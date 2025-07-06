/*
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-03 17:29:58
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-03 17:30:01
 * @FilePath: /payment-tracker/payment-tracker-analysis/src/main/java/io/github/paymenttracker/analysis/domain/model/ParsedPaymentDetails.java
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
package io.github.paymenttracker.analysis.domain.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Represents the structured payment data extracted from an AI analysis.
 * This is a Value Object.
 */
public record ParsedPaymentDetails(
    BigDecimal amount,
    String currency,
    LocalDateTime transactionDate,
    String payee,
    String paymentMethod,
    String categoryGuess
) {
}