/*
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-03 17:29:40
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-03 17:29:44
 * @FilePath: /payment-tracker/payment-tracker-analysis/src/main/java/io/github/paymenttracker/analysis/domain/model/AnalysisStatus.java
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
package io.github.paymenttracker.analysis.domain.model;

/**
 * Represents the status of an AI analysis attempt.
 */
public enum AnalysisStatus {
    /**
     * The analysis request has been received and is waiting to be processed.
     */
    PENDING_ANALYSIS,

    /**
     * The analysis is currently in progress.
     */
    ANALYZING,

    /**
     * The analysis completed successfully.
     */
    ANALYSIS_SUCCEEDED,

    /**
     * The analysis failed.
     */
    ANALYSIS_FAILED,

    /**
     * The analysis result is waiting for user confirmation.
     */
    PENDING_CONFIRMATION,

    /**
     * The user has confirmed the analysis result is correct.
     */
    CONFIRMED,

    /**
     * The user has rejected the analysis result.
     */
    REJECTED
}