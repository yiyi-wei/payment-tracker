# Pseudocode: Real AI Service Integration for Image Analysis

This document outlines the pseudocode for replacing the simulated AI analysis logic with a real AI service call using LangChain4j and a specified model endpoint.

## 1. Define the Outbound Port (Interface)

This interface defines the contract for interacting with an external AI vision model. It decouples the application core from the specific implementation of the AI service.

**File:** `payment-tracker-analysis/src/main/java/io/github/paymenttracker/analysis/application/port/out/AIAnalysisPort.java`

```java
package io.github.paymenttracker.analysis.application.port.out;

import io.github.paymenttracker.analysis.domain.model.ParsedPaymentDetails;
import java.net.URL;

// Interface for AI-based image analysis
interface AIAnalysisPort {

    /**
     * Analyzes a payment image and extracts payment details.
     *
     * @param imageUrl The URL of the image to be analyzed.
     * @return ParsedPaymentDetails containing the extracted information.
     * @throws AIAnalysisException if the analysis fails for any reason.
     */
    ParsedPaymentDetails analyzePaymentImage(URL imageUrl);
}

// Custom exception for AI analysis failures
class AIAnalysisException extends RuntimeException {
    public AIAnalysisException(String message, Throwable cause) {
        super(message, cause);
    }
}
```

## 2. Create the Outbound Adapter (Implementation)

This adapter implements the `AIAnalysisPort` using `LangChain4j` to connect to the actual AI service (e.g., Alibaba Qwen hosted on Dashscope).

**File:** `payment-tracker-analysis/src/main/java/io/github/paymenttracker/analysis/adapter/out/ai/LangChain4jAIAnalysisAdapter.java`

```java
package io.github.paymenttracker.analysis.adapter.out.ai;

import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.model.input.PromptTemplate;
import dev.langchain4j.model.input.structured.StructuredPrompt;
import dev.langchain4j.service.AiServices;
import io.github.paymenttracker.analysis.application.port.out.AIAnalysisPort;
import io.github.paymenttracker.analysis.application.port.out.AIAnalysisException;
import io.github.paymenttracker.analysis.domain.model.ParsedPaymentDetails;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.net.URL;

@Component
@RequiredArgsConstructor
class LangChain4jAIAnalysisAdapter implements AIAnalysisPort {

    // LangChain4j will automatically configure this model based on application.yml properties
    private final ChatLanguageModel chatLanguageModel;

    // Define a structured prompt for extracting payment details
    @StructuredPrompt({
        "Analyze the payment receipt image at the given URL and extract the following details:",
        " - Total amount",
        " - Currency (e.g., CNY, USD)",
        " - Transaction date and time",
        " - Payee name",
        " - Payment method",
        " - Category of the expense",
        "The image is available at: {{imageUrl}}"
    })
    interface PaymentDetailsExtractor {
        ParsedPaymentDetails extractDetailsFrom(URL imageUrl);
    }

    @Override
    public ParsedPaymentDetails analyzePaymentImage(URL imageUrl) {
        try {
            // Create an AI Service that uses the configured model
            PaymentDetailsExtractor extractor = AiServices.create(PaymentDetailsExtractor.class, chatLanguageModel);

            // Call the AI service to perform the analysis
            return extractor.extractDetailsFrom(imageUrl);

        } catch (Exception e) {
            // Wrap any exception in our custom exception type
            throw new AIAnalysisException("Failed to analyze image with AI service.", e);
        }
    }
}
```

## 3. Refactor the Event Listener to Use the Port

Modify the `ImageAnalysisRequestListener` to use the new `AIAnalysisPort` instead of the simulation logic.

**File:** `payment-tracker-analysis/src/main/java/io/github/paymenttracker/analysis/adapter/in/event/ImageAnalysisRequestListener.java` (Refactored)

```java
package io.github.paymenttracker.analysis.adapter.in.event;

import io.github.paymenttracker.analysis.application.port.in.ImageAnalysisUseCase;
import io.github.paymenttracker.analysis.application.port.in.RecordAnalysisFailureCommand;
import io.github.paymenttracker.analysis.application.port.in.RecordAnalysisSuccessCommand;
import io.github.paymenttracker.analysis.application.port.out.AIAnalysisPort;
import io.github.paymenttracker.analysis.application.port.out.AIAnalysisException;
import io.github.paymenttracker.analysis.application.port.out.ImageAnalysisAttemptRepository;
import io.github.paymenttracker.analysis.application.port.out.PaymentImageRepository; // Assuming this port exists to get image URL
import io.github.paymenttracker.analysis.domain.event.ImageAnalysisRequestedEvent;
import io.github.paymenttracker.analysis.domain.model.AIInvocationContext;
import io.github.paymenttracker.analysis.domain.model.ImageAnalysisAttemptAgg;
import io.github.paymenttracker.analysis.domain.model.ParsedPaymentDetails;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

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

    @EventListener
    @Async
    public void onImageAnalysisRequested(ImageAnalysisRequestedEvent event) {
        log.info("Received ImageAnalysisRequestedEvent for image ID: {}. Starting REAL AI analysis.", event.paymentImageId());

        // 1. Create and start the analysis attempt
        var newAttempt = ImageAnalysisAttemptAgg.create(event.paymentImageId());
        var invocationContext = new AIInvocationContext("qwen2.5-vl-7b-instruct", "1.0", Instant.now(), null, 0); // Use model from config
        newAttempt.startAnalysis(invocationContext);
        attemptRepository.save(newAttempt);
        log.info("Created and started new ImageAnalysisAttempt with ID: {}", newAttempt.getId());

        // 2. Perform the REAL AI analysis process
        try {
            // Fetch the image URL from the repository
            var paymentImage = paymentImageRepository.findById(event.paymentImageId())
                .orElseThrow(() -> new IllegalStateException("PaymentImage not found for ID: " + event.paymentImageId()));

            // Call the AI service via the port
            ParsedPaymentDetails parsedDetails = aiAnalysisPort.analyzePaymentImage(paymentImage.getUrl());

            // Handle success
            handleSuccess(newAttempt.getId(), parsedDetails, invocationContext);

        } catch (AIAnalysisException | IllegalStateException e) {
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
            context.withEndTime(Instant.now())
        );
        imageAnalysisUseCase.handleAnalysisSuccess(command);
        log.info("Real AI analysis SUCCEEDED for attempt ID: {}", attemptId);
    }

    private void handleFailure(UUID attemptId, String errorMessage, AIInvocationContext context) {
        var command = new RecordAnalysisFailureCommand(
            attemptId,
            errorMessage,
            context.withEndTime(Instant.now())
        );
        imageAnalysisUseCase.handleAnalysisFailure(command);
        log.info("Real AI analysis FAILED for attempt ID: {}", attemptId);
    }
}
```

## 4. Configuration

The user-provided configuration should be placed in `application.yml`.

**File:** `payment-tracker-app/src/main/resources/application.yml`

```yaml
langchain4j:
  open-ai:
    chat-model:
      api-key: ${QWEN_API_KEY:sk-ef1654e65c204a89b4789cdf2cb4dd65} # Use environment variable preferably
      model-name: qwen2.5-vl-7b-instruct
      base-url: https://dashscope.aliyuncs.com/compatible-mode/v1
      log-requests: true
      log-responses: true