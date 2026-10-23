package com.medischedule.backend.controller;

import com.medischedule.backend.dto.MedicationRequest;
import com.medischedule.backend.dto.MedicationResponse;
import com.medischedule.backend.security.CurrentUser;
import com.medischedule.backend.service.MedicationService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

/** Medication endpoints. The user always comes from the token, never the request body. */
@RestController
@RequestMapping("/api/medications")
public class MedicationController {

    private final MedicationService service;

    public MedicationController(MedicationService service) {
        this.service = service;
    }

    @GetMapping
    public List<MedicationResponse> list() {
        return service.list(CurrentUser.id());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public MedicationResponse create(@Valid @RequestBody MedicationRequest req) {
        return service.create(CurrentUser.id(), req);
    }

    @PutMapping("/{id}")
    public MedicationResponse update(@PathVariable Long id, @Valid @RequestBody MedicationRequest req) {
        return service.update(CurrentUser.id(), id, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.delete(CurrentUser.id(), id);
    }
}