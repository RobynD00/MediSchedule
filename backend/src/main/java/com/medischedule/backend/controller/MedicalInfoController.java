package com.medischedule.backend.controller;

import com.medischedule.backend.dto.MedicalInfoRequest;
import com.medischedule.backend.dto.MedicalInfoResponse;
import com.medischedule.backend.security.CurrentUser;
import com.medischedule.backend.service.MedicalInfoService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

/** Medical information endpoints. The user always comes from the token. */
@RestController
@RequestMapping("/api/medical-info")
public class MedicalInfoController {

    private final MedicalInfoService service;

    public MedicalInfoController(MedicalInfoService service) {
        this.service = service;
    }

    @GetMapping
    public MedicalInfoResponse get() {
        return service.get(CurrentUser.id());
    }

    @PutMapping
    public MedicalInfoResponse save(@Valid @RequestBody MedicalInfoRequest req) {
        return service.save(CurrentUser.id(), req);
    }

    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete() {
        service.delete(CurrentUser.id());
    }
}