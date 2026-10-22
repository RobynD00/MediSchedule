package com.medischedule.backend.controller;

import com.medischedule.backend.dto.DoseResponse;
import com.medischedule.backend.security.CurrentUser;
import com.medischedule.backend.service.DoseService;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.format.annotation.DateTimeFormat;
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
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to) {
        return service.history(CurrentUser.id(), medicationId, from, to);
    }
}
