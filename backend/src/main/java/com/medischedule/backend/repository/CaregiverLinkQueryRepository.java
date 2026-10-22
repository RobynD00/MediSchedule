package com.medischedule.backend.repository;

import com.medischedule.backend.entity.CaregiverLink;
import com.medischedule.backend.enums.LinkStatus;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

/** Extra caregiver link queries for Step 5. Kept in its own file so CaregiverLinkRepository stays untouched. */
public interface CaregiverLinkQueryRepository extends JpaRepository<CaregiverLink, Long> {

    List<CaregiverLink> findByPatientIdAndStatusNot(Long patientId, LinkStatus status);

    List<CaregiverLink> findByPatientIdAndStatus(Long patientId, LinkStatus status);

    List<CaregiverLink> findByCaregiverIdAndStatus(Long caregiverId, LinkStatus status);

    /** Invitations waiting for a caregiver, matched on the contact the patient typed in. */
    List<CaregiverLink> findByCaregiverContactIgnoreCaseAndStatus(String contact, LinkStatus status);

    /** Stops the same caregiver being invited twice. */
    Optional<CaregiverLink> findFirstByPatientIdAndCaregiverContactIgnoreCaseAndStatusNot(
            Long patientId, String contact, LinkStatus status);

    /** The accepted link between a caregiver and a patient, if any. */
    Optional<CaregiverLink> findFirstByPatientIdAndCaregiverIdAndStatus(
            Long patientId, Long caregiverId, LinkStatus status);
}
