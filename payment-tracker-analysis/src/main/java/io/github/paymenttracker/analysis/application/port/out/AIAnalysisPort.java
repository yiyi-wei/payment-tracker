package io.github.paymenttracker.analysis.application.port.out;

import io.github.paymenttracker.analysis.domain.model.ParsedPaymentDetails;
import java.net.URL;

/**
 * Interface for AI-based image analysis.
 */
public interface AIAnalysisPort {

    /**
     * Analyzes a payment image and extracts payment details.
     *
     * @param imageUrl The URL of the image to be analyzed.
     * @return ParsedPaymentDetails containing the extracted information.
     * @throws AIAnalysisException if the analysis fails for any reason.
     */
    ParsedPaymentDetails analyzePaymentImage(URL imageUrl);
}