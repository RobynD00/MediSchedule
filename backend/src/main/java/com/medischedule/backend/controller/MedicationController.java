package com.medischedule.backend.controller;



import com.medischedule.backend.entity.Medication;

import com.medischedule.backend.entity.User;

import com.medischedule.backend.service.MedicationService;

import jakarta.persistence.EntityManager;

import jakarta.validation.Valid;

import jakarta.validation.constraints.NotBlank;

import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

import java.util.List;

import org.springframework.http.HttpStatus;

import org.springframework.security.core.annotation.AuthenticationPrincipal;

import org.springframework.transaction.annotation.Transactional;

import org.springframework.web.bind.annotation.*;

import org.springframework.web.server.ResponseStatusException;



@RestController

@RequestMapping("/api/medications")

public class MedicationController {



    private final MedicationService medicationService;

    private final EntityManager entityManager;



    public MedicationController(

            MedicationService medicationService,

            EntityManager entityManager) {

        this.medicationService = medicationService;

        this.entityManager = entityManager;

    }



    public record MedicationRequest(

            @NotBlank @Size(max = 255) String name,

            @NotBlank @Size(max = 100) String dosage,

            @Size(max = 10000) String notes) {}



    public record MedicationResponse(

            Long id,

            String name,

            String dosage,

            String notes,

            boolean active,

            LocalDateTime createdAt) {}



    private MedicationResponse toResponse(Medication medication) {

        return new MedicationResponse(

                medication.getId(),

                medication.getName(),

                medication.getDosage(),

                medication.getNotes(),

                medication.isActive(),

                medication.getCreatedAt());

    }



    @GetMapping

    public List<MedicationResponse> getMedications(

            @AuthenticationPrincipal Long userId) {

        return medicationService.getActiveMedications(userId)

                .stream()

                .map(this::toResponse)

                .toList();

    }



    @PostMapping

    @ResponseStatus(HttpStatus.CREATED)

    @Transactional

    public MedicationResponse createMedication(

            @AuthenticationPrincipal Long userId,

            @Valid @RequestBody MedicationRequest request) {



        Medication medication = new Medication();

        medication.setUser(

                entityManager.getReference(User.class, userId));

        medication.setName(request.name().trim());

        medication.setDosage(request.dosage().trim());

        medication.setNotes(request.notes());



        return toResponse(medicationService.saveMedication(medication));

    }



    @PutMapping("/{id}")

    @Transactional

    public MedicationResponse updateMedication(

            @PathVariable Long id,

            @AuthenticationPrincipal Long userId,

            @Valid @RequestBody MedicationRequest request) {



        Medication medication = medicationService

                .getMedication(id, userId)

                .filter(Medication::isActive)

                .orElseThrow(() -> new ResponseStatusException(

                        HttpStatus.NOT_FOUND, "Medication not found"));



        medication.setName(request.name().trim());

        medication.setDosage(request.dosage().trim());

        medication.setNotes(request.notes());



        return toResponse(medicationService.saveMedication(medication));

    }



    @DeleteMapping("/{id}")

    @ResponseStatus(HttpStatus.NO_CONTENT)

    @Transactional

    public void deleteMedication(

            @PathVariable Long id,

            @AuthenticationPrincipal Long userId) {



        Medication medication = medicationService

                .getMedication(id, userId)

                .filter(Medication::isActive)

                .orElseThrow(() -> new ResponseStatusException(

                        HttpStatus.NOT_FOUND, "Medication not found"));



        medication.setActive(false);

        medicationService.saveMedication(medication);

    }

}
