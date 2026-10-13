package com.medischedule.backend.repository;

import com.medischedule.backend.entity.Reminder;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

/** Database access for Reminder. Add new queries here as modules need them. */
public interface ReminderRepository extends JpaRepository<Reminder, Long> {

    List<Reminder> findByMedicationId(Long medicationId);

    List<Reminder> findByActiveTrue();
}