package com.medischedule.backend.service;

import com.medischedule.backend.dto.AuthResponse;
import com.medischedule.backend.dto.IdentifierRequest;
import com.medischedule.backend.dto.LoginRequest;
import com.medischedule.backend.dto.MessageResponse;
import com.medischedule.backend.dto.RegisterRequest;
import com.medischedule.backend.dto.ResetPasswordRequest;
import com.medischedule.backend.dto.VerifyRequest;
import com.medischedule.backend.entity.User;
import com.medischedule.backend.exception.ApiException;
import com.medischedule.backend.repository.SessionRepository;
import com.medischedule.backend.repository.UserRepository;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * Registration, verification, login, password reset and logout.
 * The same code fields on User are used for the verification code and the reset code.
 * A reset code is only ever issued to active users and a verification code only to inactive ones.
 */
@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    /** Same message for a wrong identifier or a wrong password, so neither is revealed. */
    private static final String BAD_LOGIN = "Incorrect details. Please check and try again.";
    private static final String BAD_CODE = "That code is not correct or has expired.";
    private static final int CODE_VALID_MINUTES = 15;

    private final SecureRandom random = new SecureRandom();
    private final UserRepository userRepository;
    private final SessionRepository sessionRepository;
    private final SessionService sessionService;
    private final AuditService auditService;
    private final PasswordEncoder passwordEncoder;

    public AuthService(UserRepository userRepository,
                       SessionRepository sessionRepository,
                       SessionService sessionService,
                       AuditService auditService,
                       PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.sessionRepository = sessionRepository;
        this.sessionService = sessionService;
        this.auditService = auditService;
        this.passwordEncoder = passwordEncoder;
    }

    /** Creates an inactive account and sends a verification code. */
    public MessageResponse register(RegisterRequest request) {
        String email = normalizeEmail(request.email());
        String phone = normalizePhone(request.phone());

        if (email == null && phone == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Please enter an email address or a mobile number.");
        }
        if ((email != null && userRepository.existsByEmail(email))
                || (phone != null && userRepository.existsByPhone(phone))) {
            throw new ApiException(HttpStatus.CONFLICT,
                    "An account with these details already exists. Please log in or reset your password.");
        }

        User user = new User();
        user.setFullName(request.fullName().trim());
        user.setDateOfBirth(request.dateOfBirth());
        user.setEmail(email);
        user.setPhone(phone);
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setRole(request.role());
        user.setActive(false);
        sendNewCode(user, email != null ? email : phone);

        auditService.log(user, "REGISTER", null);
        return new MessageResponse("Account created. Please enter the code we sent you.");
    }

    /** Activates the account when the code is correct and not expired. */
    public MessageResponse verify(VerifyRequest request) {
        User user = findByIdentifier(request.identifier())
                .orElseThrow(() -> new ApiException(HttpStatus.BAD_REQUEST, BAD_CODE));
        checkCode(user, request.code());

        user.setActive(true);
        clearCode(user);
        userRepository.save(user);

        auditService.log(user, "ACCOUNT_VERIFIED", null);
        return new MessageResponse("Your account is verified. You can now log in.");
    }

    /** Sends a new verification code. Gives the same answer whether or not the account exists. */
    public MessageResponse resendCode(IdentifierRequest request) {
        findByIdentifier(request.identifier())
                .filter(user -> !user.isActive())
                .ifPresent(user -> sendNewCode(user, request.identifier()));
        return new MessageResponse("If the account needs verification, a new code has been sent.");
    }

    /** Checks the password, then opens a session and returns the token. */
    public AuthResponse login(LoginRequest request) {
        User user = findByIdentifier(request.identifier()).orElse(null);

        if (user == null || !passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            auditService.log(user, "LOGIN_FAILED", null);
            throw new ApiException(HttpStatus.UNAUTHORIZED, BAD_LOGIN);
        }
        if (!user.isActive()) {
            throw new ApiException(HttpStatus.FORBIDDEN,
                    "Please verify your account before logging in.");
        }

        String token = sessionService.createSession(user);
        auditService.log(user, "LOGIN_SUCCESS", null);
        return new AuthResponse(token, user.getId(), user.getFullName(), user.getRole(),
                user.getTextSize(), user.isHighContrast(), user.isVoiceReadout());
    }

    /** Sends a reset code. Gives the same answer whether or not the account exists. */
    public MessageResponse forgotPassword(IdentifierRequest request) {
        findByIdentifier(request.identifier())
                .filter(User::isActive)
                .ifPresent(user -> {
                    sendNewCode(user, request.identifier());
                    auditService.log(user, "PASSWORD_RESET_REQUESTED", null);
                });
        return new MessageResponse("If an account exists, a reset code has been sent.");
    }

    /** Sets a new password and signs the user out of every device. */
    public MessageResponse resetPassword(ResetPasswordRequest request) {
        User user = findByIdentifier(request.identifier())
                .filter(User::isActive)
                .orElseThrow(() -> new ApiException(HttpStatus.BAD_REQUEST, BAD_CODE));
        checkCode(user, request.code());

        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        clearCode(user);
        userRepository.save(user);

        sessionRepository.findByUserIdAndRevokedFalse(user.getId())
                .forEach(session -> sessionService.revoke(session.getToken()));

        auditService.log(user, "PASSWORD_RESET", null);
        return new MessageResponse("Your password has been changed. Please log in.");
    }

    /** Revokes the session behind the token so it stops working immediately. */
    public MessageResponse logout(String authorizationHeader) {
        if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
            String token = authorizationHeader.substring(7);
            sessionRepository.findByToken(token).ifPresent(session -> {
                sessionService.revoke(token);
                auditService.log(session.getUser(), "LOGOUT", null);
            });
        }
        return new MessageResponse("You have been logged out.");
    }

    private Optional<User> findByIdentifier(String identifier) {
        String value = identifier.trim();
        if (value.contains("@")) {
            return userRepository.findByEmail(value.toLowerCase());
        }
        return userRepository.findByPhone(value.replace(" ", ""));
    }

    private String normalizeEmail(String email) {
        return (email == null || email.isBlank()) ? null : email.trim().toLowerCase();
    }

    private String normalizePhone(String phone) {
        return (phone == null || phone.isBlank()) ? null : phone.replace(" ", "");
    }

    private void checkCode(User user, String code) {
        boolean valid = user.getVerificationCode() != null
                && user.getVerificationCode().equals(code.trim())
                && user.getVerificationExpiresAt() != null
                && user.getVerificationExpiresAt().isAfter(LocalDateTime.now());
        if (!valid) {
            throw new ApiException(HttpStatus.BAD_REQUEST, BAD_CODE);
        }
    }

    private void clearCode(User user) {
        user.setVerificationCode(null);
        user.setVerificationExpiresAt(null);
    }

    /**
     * Saves a new 6 digit code on the user.
     * Prototype: the code is written to the server log instead of being sent by SMS or email.
     * Replace the log line with a real sender when one is available.
     */
    private void sendNewCode(User user, String contact) {
        String code = String.format("%06d", random.nextInt(1_000_000));
        user.setVerificationCode(code);
        user.setVerificationExpiresAt(LocalDateTime.now().plusMinutes(CODE_VALID_MINUTES));
        userRepository.save(user);
        log.info("[DEV] Code for {} is {}", contact, code);
    }
}