package com.medischedule.backend.dto;

import java.util.Map;

/** What a scanner sees: only the details the patient approved, in the order they were chosen. */
public record QrScanResponse(Map<String, String> information) {
}