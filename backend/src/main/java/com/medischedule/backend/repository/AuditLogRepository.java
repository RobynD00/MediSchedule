package com.medischedule.backend.repository;

import com.medischedule.backend.entity.AuditLog;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

/** Database access for AuditLog. Add new queries here as modules need them. */
public interface AuditLogRepository extends JpaRepository<AuditLog, Long> {

    List<AuditLog> findByUserIdOrderByTimestampDesc(Long userId);
}