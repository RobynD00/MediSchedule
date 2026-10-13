package com.medischedule.backend.enums;

/** Result of a QR scan attempt, stored in the scan log. */
public enum ScanOutcome {
    GRANTED,
    DENIED,
    EXPIRED,
    REVOKED
}