package com.medischedule.backend.repository;

import com.medischedule.backend.entity.QrToken;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

/** Database access for QrToken. Add new queries here as modules need them. */
public interface QrTokenRepository extends JpaRepository<QrToken, Long> {

    Optional<QrToken> findByToken(String token);

    List<QrToken> findByUserIdAndRevokedFalse(Long userId);
}