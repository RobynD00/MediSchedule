package com.medischedule.backend.dto;

import com.medischedule.backend.entity.Medication;

/** What the app sees for a medication. Never return the entity itself. */
public record MedicationResponse(Long id, String name, String dosage, String notes) {

    public static MedicationResponse from(Medication m) {
        return new MedicationResponse(m.getId(), m.getName(), m.getDosage(), m.getNotes());
    }
}