package com.medischedule.backend.dto;

import com.medischedule.backend.entity.DoseHistory;
import java.time.LocalDateTime;

/** One dose: used by the popup, the History screen and the caregiver alert list. */
public record DoseResponse(
        Long id, Long medicationId, String medicationName, String dosage, String notes,
        String patientName, LocalDateTime scheduledAt, LocalDateTime respondedAt,
        String status, int snoozeCount) {

    public static DoseResponse from(DoseHistory h) {
        return new DoseResponse(
                h.getId(),
                h.getMedication().getId(),
                h.getMedication().getName(),
                h.getMedication().getDosage(),
                h.getMedication().getNotes(),
                h.getMedication().getUser().getFullName(),
                h.getScheduledAt(),
                h.getRespondedAt(),
                h.getStatus().name(),
                h.getSnoozeCount());
    }
}
