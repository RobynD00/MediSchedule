package com.medischedule.backend.repository;

import com.medischedule.backend.entity.DoseHistory;
import com.medischedule.backend.enums.DoseStatus;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/** Extra dose queries for Step 5. Kept in its own file so DoseHistoryRepository stays untouched. */
public interface DoseQueryRepository extends JpaRepository<DoseHistory, Long> {

    /** Finds a dose only if its medication belongs to this user. */
    Optional<DoseHistory> findByIdAndMedicationUserId(Long id, Long userId);

    /**
     * Cluster-wide lock held until the current transaction ends. Several backends share one
     * database, so only one of them may run the dose jobs at a time (stops duplicate doses).
     */
    @Query(value = "select pg_try_advisory_xact_lock(:key)", nativeQuery = true)
    boolean tryJobLock(@Param("key") long key);

    /** Stops the scheduler creating the same dose twice. */
    boolean existsByReminderIdAndScheduledAt(Long reminderId, LocalDateTime scheduledAt);

    /** Doses waiting for the user: new ones that are due, and snoozed ones whose snooze is over. */
    @Query("select h from DoseHistory h where h.medication.user.id = :uid and h.medication.active = true "
            + "and ((h.status = :pending and h.scheduledAt <= :now) "
            + "or (h.status = :snoozed and h.respondedAt <= :snoozeEnd)) "
            + "order by h.scheduledAt")
    List<DoseHistory> findDue(@Param("uid") Long userId, @Param("pending") DoseStatus pending,
                              @Param("snoozed") DoseStatus snoozed, @Param("now") LocalDateTime now,
                              @Param("snoozeEnd") LocalDateTime snoozeEnd);

    /** History for one user, newest first. */
    @Query("select h from DoseHistory h where h.medication.user.id = :uid "
            + "and h.scheduledAt >= :from and h.scheduledAt < :to order by h.scheduledAt desc")
    List<DoseHistory> history(@Param("uid") Long userId, @Param("from") LocalDateTime from,
                              @Param("to") LocalDateTime to);

    /** History for one user and one medication, newest first. */
    @Query("select h from DoseHistory h where h.medication.user.id = :uid and h.medication.id = :medId "
            + "and h.scheduledAt >= :from and h.scheduledAt < :to order by h.scheduledAt desc")
    List<DoseHistory> historyForMedication(@Param("uid") Long userId, @Param("medId") Long medicationId,
                                           @Param("from") LocalDateTime from, @Param("to") LocalDateTime to);

    /** Used by the scheduler to find doses nobody responded to. */
    List<DoseHistory> findByStatusAndScheduledAtBefore(DoseStatus status, LocalDateTime before);

    List<DoseHistory> findByStatusAndRespondedAtBefore(DoseStatus status, LocalDateTime before);

    /** Doses of a set of patients with a given status since a date (caregiver alerts). */
    @Query("select h from DoseHistory h where h.medication.user.id in :ids and h.status = :status "
            + "and h.scheduledAt >= :since order by h.scheduledAt desc")
    List<DoseHistory> findForPatients(@Param("ids") Collection<Long> patientIds,
                                      @Param("status") DoseStatus status, @Param("since") LocalDateTime since);

    /** All doses of one patient since a date (adherence summary). */
    @Query("select h from DoseHistory h where h.medication.user.id = :uid and h.scheduledAt >= :since "
            + "order by h.scheduledAt desc")
    List<DoseHistory> findSince(@Param("uid") Long userId, @Param("since") LocalDateTime since);
}
