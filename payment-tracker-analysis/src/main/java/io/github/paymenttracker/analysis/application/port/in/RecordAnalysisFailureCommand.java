/*
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-03 17:37:55
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-03 17:37:58
 * @FilePath: /payment-tracker/payment-tracker-analysis/src/main/java/io/github/paymenttracker/analysis/application/port/in/RecordAnalysisFailureCommand.java
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
package io.github.paymenttracker.analysis.application.port.in;

import io.github.paymenttracker.analysis.domain.model.AIInvocationContext;

import java.util.UUID;

/**
 * Command to record a failed AI analysis attempt.
 */
public record RecordAnalysisFailureCommand(
    UUID attemptId,
    String failureReason,
    AIInvocationContext context
) {
}