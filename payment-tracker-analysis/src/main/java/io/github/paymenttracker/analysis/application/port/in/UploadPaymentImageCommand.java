package io.github.paymenttracker.analysis.application.port.in;

import java.io.InputStream;
import java.util.UUID;

/**
 * Command to upload a new payment image for analysis.
 */
public record UploadPaymentImageCommand(
    UUID uploaderId,
    InputStream inputStream,
    String originalFileName,
    String contentType,
    long size
) {
}