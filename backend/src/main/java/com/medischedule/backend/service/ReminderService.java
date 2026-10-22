package com.medischedule.backend.service;

import com.medischedule.backend.dto.ReminderRequest;
import com.medischedule.backend.dto.ReminderResponse;
import com.medischedule.backend.entity.Medication;
import com.medischedule.backend.entity.Reminder;
import com.medischedule.backend.enums.Frequency;
import com.medischedule.backend.exception.ApiException;
import com.medischedule.backend.repository.MedicationRepository;
import com.medischedule.backend.repository.ReminderQueryRepository;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import java.util.Arrays;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Create / read / update / delete reminder schedules for a medication (UC04). */
@Service
public class ReminderService {

    private static final Set<String> VALID_DAYS = Set.of("MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN");

    private final ReminderQueryRepository reminders;
    private final MedicationRepository medications;
    private final AuditService audit;

    public ReminderService(ReminderQueryRepository reminders, MedicationRepository medications,
                           AuditService audit) {
        this.reminders = reminders;
        this.medications = medications;
        this.audit = audit;
    }

    @Transactional
    public ReminderResponse create(Long userId, Long medicationId, ReminderRequest req) {
        Medication med = ownedActiveMedication(userId, medicationId);
        Reminder r = new Reminder();
        r.setMedication(med);
        apply(r, req);
        r.setActive(true);
        Reminder saved = reminders.save(r);
        audit.log(med.getUser(), "REMINDER_CREATE", "Reminder " + saved.getId());
        return ReminderResponse.from(saved);
    }

    public List<ReminderResponse> list(Long userId, Long medicationId) {
        ownedActiveMedication(userId, medicationId);
        return reminders.findByMedicationIdAndActiveTrueOrderByReminderTime(medicationId)
                .stream().map(ReminderResponse::from).toList();
    }

    @Transactional
    public ReminderResponse update(Long userId, Long reminderId, ReminderRequest req) {
        Reminder r = ownedActiveReminder(userId, reminderId);
        apply(r, req);
        Reminder saved = reminders.save(r);
        audit.log(r.getMedication().getUser(), "REMINDER_UPDATE", "Reminder " + reminderId);
        return ReminderResponse.from(saved);
    }

    /** Soft delete (active = false) so the dose history that points at it is kept. */
    @Transactional
    public void delete(Long userId, Long reminderId) {
        Reminder r = ownedActiveReminder(userId, reminderId);
        r.setActive(false);
        reminders.save(r);
        audit.log(r.getMedication().getUser(), "REMINDER_DELETE", "Reminder " + reminderId);
    }

    // ---------- helpers ----------

    /** Copies and validates the request onto the entity. */
    private void apply(Reminder r, ReminderRequest req) {
        r.setReminderTime(req.reminderTime().withSecond(0).withNano(0));
        r.setFrequency(req.frequency());
        r.setStartDate(req.startDate() != null ? req.startDate() : LocalDate.now());

        if (req.frequency() == Frequency.SPECIFIC_DAYS) {
            if (req.daysOfWeek() == null || req.daysOfWeek().isBlank())
                throw new ApiException(HttpStatus.BAD_REQUEST, "Please choose at least one day.");
            // Normalise "mon, wed" -> "MON,WED" and reject anything that is not a day.
            List<String> days = Arrays.stream(req.daysOfWeek().split(","))
                    .map(d -> d.trim().toUpperCase()).filter(d -> !d.isEmpty()).distinct().toList();
            if (days.isEmpty() || !VALID_DAYS.containsAll(days))
                throw new ApiException(HttpStatus.BAD_REQUEST, "Days must be MON, TUE, WED, THU, FRI, SAT or SUN.");
            r.setDaysOfWeek(String.join(",", days));
        } else {
            r.setDaysOfWeek(null);
        }
    }

    /** "Not yours" and "not found" give the same answer so nobody can probe other people's records. */
    private Medication ownedActiveMedication(Long userId, Long medicationId) {
        Medication m = medications.findByIdAndUserId(medicationId, userId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Medication not found."));
        if (!m.isActive()) throw new ApiException(HttpStatus.NOT_FOUND, "Medication not found.");
        return m;
    }

    private Reminder ownedActiveReminder(Long userId, Long reminderId) {
        Reminder r = reminders.findByIdAndMedicationUserId(reminderId, userId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Reminder not found."));
        if (!r.isActive()) throw new ApiException(HttpStatus.NOT_FOUND, "Reminder not found.");
        return r;
    }
}
