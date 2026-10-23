package com.medischedule.backend.service;

import com.medischedule.backend.dto.QrGenerateRequest;
import com.medischedule.backend.dto.QrScanResponse;
import com.medischedule.backend.dto.QrStatusResponse;
import com.medischedule.backend.entity.MedicalInfo;
import com.medischedule.backend.entity.QrScanLog;
import com.medischedule.backend.entity.QrToken;
import com.medischedule.backend.entity.User;
import com.medischedule.backend.enums.ScanOutcome;
import com.medischedule.backend.exception.ApiException;
import com.medischedule.backend.repository.MedicalInfoRepository;
import com.medischedule.backend.repository.QrScanLogRepository;
import com.medischedule.backend.repository.QrTokenRepository;
import com.medischedule.backend.repository.UserRepository;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Generate, revoke and scan QR codes (UC15, UC16 and UC17).
 * The QR code holds only a random token. Medical data is read from the server on scan.
 */
@Service
public class QrService {

    private static final Set<String> ALLOWED_FIELDS = Set.of(
            "fullName", "allergies", "chronicConditions", "bloodType",
            "currentMedication", "dosageInstructions", "providerDetails", "emergencyContacts");
    private static final int DEFAULT_VALID_DAYS = 90;

    private final SecureRandom random = new SecureRandom();
    private final QrTokenRepository tokens;
    private final QrScanLogRepository scanLogs;
    private final MedicalInfoRepository infos;
    private final UserRepository users;
    private final AuditService audit;

    public QrService(QrTokenRepository tokens, QrScanLogRepository scanLogs,
                     MedicalInfoRepository infos, UserRepository users, AuditService audit) {
        this.tokens = tokens;
        this.scanLogs = scanLogs;
        this.infos = infos;
        this.users = users;
        this.audit = audit;
    }

    /** Replaces any active code with a new one, so only one code works at a time. */
    @Transactional
    public QrStatusResponse generate(Long userId, QrGenerateRequest req) {
        User user = users.findById(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Please log in to continue."));
        infos.findByUserId(userId).orElseThrow(() -> new ApiException(HttpStatus.BAD_REQUEST,
                "Please save your medical information before creating a QR code."));

        List<String> fields = req.sharedFields().stream().map(String::trim).distinct().toList();
        if (!ALLOWED_FIELDS.containsAll(fields)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "One of the chosen details cannot be shared.");
        }

        revokeActive(userId);

        LocalDateTime now = LocalDateTime.now();
        int days = req.validDays() == null ? DEFAULT_VALID_DAYS : req.validDays();
        QrToken qr = new QrToken();
        qr.setUser(user);
        qr.setToken(newToken());
        qr.setSharedFields(String.join(",", fields));
        qr.setConsentGivenAt(now);
        qr.setExpiresAt(now.plusDays(days));
        qr.setRevoked(false);
        QrToken saved = tokens.save(qr);

        audit.log(user, "QR_GENERATE", "Token " + saved.getId());
        return toStatus(saved);
    }

    /** Returns the newest code that is not revoked and not expired. */
    public QrStatusResponse current(Long userId) {
        LocalDateTime now = LocalDateTime.now();
        return tokens.findByUserIdAndRevokedFalse(userId).stream()
                .filter(token -> token.getExpiresAt().isAfter(now))
                .max(Comparator.comparing(QrToken::getCreatedAt))
                .map(this::toStatus)
                .orElse(QrStatusResponse.none());
    }

    /** Revokes every active code. The old token stops working immediately. */
    @Transactional
    public void revoke(Long userId) {
        User user = users.findById(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Please log in to continue."));
        revokeActive(userId);
        audit.log(user, "QR_REVOKE", null);
    }

    /**
     * Public scan. Not @Transactional on purpose: the scan log must be saved
     * even when the scan is refused and an ApiException is thrown.
     */
    public QrScanResponse scan(String token, String metadata) {
        Optional<QrToken> found = tokens.findByToken(token);
        if (found.isEmpty()) {
            audit.log("QR_SCAN_DENIED", "Unknown token");
            throw new ApiException(HttpStatus.NOT_FOUND, "This QR code is not valid.");
        }

        QrToken qr = found.get();
        if (qr.isRevoked()) {
            logScan(qr, ScanOutcome.REVOKED, metadata);
            throw new ApiException(HttpStatus.GONE, "This QR code is no longer active.");
        }
        if (qr.getExpiresAt().isBefore(LocalDateTime.now())) {
            logScan(qr, ScanOutcome.EXPIRED, metadata);
            throw new ApiException(HttpStatus.GONE, "This QR code has expired.");
        }

        MedicalInfo info = infos.findByUserId(qr.getUser().getId()).orElse(null);
        if (info == null) {
            logScan(qr, ScanOutcome.DENIED, metadata);
            throw new ApiException(HttpStatus.NOT_FOUND, "No information is available for this QR code.");
        }

        logScan(qr, ScanOutcome.GRANTED, metadata);
        return new QrScanResponse(buildView(qr, info));
    }

    private void revokeActive(Long userId) {
        tokens.findByUserIdAndRevokedFalse(userId).forEach(token -> {
            token.setRevoked(true);
            tokens.save(token);
        });
    }

    /** Only the fields the patient approved are copied into the view. */
    private Map<String, String> buildView(QrToken qr, MedicalInfo info) {
        Map<String, String> view = new LinkedHashMap<>();
        for (String field : qr.getSharedFields().split(",")) {
            String value = switch (field) {
                case "fullName" -> qr.getUser().getFullName();
                case "allergies" -> info.getAllergies();
                case "chronicConditions" -> info.getChronicConditions();
                case "bloodType" -> info.getBloodType();
                case "currentMedication" -> info.getCurrentMedication();
                case "dosageInstructions" -> info.getDosageInstructions();
                case "providerDetails" -> info.getProviderDetails();
                case "emergencyContacts" -> info.getEmergencyContacts();
                default -> null;
            };
            view.put(field, value == null || value.isBlank() ? "Not provided" : value);
        }
        return view;
    }

    /** The scan log and audit log hold technical details only, never medical data. */
    private void logScan(QrToken qr, ScanOutcome outcome, String metadata) {
        QrScanLog entry = new QrScanLog();
        entry.setQrToken(qr);
        entry.setOutcome(outcome);
        entry.setMetadata(metadata);
        scanLogs.save(entry);
        audit.log("QR_SCAN", "Token " + qr.getId() + " " + outcome);
    }

    private QrStatusResponse toStatus(QrToken qr) {
        return new QrStatusResponse(true, qr.getToken(),
                List.of(qr.getSharedFields().split(",")), qr.getExpiresAt().toString());
    }

    /** 256 bits of randomness, safe to put in a URL. */
    private String newToken() {
        byte[] bytes = new byte[32];
        random.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}