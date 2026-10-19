package com.medischedule.backend.controller;

import com.medischedule.backend.dto.AuthResponse;
import com.medischedule.backend.dto.IdentifierRequest;
import com.medischedule.backend.dto.LoginRequest;
import com.medischedule.backend.dto.MessageResponse;
import com.medischedule.backend.dto.RegisterRequest;
import com.medischedule.backend.dto.ResetPasswordRequest;
import com.medischedule.backend.dto.VerifyRequest;
import com.medischedule.backend.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Public authentication endpoints. All paths under /api/auth are open in SecurityConfig. */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public MessageResponse register(@Valid @RequestBody RegisterRequest request) {
        return authService.register(request);
    }

    @PostMapping("/verify")
    public MessageResponse verify(@Valid @RequestBody VerifyRequest request) {
        return authService.verify(request);
    }

    @PostMapping("/resend-code")
    public MessageResponse resendCode(@Valid @RequestBody IdentifierRequest request) {
        return authService.resendCode(request);
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest request) {
        return authService.login(request);
    }

    @PostMapping("/forgot-password")
    public MessageResponse forgotPassword(@Valid @RequestBody IdentifierRequest request) {
        return authService.forgotPassword(request);
    }

    @PostMapping("/reset-password")
    public MessageResponse resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        return authService.resetPassword(request);
    }

    @PostMapping("/logout")
    public MessageResponse logout(
            @RequestHeader(value = "Authorization", required = false) String authorization) {
        return authService.logout(authorization);
    }
}