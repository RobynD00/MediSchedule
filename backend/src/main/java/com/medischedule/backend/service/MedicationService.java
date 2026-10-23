package com.medischedule.backend.service;

import com.medischedule.backend.dto.MedicationRequest;
import com.medischedule.backend.dto.MedicationResponse;
import com.medischedule.backend.entity.Medication;
import com.medischedule.backend.entity.User;
import com.medischedule.backend.exception.ApiException;
import com.medischedule.backend.repository.MedicationRepository;
import com.medischedule.backend.repository.UserRepository;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Create, read, update and delete medications (UC03 and UC11).
 * Every method takes the user id from the token, so users only ever touch their own medications.
 */
@Service
public class MedicationService {

    private final MedicationRepository medications;
    private final UserRepository users;
    private final AuditService audit;

    public MedicationService(MedicationRepository medications, UserRepository users, AuditService audit) {
        this.medications = medications;
        this.users = users;
        this.audit = audit;
    }

    public List<MedicationResponse> list(Long userId) {
        return medications.findByUserIdAndActiveTrue(userId)
                .stream().map(MedicationResponse::from).toList();
    }

    @Transactional
    public MedicationResponse create(Long userId, MedicationRequest req) {
        User user = users.findById(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Please log in to continue."));
        Medication med = new Medication();
        med.setUser(user);
        apply(med, req);
        Medication saved = medications.save(med);
        audit.log(user, "MEDICATION_CREATE", "Medication " + saved.getId());
        return MedicationResponse.from(saved);
    }

    @Transactional
    public MedicationResponse update(Long userId, Long medicationId, MedicationRequest req) {
        Medication med = ownedActive(userId, medicationId);
        apply(med, req);
        Medication saved = medications.save(med);
        audit.log(med.getUser(), "MEDICATION_UPDATE", "Medication " + medicationId);
        return MedicationResponse.from(saved);
    }

    /**
     * Soft delete (active = false) so dose history is kept.
     * The scheduler skips inactive medications, so its reminders stop automatically.
     */
    @Transactional
    public void delete(Long userId, Long medicationId) {
        Medication med = ownedActive(userId, medicationId);
        med.setActive(false);
        medications.save(med);
        audit.log(med.getUser(), "MEDICATION_DELETE", "Medication " + medicationId);
    }

    /** Copies the request onto the entity. Audit logs never contain names or doses. */
    private void apply(Medication med, MedicationRequest req) {
        med.setName(req.name().trim());
        med.setDosage(req.dosage().trim());
        String notes = req.notes() == null ? "" : req.notes().trim();
        med.setNotes(notes.isEmpty() ? null : notes);
    }

    private Medication ownedActive(Long userId, Long medicationId) {
        return medications.findByIdAndUserId(medicationId, userId)
                .filter(Medication::isActive)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Medication not found."));
    }
}