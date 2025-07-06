package io.github.paymenttracker.analysis.domain.event;

import java.time.Instant;
import java.util.UUID;

/**
 * Published when a new payment image is uploaded and requires AI analysis.
 */
public record ImageAnalysisRequestedEvent(
    UUID eventId,
    Instant occurredOn,
    UUID paymentImageId,
    String imageUrl
) {
    public ImageAnalysisRequestedEvent(UUID paymentImageId, String imageUrl) {
        this(UUID.randomUUID(), Instant.now(), paymentImageId, imageUrl);
    }
}