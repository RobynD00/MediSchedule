package com.medischedule.backend.entity;

import com.medischedule.backend.enums.*;
import jakarta.persistence.*;
import java.time.*;

/**
 * Link between an elderly user (patient) and a caregiver.
 * The caregiver may not have an account yet.
 */
@Entity
@Table(name = "caregiver_links")
public class CaregiverLink {

    /** Primary key. */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** The elderly user being supported. */
    @ManyToOne
    @JoinColumn(name = "patient_id", nullable = false)
    private User patient;

    /** Caregiver account. Null until the invitation is accepted. */
    @ManyToOne
    @JoinColumn(name = "caregiver_id", nullable = true)
    private User caregiver;

    /** Name entered by the patient. */
    @Column(nullable = false)
    private String caregiverName;

    /** Email or phone used for the invitation and alerts. */
    @Column(nullable = false)
    private String caregiverContact;

    /** Patient permission to share adherence data. */
    @Column(nullable = false)
    private boolean canViewAdherence;

    /** PENDING, ACCEPTED or REVOKED. */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private LinkStatus status;

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

    public User getPatient() {
        return patient;
    }

    public void setPatient(User patient) {
        this.patient = patient;
    }

    public User getCaregiver() {
        return caregiver;
    }

    public void setCaregiver(User caregiver) {
        this.caregiver = caregiver;
    }

    public String getCaregiverName() {
        return caregiverName;
    }

    public void setCaregiverName(String caregiverName) {
        this.caregiverName = caregiverName;
    }

    public String getCaregiverContact() {
        return caregiverContact;
    }

    public void setCaregiverContact(String caregiverContact) {
        this.caregiverContact = caregiverContact;
    }

    public boolean isCanViewAdherence() {
        return canViewAdherence;
    }

    public void setCanViewAdherence(boolean canViewAdherence) {
        this.canViewAdherence = canViewAdherence;
    }

    public LinkStatus getStatus() {
        return status;
    }

    public void setStatus(LinkStatus status) {
        this.status = status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}