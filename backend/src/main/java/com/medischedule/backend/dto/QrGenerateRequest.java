package com.medischedule.backend.dto;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;

/**
 * Body for POST /api/qr/generate.
 * sharedFields may contain: fullName, allergies, chronicConditions, bloodType,
 * currentMedication, dosageInstructions, providerDetails, emergencyContacts.
 */
public record QrGenerateRequest(
        @NotEmpty(message = "Please choose at least one detail to share.")
        List<String> sharedFields,

        @AssertTrue(message = "Please confirm that you agree to share this information.")
        boolean consent,

        @Min(value = 1, message = "The code must be valid for at least 1 day.")
        @Max(value = 365, message = "The code can be valid for at most 365 days.")
        Integer validDays) {
}