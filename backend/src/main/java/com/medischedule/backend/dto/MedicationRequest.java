package com.medischedule.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Body for POST /api/medications and PUT /api/medications/{id}. */
public record MedicationRequest(
        @NotBlank(message = "Please enter the medication name.")
        @Size(max = 255, message = "The medication name is too long.")
        String name,

        @NotBlank(message = "Please enter the dosage.")
        @Size(max = 255, message = "The dosage is too long.")
        String dosage,

        @Size(max = 2000, message = "The notes are too long.")
        String notes) {
}