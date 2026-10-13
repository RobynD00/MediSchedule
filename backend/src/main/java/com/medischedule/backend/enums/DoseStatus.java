package com.medischedule.backend.enums;

/** Outcome of a single scheduled dose. */
public enum DoseStatus {
    PENDING,
    TAKEN,
    SNOOZED,
    SKIPPED,
    MISSED
}