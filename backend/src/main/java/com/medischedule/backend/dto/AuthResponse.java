package com.medischedule.backend.dto;

import com.medischedule.backend.enums.Role;

/** Returned after login. The app sends the token as "Authorization: Bearer token". */
public record AuthResponse(
        String token,
        Long userId,
        String fullName,
        Role role,
        int textSize,
        boolean highContrast,
        boolean voiceReadout) {
}