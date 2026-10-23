package com.medischedule.backend.dto;

import com.medischedule.backend.entity.MedicalInfo;

/** What the app sees for the user's own medical information. */
public record MedicalInfoResponse(
        String allergies, String chronicConditions, String bloodType,
        String currentMedication, String dosageInstructions,
        String providerDetails, String emergencyContacts, String updatedAt) {

    public static MedicalInfoResponse from(MedicalInfo m) {
        return new MedicalInfoResponse(
                m.getAllergies(), m.getChronicConditions(), m.getBloodType(),
                m.getCurrentMedication(), m.getDosageInstructions(),
                m.getProviderDetails(), m.getEmergencyContacts(),
                m.getUpdatedAt() == null ? null : m.getUpdatedAt().toString());
    }
}