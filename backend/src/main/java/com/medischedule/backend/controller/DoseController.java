package com.medischedule.backend.controller;

import com.medischedule.backend.dto.DoseResponse;
import com.medischedule.backend.security.CurrentUser;
import com.medischedule.backend.service.DoseService;
import java.time.LocalDateTime;
import java.util.List;
import com.medischedule.backend.exception.ApiException;
import java.time.format.DateTimeParseException;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

/** Dose endpoints. {id} is a dose id (a DoseHistory row). */
@RestController
@RequestMapping("/api/doses")
public class DoseController {

    private final DoseService service;

    public DoseController(DoseService service) {
        this.service = service;
    }

    /** Doses the app should show a reminder for now. The app polls this. */
    @GetMapping("/due")
    public List<DoseResponse> due() {
        return service.due(CurrentUser.id());
    }

    @PostMapping("/{id}/taken")
    public DoseResponse taken(@PathVariable Long id) {
        return service.markTaken(CurrentUser.id(), id);
    }

    @PostMapping("/{id}/snooze")
    public DoseResponse snooze(@PathVariable Long id) {
        return service.snooze(CurrentUser.id(), id);
    }

    @PostMapping("/{id}/skip")
    public DoseResponse skip(@PathVariable Long id) {
        return service.skip(CurrentUser.id(), id);
    }

    /** e.g. GET /api/doses/history?medicationId=1&from=2026-10-01T00:00:00&to=2026-10-31T23:59:59 */
    @GetMapping("/history")
    public List<DoseResponse> history(
            @RequestParam(required = false) Long medicationId,
            @RequestParam(required = false) String from,
            @RequestParam(required = false) String to) {
        return service.history(CurrentUser.id(), medicationId, parse(from), parse(to));
    }

    /** Blank means "no limit". A bad value gives a clean 400 instead of a generic 500. */
    private static LocalDateTime parse(String value) {
        if (value == null || value.isBlank()) return null;
        try {
            return LocalDateTime.parse(value.trim());
        } catch (DateTimeParseException e) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Please use a date like 2026-10-01T00:00:00.");
        }
    }
}
