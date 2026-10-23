package com.medischedule.backend.dto;

import jakarta.validation.constraints.*;

/** Body for POST /api/caregivers/link (sent by the elderly user). */
public record CaregiverLinkRequest(
        @NotBlank(message = "Please enter the caregiver's name.")
        @Size(max = 100, message = "That name is too long.")
        String caregiverName,

        /** The caregiver's email or phone number. They must register with the same one. */
        @NotBlank(message = "Please enter the caregiver's email or phone number.")
        @Size(max = 120, message = "That contact is too long.")
        String caregiverContact,

        /** The patient must agree before any adherence data is shared (UC13). */
        @AssertTrue(message = "Please agree to share your medication history with this caregiver.")
        boolean canViewAdherence
) {}
