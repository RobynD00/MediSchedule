package com.medischedule.backend.service;

import com.medischedule.backend.dto.MedicalInfoRequest;
import com.medischedule.backend.dto.MedicalInfoResponse;
import com.medischedule.backend.entity.MedicalInfo;
import com.medischedule.backend.entity.User;
import com.medischedule.backend.exception.ApiException;
import com.medischedule.backend.repository.MedicalInfoRepository;
import com.medischedule.backend.repository.QrTokenRepository;
import com.medischedule.backend.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Create, read, update and delete the user's emergency medical information (UC14). */
@Service
public class MedicalInfoService {

    private final MedicalInfoRepository infos;
    private final QrTokenRepository tokens;
    private final UserRepository users;
    private final AuditService audit;

    public MedicalInfoService(MedicalInfoRepository infos, QrTokenRepository tokens,
                              UserRepository users, AuditService audit) {
        this.infos = infos;
        this.tokens = tokens;
        this.users = users;
        this.audit = audit;
    }

    public MedicalInfoResponse get(Long userId) {
        return infos.findByUserId(userId)
                .map(MedicalInfoResponse::from)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                        "No medical information has been saved yet."));
    }

    /** Creates the record the first time and updates it after that. */
    @Transactional
    public MedicalInfoResponse save(Long userId, MedicalInfoRequest req) {
        User user = users.findById(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Please log in to continue."));
        MedicalInfo info = infos.findByUserId(userId).orElseGet(() -> {
            MedicalInfo created = new MedicalInfo();
            created.setUser(user);
            return created;
        });

        info.setAllergies(clean(req.allergies()));
        info.setChronicConditions(clean(req.chronicConditions()));
        info.setBloodType(req.bloodType().trim());
        info.setCurrentMedication(clean(req.currentMedication()));
        info.setDosageInstructions(clean(req.dosageInstructions()));
        info.setProviderDetails(clean(req.providerDetails()));
        info.setEmergencyContacts(req.emergencyContacts().trim());

        MedicalInfo saved = infos.save(info);
        audit.log(user, "MEDICAL_INFO_UPDATE", null);
        return MedicalInfoResponse.from(saved);
    }

    /** Deletes the record and revokes every QR code, so nothing can be scanned afterwards. */
    @Transactional
    public void delete(Long userId) {
        MedicalInfo info = infos.findByUserId(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                        "No medical information has been saved yet."));
        tokens.findByUserIdAndRevokedFalse(userId).forEach(token -> {
            token.setRevoked(true);
            tokens.save(token);
        });
        infos.delete(info);
        audit.log(info.getUser(), "MEDICAL_INFO_DELETE", null);
    }

    /** Trims text and turns empty text into null. Audit logs never contain the values. */
    private String clean(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}