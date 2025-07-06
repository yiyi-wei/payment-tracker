/*
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-03 17:30:33
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-06 12:41:53
 * @FilePath: /payment-tracker/payment-tracker-analysis/src/main/java/io/github/paymenttracker/analysis/domain/common/BaseAggregateRoot.java
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
package io.github.paymenttracker.analysis.domain.common;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Base class for aggregate roots, providing capabilities for managing domain events.
 *
 * @param <ID> The type of the aggregate's identifier.
 */
@Getter
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
public abstract class BaseAggregateRoot<ID> {

    private ID id;
    protected final transient List<Object> domainEvents = new ArrayList<>();

    /**
     * Registers a domain event.
     *
     * @param event The domain event to register.
     */
    protected void registerEvent(Object event) {
        domainEvents.add(event);
    }

    /**
     * Atomically retrieves all registered domain events and clears the list.
     * This ensures that events are handled only once.
     *
     * @return A new list containing the domain events that were cleared.
     */
    public List<Object> pullDomainEvents() {
        if (domainEvents.isEmpty()) {
            return Collections.emptyList();
        }
        // Create a copy and clear the original list atomically.
        List<Object> events = new ArrayList<>(this.domainEvents);
        this.domainEvents.clear();
        return events;
    }

    /**
     * Returns an unmodifiable view of the domain events.
     * This method is intended for testing purposes only.
     *
     * @return An unmodifiable list of domain events.
     */
    public List<Object> getDomainEvents() {
        return Collections.unmodifiableList(domainEvents);
    }

    /**
     * Gets the aggregate root's identifier.
     *
     * @return The identifier.
     */
    public ID getId() {
        return id;
    }
}