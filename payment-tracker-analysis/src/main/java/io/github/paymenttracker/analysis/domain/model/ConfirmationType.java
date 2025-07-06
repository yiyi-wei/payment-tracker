/*
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-03 17:29:49
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-03 17:29:52
 * @FilePath: /payment-tracker/payment-tracker-analysis/src/main/java/io/github/paymenttracker/analysis/domain/model/ConfirmationType.java
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
package io.github.paymenttracker.analysis.domain.model;

/**
 * Represents the type of user confirmation for an analysis result.
 */
public enum ConfirmationType {
    /**
     * The user accepted the AI-parsed result as correct.
     */
    ACCEPTED,

    /**
     * The user modified the AI-parsed result before accepting.
     */
    MODIFIED,

    /**
     * The user rejected the AI-parsed result as incorrect.
     */
    REJECTED
}