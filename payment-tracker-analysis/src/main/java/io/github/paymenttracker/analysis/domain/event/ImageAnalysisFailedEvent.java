/*
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-03 17:36:56
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-03 17:36:58
 * @FilePath: /payment-tracker/payment-tracker-analysis/src/main/java/io/github/paymenttracker/analysis/domain/event/ImageAnalysisFailedEvent.java
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
package io.github.paymenttracker.analysis.domain.event;

import java.time.Instant;
import java.util.UUID;

/**
 * Published when AI analysis of a payment image fails.
 */
public record ImageAnalysisFailedEvent(
    UUID eventId,
    Instant occurredOn,
    UUID attemptId,
    String reason
) {
    public ImageAnalysisFailedEvent(UUID attemptId, String reason) {
        this(UUID.randomUUID(), Instant.now(), attemptId, reason);
    }
}