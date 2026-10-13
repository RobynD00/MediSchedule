package com.medischedule.backend.entity;

import com.medischedule.backend.enums.*;
import jakarta.persistence.*;
import java.time.*;

/**
 * One row per scheduled dose and what happened to it.
 * Used for history, adherence and caregiver alerts.
 */
@Entity
@Table(name = "dose_history")
public class DoseHistory {

    /** Primary key. */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Medication the dose belongs to. */
    @ManyToOne
    @JoinColumn(name = "medication_id", nullable = false)
    private Medication medication;

    /** Reminder that produced the dose. */
    @ManyToOne
    @JoinColumn(name = "reminder_id", nullable = true)
    private Reminder reminder;

    /** PENDING, TAKEN, SNOOZED, SKIPPED or MISSED. */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DoseStatus status;

    /** When the dose was due. */
    @Column(nullable = false)
    private LocalDateTime scheduledAt;

    /** When the user responded. */
    private LocalDateTime respondedAt;

    /** Times snoozed. Too many marks the dose MISSED. */
    @Column(nullable = false)
    private int snoozeCount;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Medication getMedication() {
        return medication;
    }

    public void setMedication(Medication medication) {
        this.medication = medication;
    }

    public Reminder getReminder() {
        return reminder;
    }

    public void setReminder(Reminder reminder) {
        this.reminder = reminder;
    }

    public DoseStatus getStatus() {
        return status;
    }

    public void setStatus(DoseStatus status) {
        this.status = status;
    }

    public LocalDateTime getScheduledAt() {
        return scheduledAt;
    }

    public void setScheduledAt(LocalDateTime scheduledAt) {
        this.scheduledAt = scheduledAt;
    }

    public LocalDateTime getRespondedAt() {
        return respondedAt;
    }

    public void setRespondedAt(LocalDateTime respondedAt) {
        this.respondedAt = respondedAt;
    }

    public int getSnoozeCount() {
        return snoozeCount;
    }

    public void setSnoozeCount(int snoozeCount) {
        this.snoozeCount = snoozeCount;
    }
}