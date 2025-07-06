package io.github.paymenttracker.analysis.application;

import io.github.paymenttracker.analysis.application.port.in.RecordAnalysisFailureCommand;
import io.github.paymenttracker.analysis.application.port.in.RecordAnalysisSuccessCommand;
import io.github.paymenttracker.analysis.application.port.in.UploadPaymentImageCommand;
import io.github.paymenttracker.analysis.application.port.out.DomainEventPublisher;
import io.github.paymenttracker.analysis.application.port.out.ImageAnalysisAttemptRepository;
import io.github.paymenttracker.analysis.application.port.out.PaymentImageRepository;
import io.github.paymenttracker.analysis.application.port.out.StorageService;
import io.github.paymenttracker.analysis.domain.event.ImageAnalysisFailedEvent;
import io.github.paymenttracker.analysis.domain.event.ImageAnalysisRequestedEvent;
import io.github.paymenttracker.analysis.domain.event.ImageAnalysisSucceededEvent;
import io.github.paymenttracker.analysis.domain.model.AIInvocationContext;
import io.github.paymenttracker.analysis.domain.model.ImageAnalysisAttemptAgg;
import io.github.paymenttracker.analysis.domain.model.ParsedPaymentDetails;
import io.github.paymenttracker.analysis.domain.model.PaymentImageAgg;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("ImageAnalysisApplicationService 单元测试")
class ImageAnalysisApplicationServiceTest {

    @InjectMocks
    private ImageAnalysisApplicationService imageAnalysisService;

    @Mock
    private PaymentImageRepository paymentImageRepository;
    @Mock
    private ImageAnalysisAttemptRepository attemptRepository;
    @Mock
    private StorageService storageService;
    @Mock
    private DomainEventPublisher eventPublisher;

    @Captor
    private ArgumentCaptor<PaymentImageAgg> paymentImageAggCaptor;
    @Captor
    private ArgumentCaptor<ImageAnalysisAttemptAgg> attemptAggCaptor;
    @Captor
    private ArgumentCaptor<List<Object>> eventListCaptor;

    private UUID uploaderId;
    private byte[] imageBytes;

    @BeforeEach
    void setUp() {
        uploaderId = UUID.randomUUID();
        imageBytes = "test-image-data".getBytes();
    }

    @Test
    @DisplayName("当上传新图片时，应成功处理并发布分析请求事件")
    void handleImageUpload_whenNewImage_shouldProcessAndPublishEvent() throws IOException {
        // Given
        var command = new UploadPaymentImageCommand(
            uploaderId,
            new ByteArrayInputStream(imageBytes),
            "test.jpg",
            "image/jpeg",
            imageBytes.length
        );
        when(paymentImageRepository.findByHash(anyString())).thenReturn(Optional.empty());
        when(storageService.upload(anyString(), any())).thenReturn("http://storage.com/test.jpg");

        // When
        UUID imageId = imageAnalysisService.handleImageUpload(command);

        // Then
        assertThat(imageId).isNotNull();
        verify(storageService).upload(eq("test.jpg"), any(ByteArrayInputStream.class));
        verify(paymentImageRepository).save(paymentImageAggCaptor.capture());
        PaymentImageAgg savedAgg = paymentImageAggCaptor.getValue();
        assertThat(savedAgg.getUserId()).isEqualTo(uploaderId.toString());
        assertThat(savedAgg.getImageUrl()).isEqualTo("http://storage.com/test.jpg");

        verify(eventPublisher).publish(eventListCaptor.capture());
        List<Object> publishedEvents = eventListCaptor.getValue();
        assertThat(publishedEvents).hasSize(1).element(0).isInstanceOf(ImageAnalysisRequestedEvent.class);
        ImageAnalysisRequestedEvent event = (ImageAnalysisRequestedEvent) publishedEvents.get(0);
        assertThat(event.paymentImageId()).isEqualTo(savedAgg.getId());
        assertThat(event.imageUrl()).isEqualTo("http://storage.com/test.jpg");
    }

    @Test
    @DisplayName("当上传重复图片时，应重新触发分析且不创建新聚合根")
    void handleImageUpload_whenDuplicateImage_shouldReTriggerAnalysis() throws IOException {
        // Given
        var command = new UploadPaymentImageCommand(
            uploaderId,
            new ByteArrayInputStream(imageBytes),
            "test.jpg",
            "image/jpeg",
            imageBytes.length
        );
        var existingImage = PaymentImageAgg.create(uploaderId.toString(), "existing.jpg", "image/jpeg", (long) imageBytes.length, "existing-hash", "http://storage.com/existing.jpg");
        when(paymentImageRepository.findByHash(anyString())).thenReturn(Optional.of(existingImage));

        // When
        imageAnalysisService.handleImageUpload(command);

        // Then
        verify(storageService, never()).upload(any(), any());
        verify(paymentImageRepository).save(existingImage); // Save to persist event state change
        verify(eventPublisher).publish(anyList());
    }

    @Test
    @DisplayName("当处理分析成功回调时，应正确更新Attempt聚合根并发布成功事件")
    void handleAnalysisSuccess_shouldUpdateAttemptAndPublishSuccessEvent() {
        // Given
        var attemptId = UUID.randomUUID();
        var attempt = ImageAnalysisAttemptAgg.create(UUID.randomUUID());
        attempt.startAnalysis(new AIInvocationContext("test-model", "v1", Instant.now(), null, 0));
        var command = new RecordAnalysisSuccessCommand(
            attemptId,
            "raw-result",
            new ParsedPaymentDetails(BigDecimal.TEN, "USD", LocalDateTime.now(), "Test", "Card", "Food"),
            new AIInvocationContext("test-model", "v1", Instant.now(), Instant.now(), 0)
        );
        when(attemptRepository.findById(attemptId)).thenReturn(Optional.of(attempt));

        // When
        imageAnalysisService.handleAnalysisSuccess(command);

        // Then
        verify(attemptRepository).save(attemptAggCaptor.capture());
        ImageAnalysisAttemptAgg savedAttempt = attemptAggCaptor.getValue();
        assertThat(savedAttempt.getStatus()).isEqualTo(io.github.paymenttracker.analysis.domain.model.AnalysisStatus.ANALYSIS_SUCCEEDED);
        assertThat(savedAttempt.getRawAnalysisResult()).isEqualTo("raw-result");

        verify(eventPublisher).publish(eventListCaptor.capture());
        List<Object> publishedEvents = eventListCaptor.getValue();
        assertThat(publishedEvents).hasSize(2).last().isInstanceOf(ImageAnalysisSucceededEvent.class);
    }

    @Test
    @DisplayName("当处理分析失败回调时，应正确更新Attempt聚合根并发布失败事件")
    void handleAnalysisFailure_shouldUpdateAttemptAndPublishFailureEvent() {
        // Given
        var attemptId = UUID.randomUUID();
        var attempt = ImageAnalysisAttemptAgg.create(UUID.randomUUID());
        attempt.startAnalysis(new AIInvocationContext("test-model", "v1", Instant.now(), null, 0));
        var command = new RecordAnalysisFailureCommand(
            attemptId,
            "AI timeout",
            new AIInvocationContext("test-model", "v1", Instant.now(), Instant.now(), 3)
        );
        when(attemptRepository.findById(attemptId)).thenReturn(Optional.of(attempt));

        // When
        imageAnalysisService.handleAnalysisFailure(command);

        // Then
        verify(attemptRepository).save(attemptAggCaptor.capture());
        ImageAnalysisAttemptAgg savedAttempt = attemptAggCaptor.getValue();
        assertThat(savedAttempt.getStatus()).isEqualTo(io.github.paymenttracker.analysis.domain.model.AnalysisStatus.ANALYSIS_FAILED);
        assertThat(savedAttempt.getFailureReason()).isEqualTo("AI timeout");

        verify(eventPublisher).publish(eventListCaptor.capture());
        List<Object> publishedEvents = eventListCaptor.getValue();
        assertThat(publishedEvents).hasSize(2).last().isInstanceOf(ImageAnalysisFailedEvent.class);
    }

    @Test
    @DisplayName("当处理回调但Attempt不存在时，应抛出异常")
    void handleCallback_whenAttemptNotFound_shouldThrowException() {
        // Given
        var attemptId = UUID.randomUUID();
        var successCommand = new RecordAnalysisSuccessCommand(attemptId, null, null, null);
        var failureCommand = new RecordAnalysisFailureCommand(attemptId, null, null);
        when(attemptRepository.findById(attemptId)).thenReturn(Optional.empty());

        // When & Then
        assertThatThrownBy(() -> imageAnalysisService.handleAnalysisSuccess(successCommand))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("Attempt not found for ID:");

        assertThatThrownBy(() -> imageAnalysisService.handleAnalysisFailure(failureCommand))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("Attempt not found for ID:");
    }
}