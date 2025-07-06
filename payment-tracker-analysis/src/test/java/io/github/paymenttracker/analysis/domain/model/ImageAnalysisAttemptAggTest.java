package io.github.paymenttracker.analysis.domain.model;

import io.github.paymenttracker.analysis.domain.event.ImageAnalysisFailedEvent;
import io.github.paymenttracker.analysis.domain.event.ImageAnalysisStartedEvent;
import io.github.paymenttracker.analysis.domain.event.ImageAnalysisSucceededEvent;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;

@DisplayName("ImageAnalysisAttemptAgg 领域模型单元测试")
class ImageAnalysisAttemptAggTest {

    @Test
    @DisplayName("创建时，应处于 PENDING_ANALYSIS 状态")
    void create_shouldInitializeWithPendingStatus() {
        // Given
        var paymentImageId = UUID.randomUUID();

        // When
        var attempt = ImageAnalysisAttemptAgg.create(paymentImageId);

        // Then
        assertThat(attempt).isNotNull();
        assertThat(attempt.getPaymentImageId()).isEqualTo(paymentImageId);
        assertThat(attempt.getStatus()).isEqualTo(AnalysisStatus.PENDING_ANALYSIS);
        assertThat(attempt.getDomainEvents()).isEmpty();
    }

    @Test
    @DisplayName("startAnalysis 应将状态变为 ANALYZING 并发布事件")
    void startAnalysis_shouldChangeStatusToAnalyzingAndPublishEvent() {
        // Given
        var attempt = ImageAnalysisAttemptAgg.create(UUID.randomUUID());
        var context = new AIInvocationContext("test-model", "v1", Instant.now(), null, 0);

        // When
        attempt.startAnalysis(context);

        // Then
        assertThat(attempt.getStatus()).isEqualTo(AnalysisStatus.ANALYZING);
        assertThat(attempt.getAiContext()).isEqualTo(context);
        assertThat(attempt.getDomainEvents())
            .hasSize(1)
            .element(0).isInstanceOf(ImageAnalysisStartedEvent.class);
    }

    @Test
    @DisplayName("recordSuccess 应将状态变为 ANALYSIS_SUCCEEDED 并发布事件")
    void recordSuccess_shouldChangeStatusToSucceededAndPublishEvent() {
        // Given
        var attempt = ImageAnalysisAttemptAgg.create(UUID.randomUUID());
        attempt.startAnalysis(new AIInvocationContext("test-model", "v1", Instant.now(), null, 0));
        var details = new ParsedPaymentDetails(BigDecimal.ONE, "CNY", LocalDateTime.now(), "shop", "card", "food");

        // When
        attempt.recordSuccess("raw", details);

        // Then
        assertThat(attempt.getStatus()).isEqualTo(AnalysisStatus.ANALYSIS_SUCCEEDED);
        assertThat(attempt.getRawAnalysisResult()).isEqualTo("raw");
        assertThat(attempt.getParsedPaymentDetails()).isEqualTo(details);
        assertThat(attempt.getDomainEvents())
            .hasSize(2) // Started + Succeeded
            .last().isInstanceOf(ImageAnalysisSucceededEvent.class);
    }

    @Test
    @DisplayName("recordFailure 应将状态变为 ANALYSIS_FAILED 并发布事件")
    void recordFailure_shouldChangeStatusToFailedAndPublishEvent() {
        // Given
        var attempt = ImageAnalysisAttemptAgg.create(UUID.randomUUID());
        attempt.startAnalysis(new AIInvocationContext("test-model", "v1", Instant.now(), null, 0));

        // When
        attempt.recordFailure("Timeout");

        // Then
        assertThat(attempt.getStatus()).isEqualTo(AnalysisStatus.ANALYSIS_FAILED);
        assertThat(attempt.getFailureReason()).isEqualTo("Timeout");
        assertThat(attempt.getDomainEvents())
            .hasSize(2) // Started + Failed
            .last().isInstanceOf(ImageAnalysisFailedEvent.class);
    }

    @Test
    @DisplayName("在错误状态下调用方法应抛出异常")
    void callingMethodsInWrongState_shouldThrowException() {
        // Given
        var successAttempt = ImageAnalysisAttemptAgg.create(UUID.randomUUID());
        successAttempt.startAnalysis(new AIInvocationContext("test-model", "v1", Instant.now(), null, 0));
        successAttempt.recordSuccess("raw", new ParsedPaymentDetails(BigDecimal.ONE, "CNY", LocalDateTime.now(), "shop", "card", "food"));

        var failedAttempt = ImageAnalysisAttemptAgg.create(UUID.randomUUID());
        failedAttempt.startAnalysis(new AIInvocationContext("test-model", "v1", Instant.now(), null, 0));
        failedAttempt.recordFailure("reason");

        // When & Then
        assertThatThrownBy(() -> successAttempt.recordFailure("late failure"))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("Cannot fail an attempt that has already succeeded.");

        assertThatThrownBy(() -> failedAttempt.recordSuccess("late success", null))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("Cannot record success for an attempt that has already failed.");
            
        assertThatThrownBy(() -> ImageAnalysisAttemptAgg.create(UUID.randomUUID()).recordSuccess("no start", null))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("Cannot record success for an attempt that has not started analyzing.");
    }
}