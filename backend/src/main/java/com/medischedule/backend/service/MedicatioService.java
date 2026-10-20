package com.medischedule.backend.service;
 
import com.medischedule.backend.entity.Medication;
import com.medischedule.backend.repository.MedicationRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
 
import java.util.List;
import java.util.Optional;
 
@Service
public class MedicationService {
 
    private final MedicationRepository medicationRepository;
 
    public MedicationService(MedicationRepository medicationRepository) {
        this.medicationRepository = medicationRepository;
    }
 
    @Transactional(readOnly = true)
    public List<Medication> getActiveMedications(Long userId) {
        return medicationRepository.findByUserIdAndActiveTrue(userId);
    }
 
    @Transactional(readOnly = true)
    public Optional<Medication> getMedication(Long medicationId, Long userId) {
        return medicationRepository.findByIdAndUserId(
            medicationId, userId
        );
    }
 
    @Transactional
    public Medication saveMedication(Medication medication) {
        return medicationRepository.save(medication);
    }
}
 
