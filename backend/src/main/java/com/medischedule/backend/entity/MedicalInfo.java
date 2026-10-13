package com.medischedule.backend.entity;

import jakarta.persistence.*;
import java.time.*;

/**
 * Emergency medical record. One per user.
 * Only the fields chosen by the user are shown on a QR scan.
 */
@Entity
@Table(name = "medical_info")
public class MedicalInfo {

    /** Primary key. */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Owner. */
    @OneToOne
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    /** Allergies. */
    @Column(columnDefinition = "TEXT")
    private String allergies;

    /** Chronic conditions. */
    @Column(columnDefinition = "TEXT")
    private String chronicConditions;

    /** Blood type. */
    private String bloodType;

    /** Current medication summary. */
    @Column(columnDefinition = "TEXT")
    private String currentMedication;

    /** Dosage instructions. */
    @Column(columnDefinition = "TEXT")
    private String dosageInstructions;

    /** Healthcare provider details. */
    @Column(columnDefinition = "TEXT")
    private String providerDetails;

    /** Emergency contacts. */
    @Column(columnDefinition = "TEXT")
    private String emergencyContacts;

    /** Last change time. */
    private LocalDateTime updatedAt;

    @PrePersist
    @PreUpdate
    void onSave() {
        updatedAt = LocalDateTime.now();
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

    public String getAllergies() {
        return allergies;
    }

    public void setAllergies(String allergies) {
        this.allergies = allergies;
    }

    public String getChronicConditions() {
        return chronicConditions;
    }

    public void setChronicConditions(String chronicConditions) {
        this.chronicConditions = chronicConditions;
    }

    public String getBloodType() {
        return bloodType;
    }

    public void setBloodType(String bloodType) {
        this.bloodType = bloodType;
    }

    public String getCurrentMedication() {
        return currentMedication;
    }

    public void setCurrentMedication(String currentMedication) {
        this.currentMedication = currentMedication;
    }

    public String getDosageInstructions() {
        return dosageInstructions;
    }

    public void setDosageInstructions(String dosageInstructions) {
        this.dosageInstructions = dosageInstructions;
    }

    public String getProviderDetails() {
        return providerDetails;
    }

    public void setProviderDetails(String providerDetails) {
        this.providerDetails = providerDetails;
    }

    public String getEmergencyContacts() {
        return emergencyContacts;
    }

    public void setEmergencyContacts(String emergencyContacts) {
        this.emergencyContacts = emergencyContacts;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}