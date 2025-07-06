package io.github.paymenttracker.analysis.application.port.out;

import java.util.List;

/**
 * Interface for publishing domain events.
 */
public interface DomainEventPublisher {

    /**
     * Publishes a single domain event.
     *
     * @param event The domain event to publish.
     */
    void publish(Object event);

    /**
     * Publishes a list of domain events.
     *
     * @param events The list of domain events to publish.
     */
    default void publish(List<Object> events) {
        events.forEach(this::publish);
    }
}