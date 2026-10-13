package com.medischedule.backend.service;

import com.medischedule.backend.entity.AuditLog;
import com.medischedule.backend.entity.User;
import com.medischedule.backend.repository.AuditLogRepository;
import org.springframework.stereotype.Service;

/**
 * Shared audit logging. Call it from any module after an important action.
 * Action names: LOGIN_SUCCESS, LOGIN_FAILED, REGISTER, QR_GENERATE, QR_SCAN, QR_REVOKE, MEDICAL_INFO_UPDATE.
 * Never put medical data or passwords in metadata.
 */
@Service
public class AuditService {

    private final AuditLogRepository auditLogRepository;

    public AuditService(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    /** Log an action done by a known user. */
    public void log(User user, String action, String metadata) {
        AuditLog entry = new AuditLog();
        entry.setUser(user);
        entry.setAction(action);
        entry.setMetadata(metadata);
        auditLogRepository.save(entry);
    }

    /** Log an action with no logged-in user, such as a public QR scan. */
    public void log(String action, String metadata) {
        log(null, action, metadata);
    }
}