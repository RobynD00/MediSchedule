package com.medischedule.backend.service;

import com.medischedule.backend.dto.AdherenceSummaryResponse;
import com.medischedule.backend.dto.CaregiverLinkRequest;
import com.medischedule.backend.dto.CaregiverLinkResponse;
import com.medischedule.backend.dto.DoseResponse;
import com.medischedule.backend.entity.CaregiverLink;
import com.medischedule.backend.entity.DoseHistory;
import com.medischedule.backend.entity.User;
import com.medischedule.backend.enums.DoseStatus;
import com.medischedule.backend.enums.LinkStatus;
import com.medischedule.backend.exception.ApiException;
import com.medischedule.backend.repository.CaregiverLinkQueryRepository;
import com.medischedule.backend.repository.DoseQueryRepository;
import com.medischedule.backend.repository.UserRepository;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Caregiver links, missed-dose alerts and the caregiver dashboard (UC08, UC10, UC13). */
@Service
public class CaregiverService {

    private final CaregiverLinkQueryRepository links;
    private final DoseQueryRepository doses;
    private final UserRepository users;
    private final AuditService audit;

    public CaregiverService(CaregiverLinkQueryRepository links, DoseQueryRepository doses,
                            UserRepository users, AuditService audit) {
        this.links = links;
        this.doses = doses;
        this.users = users;
        this.audit = audit;
    }

    /** The elderly user invites a caregiver. The link stays PENDING until the caregiver accepts. */
    @Transactional
    public CaregiverLinkResponse invite(Long patientId, CaregiverLinkRequest req) {
        User patient = loadUser(patientId);
        String contact = normalise(req.caregiverContact());
        if (contact.equalsIgnoreCase(normalise(patient.getEmail()))
                || contact.equals(normalise(patient.getPhone())))
            throw new ApiException(HttpStatus.BAD_REQUEST, "You cannot add yourself as a caregiver.");
        if (links.findFirstByPatientIdAndCaregiverContactIgnoreCaseAndStatusNot(
                patientId, contact, LinkStatus.REVOKED).isPresent())
            throw new ApiException(HttpStatus.CONFLICT, "You have already added this caregiver.");

        CaregiverLink link = new CaregiverLink();
        link.setPatient(patient);
        link.setCaregiverName(req.caregiverName().trim());
        link.setCaregiverContact(contact);
        link.setCanViewAdherence(req.canViewAdherence());
        link.setStatus(LinkStatus.PENDING);
        CaregiverLink saved = links.save(link);
        audit.log(patient, "CAREGIVER_INVITE", "Link " + saved.getId());
        return CaregiverLinkResponse.from(saved);
    }

    /** Invitations waiting for the logged-in caregiver (matched on their email or phone). */
    public List<CaregiverLinkResponse> invitations(Long userId) {
        User me = loadUser(userId);
        return pendingFor(me).stream().map(CaregiverLinkResponse::from).toList();
    }

    /** The caregiver accepts. Only the person the invitation was sent to can do this. */
    @Transactional
    public CaregiverLinkResponse accept(Long userId, Long linkId) {
        User me = loadUser(userId);
        CaregiverLink link = find(linkId);
        boolean mine = pendingFor(me).stream().anyMatch(l -> l.getId().equals(linkId));
        if (!mine) throw new ApiException(HttpStatus.NOT_FOUND, "Invitation not found.");
        link.setCaregiver(me);
        link.setStatus(LinkStatus.ACCEPTED);
        audit.log(me, "CAREGIVER_ACCEPT", "Link " + linkId);
        return CaregiverLinkResponse.from(links.save(link));
    }

    /** Either side can end the link at any time. */
    @Transactional
    public void revoke(Long userId, Long linkId) {
        CaregiverLink link = find(linkId);
        boolean isPatient = link.getPatient().getId().equals(userId);
        boolean isCaregiver = link.getCaregiver() != null && link.getCaregiver().getId().equals(userId);
        boolean invitedByContact = link.getCaregiver() == null
                && pendingFor(loadUser(userId)).stream().anyMatch(l -> l.getId().equals(linkId));
        if (!isPatient && !isCaregiver && !invitedByContact)
            throw new ApiException(HttpStatus.NOT_FOUND, "Link not found.");
        link.setStatus(LinkStatus.REVOKED);
        links.save(link);
        audit.log(loadUser(userId), "CAREGIVER_REVOKE", "Link " + linkId);
    }

    /** The patient's own caregivers (pending and accepted). */
    public List<CaregiverLinkResponse> myCaregivers(Long patientId) {
        return links.findByPatientIdAndStatusNot(patientId, LinkStatus.REVOKED)
                .stream().map(CaregiverLinkResponse::from).toList();
    }

    /** People this caregiver looks after. */
    public List<CaregiverLinkResponse> myPatients(Long caregiverId) {
        return links.findByCaregiverIdAndStatus(caregiverId, LinkStatus.ACCEPTED)
                .stream().filter(CaregiverLink::isCanViewAdherence)
                .map(CaregiverLinkResponse::from).toList();
    }

    /** Missed doses of all this caregiver's patients over the last N days (the alert feed). */
    public List<DoseResponse> missedAlerts(Long caregiverId, int days) {
        List<Long> patientIds = links.findByCaregiverIdAndStatus(caregiverId, LinkStatus.ACCEPTED).stream()
                .filter(CaregiverLink::isCanViewAdherence).map(l -> l.getPatient().getId()).toList();
        if (patientIds.isEmpty()) return List.of();
        return doses.findForPatients(patientIds, DoseStatus.MISSED, LocalDateTime.now().minusDays(clamp(days)))
                .stream().map(DoseResponse::from).toList();
    }

    /** Dashboard numbers for one patient (UC10). Needs an accepted link with permission. */
    public AdherenceSummaryResponse adherence(Long caregiverId, Long patientId, int days) {
        CaregiverLink link = links.findFirstByPatientIdAndCaregiverIdAndStatus(
                        patientId, caregiverId, LinkStatus.ACCEPTED)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Patient not found."));
        if (!link.isCanViewAdherence())
            throw new ApiException(HttpStatus.FORBIDDEN, "This person has not shared their history with you.");

        int window = clamp(days);
        List<DoseHistory> rows = doses.findSince(patientId, LocalDateTime.now().minusDays(window));
        long taken = count(rows, DoseStatus.TAKEN);
        long missed = count(rows, DoseStatus.MISSED);
        long skipped = count(rows, DoseStatus.SKIPPED);
        long total = taken + missed + skipped;
        int percent = total == 0 ? 0 : (int) Math.round(taken * 100.0 / total);
        List<DoseResponse> recent = rows.stream().limit(20).map(DoseResponse::from).toList();
        audit.log(loadUser(caregiverId), "ADHERENCE_VIEW", "Patient " + patientId);
        return new AdherenceSummaryResponse(link.getPatient().getFullName(), window,
                taken, missed, skipped, total, percent, recent);
    }

    /**
     * Called when a dose becomes MISSED. Records one alert per caregiver who is allowed to see it.
     * The alert feed (missedAlerts) reads the missed doses themselves.
     */
    public void alertCaregivers(DoseHistory dose) {
        User patient = dose.getMedication().getUser();
        for (CaregiverLink l : links.findByPatientIdAndStatus(patient.getId(), LinkStatus.ACCEPTED)) {
            if (!l.isCanViewAdherence() || l.getCaregiver() == null) continue;
            audit.log(l.getCaregiver(), "MISSED_DOSE_ALERT", "Dose " + dose.getId());
            // TODO (optional): send an FCM push to the caregiver's device here.
        }
    }

    // ---------- helpers ----------

    private List<CaregiverLink> pendingFor(User me) {
        List<CaregiverLink> found = new java.util.ArrayList<>();
        if (me.getEmail() != null)
            found.addAll(links.findByCaregiverContactIgnoreCaseAndStatus(me.getEmail(), LinkStatus.PENDING));
        if (me.getPhone() != null)
            found.addAll(links.findByCaregiverContactIgnoreCaseAndStatus(me.getPhone(), LinkStatus.PENDING));
        return found;
    }

    private CaregiverLink find(Long id) {
        return links.findById(id).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Link not found."));
    }

    private User loadUser(Long id) {
        return users.findById(id).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found."));
    }

    private static String normalise(String s) {
        return s == null ? "" : s.trim().toLowerCase();
    }

    private static long count(List<DoseHistory> rows, DoseStatus status) {
        return rows.stream().filter(h -> h.getStatus() == status).count();
    }

    private static int clamp(int days) {
        return Math.min(Math.max(days, 1), 90);
    }
}
