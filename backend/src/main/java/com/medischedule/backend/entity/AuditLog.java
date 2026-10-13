package com.medischedule.backend.entity;

import jakarta.persistence.*;
import java.time.*;

/**
 * Record of important actions: login, QR generate, scan, revoke, medical info change.
 * Never store medical data in metadata.
 */
@Entity
@Table(name = "audit_logs")
public class AuditLog {

    /** Primary key. */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Acting user. Null for anonymous actions such as a public QR scan. */
    @ManyToOne
    @JoinColumn(name = "user_id", nullable = true)
    private User user;

    /** Action name, e.g. LOGIN_SUCCESS, QR_SCAN. */
    @Column(nullable = false)
    private String action;

    /** Technical details only. */
    @Column(columnDefinition = "TEXT")
    private String metadata;

    /** Set automatically on insert. */
    @Column(nullable = false, updatable = false)
    private LocalDateTime timestamp;

    @PrePersist
    void onCreate() {
        timestamp = LocalDateTime.now();
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

    public String getAction() {
        return action;
    }

    public void setAction(String action) {
        this.action = action;
    }

    public String getMetadata() {
        return metadata;
    }

    public void setMetadata(String metadata) {
        this.metadata = metadata;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }
}