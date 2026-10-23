package com.medischedule.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** Body for PUT /api/medical-info. Blood type and emergency contacts are required. */
public record MedicalInfoRequest(
        @Size(max = 2000, message = "Allergies are too long.")
        String allergies,

        @Size(max = 2000, message = "Chronic conditions are too long.")
        String chronicConditions,

        @NotBlank(message = "Please choose a blood type, or Unknown.")
        @Pattern(regexp = "^((A|B|AB|O)[+-]|Unknown)$",
                message = "Please choose a valid blood type, for example O+ or Unknown.")
        String bloodType,

        @Size(max = 2000, message = "Current medication is too long.")
        String currentMedication,

        @Size(max = 2000, message = "Dosage instructions are too long.")
        String dosageInstructions,

        @Size(max = 2000, message = "Provider details are too long.")
        String providerDetails,

        @NotBlank(message = "Please enter at least one emergency contact.")
        @Size(max = 2000, message = "Emergency contacts are too long.")
        String emergencyContacts) {
}