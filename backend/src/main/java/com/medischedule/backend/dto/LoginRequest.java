package com.medischedule.backend.dto;

import jakarta.validation.constraints.NotBlank;

/** Identifier is the registered email address or mobile number. */
public record LoginRequest(
        @NotBlank(message = "Please enter your email or mobile number.")
        String identifier,

        @NotBlank(message = "Please enter your password.")
        String password) {
}