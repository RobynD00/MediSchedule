package com.medischedule.backend.repository;

import com.medischedule.backend.entity.Medication;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

/** Database access for Medication. Add new queries here as modules need them. */
public interface MedicationRepository extends JpaRepository<Medication, Long> {

    List<Medication> findByUserIdAndActiveTrue(Long userId);

    Optional<Medication> findByIdAndUserId(Long id, Long userId);
}