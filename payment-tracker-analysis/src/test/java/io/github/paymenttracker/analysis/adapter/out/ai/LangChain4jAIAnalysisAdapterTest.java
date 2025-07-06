/*
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-06 12:37:38
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-06 12:39:44
 * @FilePath: /payment-tracker/payment-tracker-analysis/src/test/java/io/github/paymenttracker/analysis/adapter/out/ai/LangChain4jAIAnalysisAdapterTest.java
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
package io.github.paymenttracker.analysis.adapter.out.ai;

import dev.langchain4j.service.AiServices;
import io.github.paymenttracker.analysis.application.port.out.AIAnalysisException;
import io.github.paymenttracker.analysis.domain.model.ParsedPaymentDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.net.MalformedURLException;
import java.net.URL;
import java.time.OffsetDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class LangChain4jAIAnalysisAdapterTest {

    @Mock
    private LangChain4jAIAnalysisAdapter.PaymentDetailsExtractor mockExtractor;

    private LangChain4jAIAnalysisAdapter adapter;

    @BeforeEach
    void setUp() {
        // This setup assumes a refactored constructor.
        // The test will fail until the adapter is refactored.
        adapter = new LangChain4jAIAnalysisAdapter(null, mockExtractor);
    }

    @Test
    void analyzePaymentImage_whenExtractionSucceeds_shouldReturnParsedDetails() throws MalformedURLException {
        // Given
        URL imageUrl = new URL("https://example.com/image.jpg");
        ParsedPaymentDetails expectedDetails = new ParsedPaymentDetails(
            new BigDecimal("123.45"), "CNY", java.time.LocalDateTime.now(), "Test Payee", "Credit Card", "Groceries"
        );
        when(mockExtractor.extractDetailsFrom(imageUrl)).thenReturn(expectedDetails);

        // When
        ParsedPaymentDetails actualDetails = adapter.analyzePaymentImage(imageUrl);

        // Then
        assertThat(actualDetails).isEqualTo(expectedDetails);
    }

    @Test
    void analyzePaymentImage_whenExtractionFails_shouldThrowAIAnalysisException() throws MalformedURLException {
        // Given
        URL imageUrl = new URL("https://example.com/image.jpg");
        RuntimeException cause = new RuntimeException("AI service failed");
        when(mockExtractor.extractDetailsFrom(imageUrl)).thenThrow(cause);

        // When & Then
        assertThatThrownBy(() -> adapter.analyzePaymentImage(imageUrl))
            .isInstanceOf(AIAnalysisException.class)
            .hasMessage("Failed to analyze image with AI service.")
            .hasCause(cause);
    }
}