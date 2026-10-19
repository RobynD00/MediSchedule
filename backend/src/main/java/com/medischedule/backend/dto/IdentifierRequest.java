package com.medischedule.backend.dto;

import jakarta.validation.constraints.NotBlank;

/** Used by forgot-password and resend-code. */
public record IdentifierRequest(
        @NotBlank(message = "Please enter your email or mobile number.")
        String identifier) {
}