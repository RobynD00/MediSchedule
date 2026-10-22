package com.medischedule.backend.dto;

import com.medischedule.backend.enums.Frequency;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import java.time.LocalTime;

/**
 * Body for POST /api/medications/{id}/reminders and PUT /api/reminders/{id}.
 * Example: {"reminderTime":"08:00","frequency":"SPECIFIC_DAYS","daysOfWeek":"MON,WED,FRI"}
 */
public record ReminderRequest(
        @NotNull(message = "Please choose a reminder time.")
        LocalTime reminderTime,

        @NotNull(message = "Please choose how often to be reminded.")
        Frequency frequency,

        /** Only used for SPECIFIC_DAYS. Comma separated: MON,TUE,WED,THU,FRI,SAT,SUN. */
        String daysOfWeek,

        /** Optional. Defaults to today. */
        LocalDate startDate
) {}
