package com.medischedule.backend.repository;

import com.medischedule.backend.entity.Session;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

/** Database access for Session. Add new queries here as modules need them. */
public interface SessionRepository extends JpaRepository<Session, Long> {

    Optional<Session> findByToken(String token);

    List<Session> findByUserIdAndRevokedFalse(Long userId);
}