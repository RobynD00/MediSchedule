package com.medischedule.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ResetPasswordRequest(
        @NotBlank(message = "Please enter your email or mobile number.")
        String identifier,

        @NotBlank(message = "Please enter the code.")
        String code,

        @NotBlank(message = "Please enter a new password.")
        @Size(min = 8, message = "Password must be at least 8 characters.")
        String newPassword) {
}