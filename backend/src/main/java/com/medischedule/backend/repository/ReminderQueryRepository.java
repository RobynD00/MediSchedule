package com.medischedule.backend.repository;

import com.medischedule.backend.entity.Reminder;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

/** Extra reminder queries for Step 5. Kept in its own file so ReminderRepository stays untouched. */
public interface ReminderQueryRepository extends JpaRepository<Reminder, Long> {

    /** Finds a reminder only if its medication belongs to this user. */
    Optional<Reminder> findByIdAndMedicationUserId(Long id, Long userId);

    List<Reminder> findByMedicationIdAndActiveTrueOrderByReminderTime(Long medicationId);

    List<Reminder> findByActiveTrue();
}
