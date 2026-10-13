package com.medischedule.backend.repository;

import com.medischedule.backend.entity.QrScanLog;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

/** Database access for QrScanLog. Add new queries here as modules need them. */
public interface QrScanLogRepository extends JpaRepository<QrScanLog, Long> {

    List<QrScanLog> findByQrTokenId(Long qrTokenId);
}