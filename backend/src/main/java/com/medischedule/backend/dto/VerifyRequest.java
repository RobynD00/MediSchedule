package com.medischedule.backend.dto;

import jakarta.validation.constraints.NotBlank;

/** One-time code sent after registration. */
public record VerifyRequest(
        @NotBlank(message = "Please enter your email or mobile number.")
        String identifier,

        @NotBlank(message = "Please enter the code.")
        String code) {
}