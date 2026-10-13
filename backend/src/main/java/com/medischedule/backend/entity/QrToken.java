package com.medischedule.backend.entity;

import jakarta.persistence.*;
import java.time.*;

/**
 * Random access token behind a QR code.
 * The QR holds only this token, never medical data.
 */
@Entity
@Table(name = "qr_tokens")
public class QrToken {

    /** Primary key. */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Owner. */
    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /** Random, unguessable value. */
    @Column(nullable = false, unique = true)
    private String token;

    /** Comma separated fields the user agreed to share, e.g. allergies,bloodType. */
    @Column(columnDefinition = "TEXT")
    private String sharedFields;

    /** Consent time. Required before generating. */
    @Column(nullable = false)
    private LocalDateTime consentGivenAt;

    /** Token expiry. */
    @Column(nullable = false)
    private LocalDateTime expiresAt;

    /** True once revoked or replaced. */
    @Column(nullable = false)
    private boolean revoked;

    /** Set automatically on insert. */
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public String getSharedFields() {
        return sharedFields;
    }

    public void setSharedFields(String sharedFields) {
        this.sharedFields = sharedFields;
    }

    public LocalDateTime getConsentGivenAt() {
        return consentGivenAt;
    }

    public void setConsentGivenAt(LocalDateTime consentGivenAt) {
        this.consentGivenAt = consentGivenAt;
    }

    public LocalDateTime getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(LocalDateTime expiresAt) {
        this.expiresAt = expiresAt;
    }

    public boolean isRevoked() {
        return revoked;
    }

    public void setRevoked(boolean revoked) {
        this.revoked = revoked;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}