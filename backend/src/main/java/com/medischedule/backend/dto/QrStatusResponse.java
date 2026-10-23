package com.medischedule.backend.dto;

import java.util.List;

/** The user's current QR code. active is false when there is none. */
public record QrStatusResponse(boolean active, String token, List<String> sharedFields, String expiresAt) {

    public static QrStatusResponse none() {
        return new QrStatusResponse(false, null, List.of(), null);
    }
}