package io.github.paymenttracker.analysis.domain.model;

import java.time.Instant;
import java.util.UUID;

/**
 * Represents the user's final confirmation of an analysis result.
 * This is treated as a Value Object within the ImageAnalysisAttemptAgg aggregate.
 */
public record UserConfirmation(
    UUID confirmationId,
    UUID confirmedBy,
    Instant confirmedAt,
    ConfirmationType confirmationType,
    ParsedPaymentDetails correctedDetails // Optional, non-null if confirmationType is MODIFIED
) {
}