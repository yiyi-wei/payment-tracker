/*
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-03 17:37:07
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-06 12:42:23
 * @FilePath: /payment-tracker/payment-tracker-analysis/src/main/java/io/github/paymenttracker/analysis/domain/model/ImageAnalysisAttemptAgg.java
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
package io.github.paymenttracker.analysis.domain.model;

import io.github.paymenttracker.analysis.domain.common.BaseAggregateRoot;
import io.github.paymenttracker.analysis.domain.event.ImageAnalysisFailedEvent;
import io.github.paymenttracker.analysis.domain.event.ImageAnalysisStartedEvent;
import io.github.paymenttracker.analysis.domain.event.ImageAnalysisSucceededEvent;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

import java.util.UUID;

@Getter
@SuperBuilder
@NoArgsConstructor
public class ImageAnalysisAttemptAgg extends BaseAggregateRoot<UUID> {

    private UUID paymentImageId;
    private AnalysisStatus status;
    private AIInvocationContext aiContext;
    private String rawAnalysisResult;
    private ParsedPaymentDetails parsedPaymentDetails;
    private UserConfirmation userConfirmation;
    private String failureReason;

    private ImageAnalysisAttemptAgg(UUID paymentImageId) {
        super(UUID.randomUUID());
        this.paymentImageId = paymentImageId;
        this.status = AnalysisStatus.PENDING_ANALYSIS;
    }

    public static ImageAnalysisAttemptAgg create(UUID paymentImageId) {
        return new ImageAnalysisAttemptAgg(paymentImageId);
    }

    public void startAnalysis(AIInvocationContext context) {
        if (this.status != AnalysisStatus.PENDING_ANALYSIS) {
            throw new IllegalStateException("Cannot start analysis for an attempt that is not pending.");
        }
        this.status = AnalysisStatus.ANALYZING;
        this.aiContext = context;
        registerEvent(new ImageAnalysisStartedEvent(this.getId()));
    }

    public void recordSuccess(String rawResult, ParsedPaymentDetails details) {
        if (this.status == AnalysisStatus.ANALYSIS_SUCCEEDED) {
            throw new IllegalStateException("Cannot record success for an attempt that has already succeeded.");
        }
        if (this.status == AnalysisStatus.ANALYSIS_FAILED) {
            throw new IllegalStateException("Cannot record success for an attempt that has already failed.");
        }
        if (this.status != AnalysisStatus.ANALYZING) {
            throw new IllegalStateException("Cannot record success for an attempt that has not started analyzing.");
        }
        this.status = AnalysisStatus.ANALYSIS_SUCCEEDED;
        this.rawAnalysisResult = rawResult;
        this.parsedPaymentDetails = details;
        this.failureReason = null;
        registerEvent(new ImageAnalysisSucceededEvent(this.getId(), this.parsedPaymentDetails));
    }

    public void recordFailure(String reason) {
        if (this.status == AnalysisStatus.ANALYSIS_SUCCEEDED) {
            throw new IllegalStateException("Cannot fail an attempt that has already succeeded.");
        }
        if (this.status == AnalysisStatus.ANALYSIS_FAILED) {
            throw new IllegalStateException("Cannot fail an attempt that has already failed.");
        }
        if (this.status != AnalysisStatus.ANALYZING) {
            throw new IllegalStateException("Cannot fail an attempt that has not started analyzing.");
        }
        this.status = AnalysisStatus.ANALYSIS_FAILED;
        this.failureReason = reason;
        registerEvent(new ImageAnalysisFailedEvent(this.getId(), reason));
    }
}