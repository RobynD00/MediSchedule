package com.medischedule.backend.controller;

import com.medischedule.backend.dto.MessageResponse;
import com.medischedule.backend.dto.QrGenerateRequest;
import com.medischedule.backend.dto.QrScanResponse;
import com.medischedule.backend.dto.QrStatusResponse;
import com.medischedule.backend.security.CurrentUser;
import com.medischedule.backend.service.QrService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

/**
 * QR endpoints. Only /api/qr/scan/** is public (see SecurityConfig).
 * Everything else needs the patient's login token.
 */
@RestController
@RequestMapping("/api/qr")
public class QrController {

    private final QrService service;

    public QrController(QrService service) {
        this.service = service;
    }

    @GetMapping("/current")
    public QrStatusResponse current() {
        return service.current(CurrentUser.id());
    }

    @PostMapping("/generate")
    @ResponseStatus(HttpStatus.CREATED)
    public QrStatusResponse generate(@Valid @RequestBody QrGenerateRequest req) {
        return service.generate(CurrentUser.id(), req);
    }

    @PostMapping("/revoke")
    public MessageResponse revoke() {
        service.revoke(CurrentUser.id());
        return new MessageResponse("Your QR code has been switched off.");
    }

    /** Public. Anyone holding a valid token sees only what the patient approved. */
    @GetMapping("/scan/{token}")
    public QrScanResponse scan(@PathVariable String token, HttpServletRequest request) {
        String agent = request.getHeader("User-Agent");
        String metadata = "ip=" + request.getRemoteAddr() + "; agent="
                + (agent == null ? "unknown" : agent.substring(0, Math.min(agent.length(), 120)));
        return service.scan(token, metadata);
    }
}