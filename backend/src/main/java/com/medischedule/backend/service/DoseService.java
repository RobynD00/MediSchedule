package com.medischedule.backend.service;

import com.medischedule.backend.dto.DoseResponse;
import com.medischedule.backend.entity.DoseHistory;
import com.medischedule.backend.entity.Reminder;
import com.medischedule.backend.enums.DoseStatus;
import com.medischedule.backend.enums.Frequency;
import com.medischedule.backend.exception.ApiException;
import com.medischedule.backend.repository.DoseQueryRepository;
import com.medischedule.backend.repository.ReminderQueryRepository;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Dose lifecycle: scheduler creates a PENDING dose, the user marks it
 * TAKEN / SKIPPED / SNOOZED, and anything ignored becomes MISSED (UC05 to UC09).
 *
 * scheduledAt is never changed, so the scheduler can always tell a dose already exists.
 */
@Service
public class DoseService {

    /** How long a snooze lasts. */
    public static final int SNOOZE_MINUTES = 10;
    /** More snoozes than this and the dose counts as missed (UC07). */
    public static final int MAX_SNOOZES = 3;
    /** Minutes after the due time before an ignored dose is marked missed. */
    public static final int MISSED_AFTER_MINUTES = 30;
    /** Doses older than this are not created if the server was off when they were due. */
    private static final int CREATE_WINDOW_MINUTES = 60;
    private static final long JOB_LOCK_CREATE = 5001L;
    private static final long JOB_LOCK_MISSED = 5002L;

    private final DoseQueryRepository doses;
    private final ReminderQueryRepository reminders;
    private final CaregiverService caregiverService;
    private final AuditService audit;

    public DoseService(DoseQueryRepository doses, ReminderQueryRepository reminders,
                       CaregiverService caregiverService, AuditService audit) {
        this.doses = doses;
        this.reminders = reminders;
        this.caregiverService = caregiverService;
        this.audit = audit;
    }

    // ---------- user actions ----------

    /** Doses the app should show a reminder for right now. */
    public List<DoseResponse> due(Long userId) {
        LocalDateTime now = LocalDateTime.now();
        return doses.findDue(userId, DoseStatus.PENDING, DoseStatus.SNOOZED, now,
                        now.minusMinutes(SNOOZE_MINUTES))
                .stream().map(DoseResponse::from).toList();
    }

    /** One tap: dose taken. */
    @Transactional
    public DoseResponse markTaken(Long userId, Long doseId) {
        DoseHistory d = ownedOpenDose(userId, doseId);
        d.setStatus(DoseStatus.TAKEN);
        d.setRespondedAt(LocalDateTime.now());
        return saveAndAudit(d, "DOSE_TAKEN");
    }

    @Transactional
    public DoseResponse skip(Long userId, Long doseId) {
        DoseHistory d = ownedOpenDose(userId, doseId);
        d.setStatus(DoseStatus.SKIPPED);
        d.setRespondedAt(LocalDateTime.now());
        return saveAndAudit(d, "DOSE_SKIPPED");
    }

    /** "Remind me later". Too many snoozes marks the dose missed and alerts the caregiver. */
    @Transactional
    public DoseResponse snooze(Long userId, Long doseId) {
        DoseHistory d = ownedOpenDose(userId, doseId);
        if (d.getSnoozeCount() >= MAX_SNOOZES) {
            return DoseResponse.from(markMissed(d));
        }
        d.setStatus(DoseStatus.SNOOZED);
        d.setSnoozeCount(d.getSnoozeCount() + 1);
        d.setRespondedAt(LocalDateTime.now()); // doubles as "snoozed at"; due again after SNOOZE_MINUTES
        return saveAndAudit(d, "DOSE_SNOOZED");
    }

    /** History screen (UC09): newest first, optional medication and date filters. */
    public List<DoseResponse> history(Long userId, Long medicationId, LocalDateTime from, LocalDateTime to) {
        LocalDateTime start = from != null ? from : LocalDateTime.of(2000, 1, 1, 0, 0);
        LocalDateTime end = to != null ? to : LocalDateTime.now().plusYears(1);
        List<DoseHistory> rows = medicationId == null
                ? doses.history(userId, start, end)
                : doses.historyForMedication(userId, medicationId, start, end);
        return rows.stream().map(DoseResponse::from).toList();
    }

    // ---------- scheduler jobs ----------

    /** Creates today's PENDING doses for every active reminder whose time has arrived. */
    @Transactional
    public int createDueDoses(LocalDateTime now) {
        if (!doses.tryJobLock(JOB_LOCK_CREATE)) return 0; // another backend is already doing this
        int created = 0;
        LocalDate today = now.toLocalDate();
        for (Reminder r : reminders.findByActiveTrue()) {
            if (!r.getMedication().isActive() || !r.getMedication().getUser().isActive()) continue;
            if (today.isBefore(r.getStartDate())) continue;
            if (r.getFrequency() == Frequency.SPECIFIC_DAYS && !runsOn(r, today)) continue;

            LocalDateTime dueAt = LocalDateTime.of(today, r.getReminderTime()).withSecond(0).withNano(0);
            if (dueAt.isAfter(now) || dueAt.isBefore(now.minusMinutes(CREATE_WINDOW_MINUTES))) continue;
            if (doses.existsByReminderIdAndScheduledAt(r.getId(), dueAt)) continue;

            DoseHistory d = new DoseHistory();
            d.setMedication(r.getMedication());
            d.setReminder(r);
            d.setScheduledAt(dueAt);
            d.setStatus(DoseStatus.PENDING);
            d.setSnoozeCount(0);
            doses.save(d);
            created++;
        }
        return created;
    }

    /** Marks ignored doses missed and alerts caregivers (UC08). */
    @Transactional
    public int markOverdueAsMissed(LocalDateTime now) {
        if (!doses.tryJobLock(JOB_LOCK_MISSED)) return 0; // another backend is already doing this
        int count = 0;
        for (DoseHistory d : doses.findByStatusAndScheduledAtBefore(
                DoseStatus.PENDING, now.minusMinutes(MISSED_AFTER_MINUTES))) {
            markMissed(d);
            count++;
        }
        // A snoozed dose gets SNOOZE_MINUTES to come back, then the same grace period again.
        for (DoseHistory d : doses.findByStatusAndRespondedAtBefore(
                DoseStatus.SNOOZED, now.minusMinutes(SNOOZE_MINUTES + MISSED_AFTER_MINUTES))) {
            markMissed(d);
            count++;
        }
        return count;
    }

    // ---------- helpers ----------

    private DoseHistory markMissed(DoseHistory d) {
        d.setStatus(DoseStatus.MISSED);
        d.setRespondedAt(LocalDateTime.now());
        DoseHistory saved = doses.save(d);
        // No medication names or medical details in the audit log.
        audit.log(d.getMedication().getUser(), "DOSE_MISSED", "Dose " + d.getId());
        caregiverService.alertCaregivers(d);
        return saved;
    }

    private DoseResponse saveAndAudit(DoseHistory d, String action) {
        DoseHistory saved = doses.save(d);
        audit.log(d.getMedication().getUser(), action, "Dose " + d.getId());
        return DoseResponse.from(saved);
    }

    /** A dose can only be answered while it is still PENDING or SNOOZED. */
    private DoseHistory ownedOpenDose(Long userId, Long doseId) {
        DoseHistory d = doses.findByIdAndMedicationUserId(doseId, userId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Dose not found."));
        if (d.getStatus() != DoseStatus.PENDING && d.getStatus() != DoseStatus.SNOOZED)
            throw new ApiException(HttpStatus.CONFLICT, "This dose has already been recorded.");
        return d;
    }

    /** Does a SPECIFIC_DAYS reminder run on this date? daysOfWeek looks like "MON,WED,FRI". */
    private boolean runsOn(Reminder r, LocalDate date) {
        if (r.getDaysOfWeek() == null) return false;
        String code = date.getDayOfWeek().name().substring(0, 3); // MONDAY -> MON
        return List.of(r.getDaysOfWeek().split(",")).contains(code);
    }
}
