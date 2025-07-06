package io.github.paymenttracker.analysis.application.port.in;

import io.github.paymenttracker.analysis.domain.model.AIInvocationContext;
import io.github.paymenttracker.analysis.domain.model.ParsedPaymentDetails;

import java.util.UUID;

/**
 * Command to record a successful AI analysis result.
 */
public record RecordAnalysisSuccessCommand(
    UUID attemptId,
    String rawResult,
    ParsedPaymentDetails parsedDetails,
    AIInvocationContext context
) {
}