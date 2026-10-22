package com.medischedule.backend.dto;

import java.util.List;

/** Caregiver dashboard: counts for the last N days plus the recent doses. */
public record AdherenceSummaryResponse(
        String patientName, int days, long taken, long missed, long skipped,
        long total, int adherencePercent, List<DoseResponse> recent) {}
