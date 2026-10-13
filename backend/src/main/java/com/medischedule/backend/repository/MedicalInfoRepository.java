package com.medischedule.backend.repository;

import com.medischedule.backend.entity.MedicalInfo;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

/** Database access for MedicalInfo. Add new queries here as modules need them. */
public interface MedicalInfoRepository extends JpaRepository<MedicalInfo, Long> {

    Optional<MedicalInfo> findByUserId(Long userId);
}