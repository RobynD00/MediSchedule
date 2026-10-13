package com.medischedule.backend.entity;

import jakarta.persistence.*;
import java.time.*;

/**
 * A medication a user must take.
 * Delete is soft: set active to false so dose history is kept.
 */
@Entity
@Table(name = "medications")
public class Medication {

    /** Primary key. */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Owner. */
    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /** Medication name. */
    @Column(nullable = false)
    private String name;

    /** Dose amount, e.g. 500mg. */
    @Column(nullable = false)
    private String dosage;

    /** Optional instructions. */
    @Column(columnDefinition = "TEXT")
    private String notes;

    /** False means deleted (soft delete). */
    @Column(nullable = false)
    private boolean active;

    /** Set automatically on insert. */
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        createdAt = LocalDateTime.now();
        active = true;
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

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDosage() {
        return dosage;
    }

    public void setDosage(String dosage) {
        this.dosage = dosage;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}