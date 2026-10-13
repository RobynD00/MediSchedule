package com.medischedule.backend.entity;

import jakarta.persistence.*;
import java.time.*;

/**
 * Login session. One user can have many.
 * Set revoked to true on logout.
 */
@Entity
@Table(name = "user_sessions")
public class Session {

    /** Primary key. */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Owner of the session. */
    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /** JWT or session token. */
    @Column(nullable = false, unique = true, length = 512)
    private String token;

    /** Expiry time. */
    @Column(nullable = false)
    private LocalDateTime expiresAt;

    /** True after logout. */
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