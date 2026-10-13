package com.medischedule.backend.dto;

/** Standard error body returned by every failed API call. */
public record ErrorResponse(int status, String message) {
}