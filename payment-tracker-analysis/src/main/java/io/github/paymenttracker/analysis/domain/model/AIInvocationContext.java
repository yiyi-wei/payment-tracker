/*
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-03 17:30:07
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-06 12:33:41
 * @FilePath: /payment-tracker/payment-tracker-analysis/src/main/java/io/github/paymenttracker/analysis/domain/model/AIInvocationContext.java
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
package io.github.paymenttracker.analysis.domain.model;

import java.time.Instant;

/**
 * Represents the context of an AI model invocation for analysis.
 * This is a Value Object.
 */
public record AIInvocationContext(
    String modelName,
    String promptVersion,
    Instant requestTimestamp,
    Instant responseTimestamp,
    int retryCount
) {
    public AIInvocationContext withResponseTimestamp(Instant responseTimestamp) {
        return new AIInvocationContext(
            this.modelName,
            this.promptVersion,
            this.requestTimestamp,
            responseTimestamp,
            this.retryCount
        );
    }
}