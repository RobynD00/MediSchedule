package com.medischedule.backend.controller;

import com.medischedule.backend.dto.AdherenceSummaryResponse;
import com.medischedule.backend.dto.CaregiverLinkRequest;
import com.medischedule.backend.dto.CaregiverLinkResponse;
import com.medischedule.backend.dto.DoseResponse;
import com.medischedule.backend.security.CurrentUser;
import com.medischedule.backend.service.CaregiverService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

/** Caregiver linking, alerts and dashboard. */
@RestController
@RequestMapping("/api/caregivers")
public class CaregiverController {

    private final CaregiverService service;

    public CaregiverController(CaregiverService service) {
        this.service = service;
    }

    /** The elderly user adds a caregiver. */
    @PostMapping("/link")
    @ResponseStatus(HttpStatus.CREATED)
    public CaregiverLinkResponse link(@Valid @RequestBody CaregiverLinkRequest req) {
        return service.invite(CurrentUser.id(), req);
    }

    /** My caregivers (as the patient). */
    @GetMapping("/mine")
    public List<CaregiverLinkResponse> mine() {
        return service.myCaregivers(CurrentUser.id());
    }

    /** Invitations waiting for me (as a caregiver). */
    @GetMapping("/invitations")
    public List<CaregiverLinkResponse> invitations() {
        return service.invitations(CurrentUser.id());
    }

    @PostMapping("/links/{id}/accept")
    public CaregiverLinkResponse accept(@PathVariable Long id) {
        return service.accept(CurrentUser.id(), id);
    }

    /** Patient or caregiver ends a link. */
    @DeleteMapping("/links/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void revoke(@PathVariable Long id) {
        service.revoke(CurrentUser.id(), id);
    }

    /** People I look after (as a caregiver). */
    @GetMapping("/patients")
    public List<CaregiverLinkResponse> patients() {
        return service.myPatients(CurrentUser.id());
    }

    /** Missed doses of everyone I look after. Default last 7 days. */
    @GetMapping("/alerts")
    public List<DoseResponse> alerts(@RequestParam(defaultValue = "7") int days) {
        return service.missedAlerts(CurrentUser.id(), days);
    }

    /** Taken vs missed numbers for one patient. */
    @GetMapping("/patients/{patientId}/adherence")
    public AdherenceSummaryResponse adherence(@PathVariable Long patientId,
                                              @RequestParam(defaultValue = "7") int days) {
        return service.adherence(CurrentUser.id(), patientId, days);
    }
}
