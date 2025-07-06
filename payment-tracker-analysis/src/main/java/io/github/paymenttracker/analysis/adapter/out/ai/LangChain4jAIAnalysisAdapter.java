package io.github.paymenttracker.analysis.adapter.out.ai;

import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.model.input.structured.StructuredPrompt;
import dev.langchain4j.service.AiServices;
import io.github.paymenttracker.analysis.application.port.out.AIAnalysisException;
import io.github.paymenttracker.analysis.application.port.out.AIAnalysisPort;
import io.github.paymenttracker.analysis.domain.model.ParsedPaymentDetails;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.net.URL;

@Component
class LangChain4jAIAnalysisAdapter implements AIAnalysisPort {

    private final ChatLanguageModel chatLanguageModel;
    private final PaymentDetailsExtractor extractor;

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

    // Constructor for production use, creates the extractor internally
    public LangChain4jAIAnalysisAdapter(ChatLanguageModel chatLanguageModel) {
        this.chatLanguageModel = chatLanguageModel;
        this.extractor = AiServices.create(PaymentDetailsExtractor.class, chatLanguageModel);
    }

    // Constructor for testing, allows injecting a mock extractor
    LangChain4jAIAnalysisAdapter(ChatLanguageModel chatLanguageModel, PaymentDetailsExtractor extractor) {
        this.chatLanguageModel = chatLanguageModel;
        this.extractor = extractor;
    }


    @Override
    public ParsedPaymentDetails analyzePaymentImage(URL imageUrl) {
        try {
            // Call the AI service to perform the analysis
            return extractor.extractDetailsFrom(imageUrl);

        } catch (Exception e) {
            // Wrap any exception in our custom exception type
            throw new AIAnalysisException("Failed to analyze image with AI service.", e);
        }
    }
}