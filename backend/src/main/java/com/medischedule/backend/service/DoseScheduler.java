package com.medischedule.backend.service;

import java.time.LocalDateTime;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/** Background jobs, once a minute. The real work lives in DoseService. */
@Component
public class DoseScheduler {

    private final DoseService doseService;

    public DoseScheduler(DoseService doseService) {
        this.doseService = doseService;
    }

    /** Create the PENDING doses that have just become due, then mark ignored ones missed. */
    @Scheduled(fixedDelay = 60_000, initialDelay = 15_000)
    public void run() {
        LocalDateTime now = LocalDateTime.now();
        doseService.createDueDoses(now);
        doseService.markOverdueAsMissed(now);
    }
}
