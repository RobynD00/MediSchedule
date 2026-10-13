package com.medischedule.backend.service;

import com.medischedule.backend.entity.Session;
import com.medischedule.backend.entity.User;
import com.medischedule.backend.repository.SessionRepository;
import com.medischedule.backend.security.JwtUtil;
import java.time.Duration;
import java.time.LocalDateTime;
import org.springframework.stereotype.Service;

/**
 * Login and logout sessions. Used by the auth module.
 * Login: call createSession(user) and return the token to the app.
 * Logout: call revoke(token).
 */
@Service
public class SessionService {

    private final SessionRepository sessionRepository;
    private final JwtUtil jwtUtil;

    public SessionService(SessionRepository sessionRepository, JwtUtil jwtUtil) {
        this.sessionRepository = sessionRepository;
        this.jwtUtil = jwtUtil;
    }

    /** Creates a token and saves its Session row. Returns the token. */
    public String createSession(User user) {
        String token = jwtUtil.generateToken(user.getId(), user.getRole().name());
        Session session = new Session();
        session.setUser(user);
        session.setToken(token);
        session.setExpiresAt(LocalDateTime.now().plus(Duration.ofMillis(jwtUtil.getExpirationMs())));
        session.setRevoked(false);
        sessionRepository.save(session);
        return token;
    }

    /** Marks the session as revoked so the token stops working. */
    public void revoke(String token) {
        sessionRepository.findByToken(token).ifPresent(session -> {
            session.setRevoked(true);
            sessionRepository.save(session);
        });
    }
}