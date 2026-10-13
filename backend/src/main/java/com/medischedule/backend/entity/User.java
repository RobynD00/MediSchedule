package com.medischedule.backend.entity;

import com.medischedule.backend.enums.*;
import jakarta.persistence.*;
import java.time.*;

/**
 * Registered account (elderly user or caregiver).
 * Passwords are stored hashed 
 * Do not return entities from controllers. Map to DTOs instead.
 */
@Entity
@Table(name = "users")
public class User {

    /** Primary key. */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Display name. */
    @Column(nullable = false)
    private String fullName;

    /** Date of birth. */
    private LocalDate dateOfBirth;

    /** Login identifier. Unique. May be null if phone is used. */
    @Column(unique = true)
    private String email;

    /** Login identifier. Unique. May be null if email is used. */
    @Column(unique = true)
    private String phone;

    /** BCrypt hash. Never expose in a DTO. */
    @Column(nullable = false)
    private String passwordHash;

    /** ELDERLY or CAREGIVER. */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    /** False until verification succeeds. */
    @Column(nullable = false)
    private boolean active;

    /** One-time code sent at registration. */
    private String verificationCode;

    /** When the verification code stops working. */
    private LocalDateTime verificationExpiresAt;

    /** Accessibility: preferred text size. */
    @Column(nullable = false)
    private int textSize;

    /** Accessibility: high contrast mode. */
    @Column(nullable = false)
    private boolean highContrast;

    /** Accessibility: read reminders aloud. */
    @Column(nullable = false)
    private boolean voiceReadout;

    /** Set automatically on insert. */
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        createdAt = LocalDateTime.now();
        if (textSize == 0) {
            textSize = 20;
        }
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public LocalDate getDateOfBirth() {
        return dateOfBirth;
    }

    public void setDateOfBirth(LocalDate dateOfBirth) {
        this.dateOfBirth = dateOfBirth;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public Role getRole() {
        return role;
    }

    public void setRole(Role role) {
        this.role = role;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public String getVerificationCode() {
        return verificationCode;
    }

    public void setVerificationCode(String verificationCode) {
        this.verificationCode = verificationCode;
    }

    public LocalDateTime getVerificationExpiresAt() {
        return verificationExpiresAt;
    }

    public void setVerificationExpiresAt(LocalDateTime verificationExpiresAt) {
        this.verificationExpiresAt = verificationExpiresAt;
    }

    public int getTextSize() {
        return textSize;
    }

    public void setTextSize(int textSize) {
        this.textSize = textSize;
    }

    public boolean isHighContrast() {
        return highContrast;
    }

    public void setHighContrast(boolean highContrast) {
        this.highContrast = highContrast;
    }

    public boolean isVoiceReadout() {
        return voiceReadout;
    }

    public void setVoiceReadout(boolean voiceReadout) {
        this.voiceReadout = voiceReadout;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}