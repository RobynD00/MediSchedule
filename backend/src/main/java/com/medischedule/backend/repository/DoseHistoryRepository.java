package com.medischedule.backend.repository;

import com.medischedule.backend.entity.DoseHistory;
import com.medischedule.backend.enums.DoseStatus;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

/** Database access for DoseHistory. Add new queries here as modules need them. */
public interface DoseHistoryRepository extends JpaRepository<DoseHistory, Long> {

    List<DoseHistory> findByMedicationUserIdOrderByScheduledAtDesc(Long userId);

    List<DoseHistory> findByMedicationIdOrderByScheduledAtDesc(Long medicationId);

    List<DoseHistory> findByStatusAndScheduledAtBefore(DoseStatus status, LocalDateTime before);
}