package com.medischedule.backend.dto;

import com.medischedule.backend.entity.CaregiverLink;

/** A caregiver link as shown to either side. */
public record CaregiverLinkResponse(
        Long id, Long patientId, String patientName,
        String caregiverName, String caregiverContact,
        boolean canViewAdherence, String status) {

    public static CaregiverLinkResponse from(CaregiverLink l) {
        return new CaregiverLinkResponse(
                l.getId(), l.getPatient().getId(), l.getPatient().getFullName(),
                l.getCaregiverName(), l.getCaregiverContact(),
                l.isCanViewAdherence(), l.getStatus().name());
    }
}
