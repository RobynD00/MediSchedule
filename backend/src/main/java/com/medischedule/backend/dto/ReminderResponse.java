package com.medischedule.backend.dto;

import com.medischedule.backend.entity.Reminder;

/** What the app sees for a reminder schedule. Never return the entity itself. */
public record ReminderResponse(
        Long id, Long medicationId, String medicationName,
        String reminderTime, String frequency, String daysOfWeek,
        String startDate, boolean active) {

    public static ReminderResponse from(Reminder r) {
        return new ReminderResponse(
                r.getId(),
                r.getMedication().getId(),
                r.getMedication().getName(),
                r.getReminderTime().toString(),
                r.getFrequency().name(),
                r.getDaysOfWeek(),
                r.getStartDate().toString(),
                r.isActive());
    }
}
