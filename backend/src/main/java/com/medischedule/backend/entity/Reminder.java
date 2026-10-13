package com.medischedule.backend.entity;

import com.medischedule.backend.enums.*;
import jakarta.persistence.*;
import java.time.*;

/**
 * A scheduled time for a medication.
 * One medication can have many reminders.
 */
@Entity
@Table(name = "reminders")
public class Reminder {

    /** Primary key. */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Medication this reminder belongs to. */
    @ManyToOne
    @JoinColumn(name = "medication_id", nullable = false)
    private Medication medication;

    /** Time of day. */
    @Column(nullable = false)
    private LocalTime reminderTime;

    /** DAILY or SPECIFIC_DAYS. */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Frequency frequency;

    /** Used when frequency is SPECIFIC_DAYS, e.g. MON,WED,FRI. */
    private String daysOfWeek;

    /** First day the reminder applies. */
    @Column(nullable = false)
    private LocalDate startDate;

    /** False stops the scheduler from using it. */
    @Column(nullable = false)
    private boolean active;

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

    public LocalTime getReminderTime() {
        return reminderTime;
    }

    public void setReminderTime(LocalTime reminderTime) {
        this.reminderTime = reminderTime;
    }

    public Frequency getFrequency() {
        return frequency;
    }

    public void setFrequency(Frequency frequency) {
        this.frequency = frequency;
    }

    public String getDaysOfWeek() {
        return daysOfWeek;
    }

    public void setDaysOfWeek(String daysOfWeek) {
        this.daysOfWeek = daysOfWeek;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}