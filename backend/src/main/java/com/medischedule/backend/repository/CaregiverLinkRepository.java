package com.medischedule.backend.repository;

import com.medischedule.backend.entity.CaregiverLink;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

/** Database access for CaregiverLink. Add new queries here as modules need them. */
public interface CaregiverLinkRepository extends JpaRepository<CaregiverLink, Long> {

    List<CaregiverLink> findByPatientId(Long patientId);

    List<CaregiverLink> findByCaregiverId(Long caregiverId);
}