package com.medischedule.backend.entity;

import com.medischedule.backend.enums.*;
import jakarta.persistence.*;
import java.time.*;

/**
 * Every scan attempt of a QR token.
 * Never store medical data here.
 */
@Entity
@Table(name = "qr_scan_logs")
public class QrScanLog {

    /** Primary key. */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Token that was scanned. */
    @ManyToOne
    @JoinColumn(name = "qr_token_id", nullable = false)
    private QrToken qrToken;

    /** Set automatically on insert. */
    @Column(nullable = false, updatable = false)
    private LocalDateTime scannedAt;

    /** GRANTED, DENIED, EXPIRED or REVOKED. */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ScanOutcome outcome;

    /** Technical info such as IP address or device. */
    @Column(columnDefinition = "TEXT")
    private String metadata;

    @PrePersist
    void onCreate() {
        scannedAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public QrToken getQrToken() {
        return qrToken;
    }

    public void setQrToken(QrToken qrToken) {
        this.qrToken = qrToken;
    }

    public LocalDateTime getScannedAt() {
        return scannedAt;
    }

    public void setScannedAt(LocalDateTime scannedAt) {
        this.scannedAt = scannedAt;
    }

    public ScanOutcome getOutcome() {
        return outcome;
    }

    public void setOutcome(ScanOutcome outcome) {
        this.outcome = outcome;
    }

    public String getMetadata() {
        return metadata;
    }

    public void setMetadata(String metadata) {
        this.metadata = metadata;
    }
}