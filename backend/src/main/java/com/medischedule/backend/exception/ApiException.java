package com.medischedule.backend.exception;

import org.springframework.http.HttpStatus;

/**
 * Throw this from services when a request must fail with a clear message.
 * Example: throw new ApiException(HttpStatus.NOT_FOUND, "Medication not found.");
 * Keep messages simple and non-technical. Never include passwords or medical data.
 */
public class ApiException extends RuntimeException {

    private final HttpStatus status;

    public ApiException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }
}