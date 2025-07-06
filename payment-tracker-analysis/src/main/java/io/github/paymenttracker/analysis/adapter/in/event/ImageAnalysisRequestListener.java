/*
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-03 17:41:45
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-06 12:34:25
 * @FilePath: /payment-tracker/payment-tracker-analysis/src/main/java/io/github/paymenttracker/analysis/adapter/in/event/ImageAnalysisRequestListener.java
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
package io.github.paymenttracker.analysis.adapter.in.event;

import io.github.paymenttracker.analysis.application.port.in.ImageAnalysisUseCase;
import io.github.paymenttracker.analysis.application.port.in.RecordAnalysisFailureCommand;
import io.github.paymenttracker.analysis.application.port.in.RecordAnalysisSuccessCommand;
import io.github.paymenttracker.analysis.application.port.out.AIAnalysisException;
import io.github.paymenttracker.analysis.application.port.out.AIAnalysisPort;
import io.github.paymenttracker.analysis.application.port.out.ImageAnalysisAttemptRepository;
import io.github.paymenttracker.analysis.application.port.out.PaymentImageRepository;
import io.github.paymenttracker.analysis.domain.event.ImageAnalysisRequestedEvent;
import io.github.paymenttracker.analysis.domain.model.AIInvocationContext;
import io.github.paymenttracker.analysis.domain.model.ImageAnalysisAttemptAgg;
import io.github.paymenttracker.analysis.domain.model.ParsedPaymentDetails;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import java.net.URL;
import java.time.Instant;
import java.util.UUID;

@Slf4j
@Component
@RequiredArgsConstructor
public class ImageAnalysisRequestListener {

    private final ImageAnalysisUseCase imageAnalysisUseCase;
    private final ImageAnalysisAttemptRepository attemptRepository;
    private final PaymentImageRepository paymentImageRepository; // To fetch image details
    private final AIAnalysisPort aiAnalysisPort; // Inject the new port

    @Value("${langchain4j.open-ai.chat-model.model-name}")
    private String modelName;

    @EventListener
    @Async
    public void onImageAnalysisRequested(ImageAnalysisRequestedEvent event) {
        log.info("Received ImageAnalysisRequestedEvent for image ID: {}. Starting REAL AI analysis.", event.paymentImageId());

        // 1. Create and start the analysis attempt
        var newAttempt = ImageAnalysisAttemptAgg.create(event.paymentImageId());
        var invocationContext = new AIInvocationContext(modelName, "1.0", Instant.now(), null, 0);
        newAttempt.startAnalysis(invocationContext);
        attemptRepository.save(newAttempt);
        log.info("Created and started new ImageAnalysisAttempt with ID: {}", newAttempt.getId());

        // 2. Perform the REAL AI analysis process
        try {
            // Fetch the image URL from the repository
            var paymentImage = paymentImageRepository.findById(event.paymentImageId())
                .orElseThrow(() -> new IllegalStateException("PaymentImage not found for ID: " + event.paymentImageId()));

            // Call the AI service via the port
            ParsedPaymentDetails parsedDetails = aiAnalysisPort.analyzePaymentImage(new URL(paymentImage.getImageUrl()));

            // Handle success
            handleSuccess(newAttempt.getId(), parsedDetails, invocationContext);

        } catch (AIAnalysisException | IllegalStateException | java.net.MalformedURLException e) {
            log.error("AI analysis FAILED for attempt ID: {}", newAttempt.getId(), e);
            // Handle failure
            handleFailure(newAttempt.getId(), e.getMessage(), invocationContext);
        }
    }

    private void handleSuccess(UUID attemptId, ParsedPaymentDetails parsedDetails, AIInvocationContext context) {
        var command = new RecordAnalysisSuccessCommand(
            attemptId,
            "Successfully parsed by AI.", // Raw text can be part of ParsedPaymentDetails if needed
            parsedDetails,
            context.withResponseTimestamp(Instant.now())
        );
        imageAnalysisUseCase.handleAnalysisSuccess(command);
        log.info("Real AI analysis SUCCEEDED for attempt ID: {}", attemptId);
    }

    private void handleFailure(UUID attemptId, String errorMessage, AIInvocationContext context) {
        var command = new RecordAnalysisFailureCommand(
            attemptId,
            errorMessage,
            context.withResponseTimestamp(Instant.now())
        );
        imageAnalysisUseCase.handleAnalysisFailure(command);
        log.info("Real AI analysis FAILED for attempt ID: {}", attemptId);
    }
}