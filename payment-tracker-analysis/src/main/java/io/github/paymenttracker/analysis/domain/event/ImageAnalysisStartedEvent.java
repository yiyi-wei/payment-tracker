package io.github.paymenttracker.analysis.domain.event;

import java.time.Instant;
import java.util.UUID;

/**
 * Represents the event when an image analysis attempt has started.
 *
 * @param eventId    The unique ID of the event.
 * @param occurredOn The timestamp when the event occurred.
 * @param attemptId  The ID of the analysis attempt that has started.
 */
public record ImageAnalysisStartedEvent(
    UUID eventId,
    Instant occurredOn,
    UUID attemptId
) {
    public ImageAnalysisStartedEvent(UUID attemptId) {
        this(UUID.randomUUID(), Instant.now(), attemptId);
    }
}