package com.medischedule.backend.dto;

import com.medischedule.backend.enums.Role;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;

/** Sign-up details. At least one of email or phone is required (checked in AuthService). */
public record RegisterRequest(
        @NotBlank(message = "Please enter your full name.")
        String fullName,

        @NotNull(message = "Please enter your date of birth.")
        @Past(message = "Date of birth must be in the past.")
        LocalDate dateOfBirth,

        @Email(message = "Please enter a valid email address.")
        String email,

        String phone,

        @NotBlank(message = "Please enter a password.")
        @Size(min = 8, message = "Password must be at least 8 characters.")
        String password,

        @NotNull(message = "Please choose a role.")
        Role role,

        @AssertTrue(message = "Please accept the privacy notice and terms.")
        boolean acceptedTerms) {
}