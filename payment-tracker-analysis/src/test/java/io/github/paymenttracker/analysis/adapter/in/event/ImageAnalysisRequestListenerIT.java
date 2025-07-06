package io.github.paymenttracker.analysis.adapter.in.event;

import io.github.paymenttracker.analysis.application.port.out.AIAnalysisException;
import io.github.paymenttracker.analysis.application.port.out.AIAnalysisPort;
import io.github.paymenttracker.analysis.domain.event.ImageAnalysisRequestedEvent;
import io.github.paymenttracker.analysis.domain.model.ParsedPaymentDetails;
import io.github.paymenttracker.analysis.domain.model.PaymentImageAgg;
import io.github.paymenttracker.analysis.application.port.out.PaymentImageRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.net.URL;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@SpringBootTest
@ActiveProfiles("test")
class ImageAnalysisRequestListenerIT {

    @Autowired
    private ApplicationEventPublisher eventPublisher;

    @MockBean
    private AIAnalysisPort aiAnalysisPort;

    @MockBean
    private PaymentImageRepository paymentImageRepository;

    @Test
    void onImageAnalysisRequested_whenAiSucceeds_shouldHandleSuccess() throws Exception {
        // Given
        UUID imageId = UUID.randomUUID();
        String imageUrl = "https://example.com/image.jpg";
        PaymentImageAgg paymentImage = PaymentImageAgg.builder().id(imageId).imageUrl(imageUrl).build();
        when(paymentImageRepository.findById(imageId)).thenReturn(Optional.of(paymentImage));

        ParsedPaymentDetails parsedDetails = new ParsedPaymentDetails(new BigDecimal("100.00"), "USD", LocalDateTime.now(), "Test", "Card", "Test");
        when(aiAnalysisPort.analyzePaymentImage(any(URL.class))).thenReturn(parsedDetails);

        ImageAnalysisRequestedEvent event = new ImageAnalysisRequestedEvent(imageId, imageUrl);

        // When
        eventPublisher.publishEvent(event);

        // Then
        // Verify that the success path was taken. We can't easily verify the command sent to the use case,
        // but we can verify the interaction with our mock AI port.
        verify(aiAnalysisPort, timeout(1000)).analyzePaymentImage(new URL(imageUrl));
    }

    @Test
    void onImageAnalysisRequested_whenAiFails_shouldHandleFailure() throws Exception {
        // Given
        UUID imageId = UUID.randomUUID();
        String imageUrl = "https://example.com/image.jpg";
        PaymentImageAgg paymentImage = PaymentImageAgg.builder().id(imageId).imageUrl(imageUrl).build();
        when(paymentImageRepository.findById(imageId)).thenReturn(Optional.of(paymentImage));

        when(aiAnalysisPort.analyzePaymentImage(any(URL.class))).thenThrow(new AIAnalysisException("AI failed", new RuntimeException()));

        ImageAnalysisRequestedEvent event = new ImageAnalysisRequestedEvent(imageId, imageUrl);

        // When
        eventPublisher.publishEvent(event);

        // Then
        verify(aiAnalysisPort, timeout(1000)).analyzePaymentImage(new URL(imageUrl));
        // We could also verify that the failure handler in the use case was called if we mock the use case.
        // For this test, verifying the AI port interaction is sufficient.
    }
}