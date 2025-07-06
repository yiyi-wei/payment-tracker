package io.github.paymenttracker.analysis.domain.event;

import io.github.paymenttracker.analysis.domain.model.ParsedPaymentDetails;

import java.time.Instant;
import java.util.UUID;

/**
 * Published when AI analysis of a payment image succeeds.
 */
public record ImageAnalysisSucceededEvent(
    UUID eventId,
    Instant occurredOn,
    UUID attemptId,
    ParsedPaymentDetails parsedDetails
) {
    public ImageAnalysisSucceededEvent(UUID attemptId, ParsedPaymentDetails parsedDetails) {
        this(UUID.randomUUID(), Instant.now(), attemptId, parsedDetails);
    }
}