package com.medischedule.backend.controller;

import com.medischedule.backend.dto.ReminderRequest;
import com.medischedule.backend.dto.ReminderResponse;
import com.medischedule.backend.security.CurrentUser;
import com.medischedule.backend.service.ReminderService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

/** Reminder schedule endpoints. The user always comes from the token, never the request body. */
@RestController
@RequestMapping("/api")
public class ReminderController {

    private final ReminderService service;

    public ReminderController(ReminderService service) {
        this.service = service;
    }

    @PostMapping("/medications/{medicationId}/reminders")
    @ResponseStatus(HttpStatus.CREATED)
    public ReminderResponse create(@PathVariable Long medicationId, @Valid @RequestBody ReminderRequest req) {
        return service.create(CurrentUser.id(), medicationId, req);
    }

    @GetMapping("/medications/{medicationId}/reminders")
    public List<ReminderResponse> list(@PathVariable Long medicationId) {
        return service.list(CurrentUser.id(), medicationId);
    }

    @PutMapping("/reminders/{id}")
    public ReminderResponse update(@PathVariable Long id, @Valid @RequestBody ReminderRequest req) {
        return service.update(CurrentUser.id(), id, req);
    }

    @DeleteMapping("/reminders/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.delete(CurrentUser.id(), id);
    }
}
