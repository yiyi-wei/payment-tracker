package io.github.paymenttracker.analysis.application;

import io.github.paymenttracker.analysis.application.port.in.ImageAnalysisUseCase;
import io.github.paymenttracker.analysis.application.port.in.RecordAnalysisFailureCommand;
import io.github.paymenttracker.analysis.application.port.in.RecordAnalysisSuccessCommand;
import io.github.paymenttracker.analysis.application.port.in.UploadPaymentImageCommand;
import io.github.paymenttracker.analysis.application.port.out.DomainEventPublisher;
import io.github.paymenttracker.analysis.application.port.out.ImageAnalysisAttemptRepository;
import io.github.paymenttracker.analysis.application.port.out.PaymentImageRepository;
import io.github.paymenttracker.analysis.application.port.out.StorageService;
import io.github.paymenttracker.analysis.domain.model.PaymentImageAgg;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class ImageAnalysisApplicationService implements ImageAnalysisUseCase {

    private final PaymentImageRepository paymentImageRepository;
    private final ImageAnalysisAttemptRepository attemptRepository;
    private final StorageService storageService;
    private final DomainEventPublisher eventPublisher;

    @Override
    public UUID handleImageUpload(UploadPaymentImageCommand command) {
        try {
            byte[] imageBytes = command.inputStream().readAllBytes();
            String imageHash = calculateSHA256(imageBytes);
            var existingImage = paymentImageRepository.findByHash(imageHash);

            if(existingImage.isPresent()) {
                var image = existingImage.get();
                log.info("Duplicate image detected (hash: {}). Re-triggering analysis for image ID: {}", imageHash, image.getId());
                image.requestAnalysis();
                eventPublisher.publish(image.pullDomainEvents());
                paymentImageRepository.save(image);
                return image.getId();
            }

            String imageUrl = storageService.upload(command.originalFileName(), new ByteArrayInputStream(imageBytes));

            var newPaymentImage = PaymentImageAgg.create(command.uploaderId()
                    .toString(), command.originalFileName(), command.contentType(), command.size(), imageHash, imageUrl);

            newPaymentImage.requestAnalysis();
            paymentImageRepository.save(newPaymentImage);
            eventPublisher.publish(newPaymentImage.pullDomainEvents());
            log.info("New image saved (ID: {}). Analysis requested.", newPaymentImage.getId());

            return newPaymentImage.getId();

        } catch(IOException e) {
            log.error("Failed to handle image upload for file: {}", command.originalFileName(), e);
            throw new RuntimeException("Failed to process image upload", e);
        }
    }

    @Override
    public void handleAnalysisSuccess(RecordAnalysisSuccessCommand command) {
        var attempt = attemptRepository.findById(command.attemptId())
                .orElseThrow(() -> new IllegalStateException("Attempt not found for ID: " + command.attemptId()));

        attempt.recordSuccess(command.rawResult(), command.parsedDetails());
        attemptRepository.save(attempt);
        eventPublisher.publish(attempt.pullDomainEvents());
        log.info("Successfully recorded AI analysis result for attempt ID: {}", command.attemptId());
    }

    @Override
    public void handleAnalysisFailure(RecordAnalysisFailureCommand command) {
        var attempt = attemptRepository.findById(command.attemptId())
                .orElseThrow(() -> new IllegalStateException("Attempt not found for ID: " + command.attemptId()));

        attempt.recordFailure(command.failureReason());
        attemptRepository.save(attempt);
        eventPublisher.publish(attempt.pullDomainEvents());
        log.info("Recorded AI analysis failure for attempt ID: {}. Reason: {}", command.attemptId(), command.failureReason());
    }

    private String calculateSHA256(byte[] imageBytes) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] encodedhash = digest.digest(imageBytes);
            return bytesToHex(encodedhash);
        } catch(NoSuchAlgorithmException e) {
            throw new RuntimeException("Could not calculate SHA-256 hash", e);
        }
    }

    private static String bytesToHex(byte[] hash) {
        var hexString = new StringBuilder(2 * hash.length);
        for(byte b : hash) {
            String hex = Integer.toHexString(0xff & b);
            if(hex.length() == 1) {
                hexString.append('0');
            }
            hexString.append(hex);
        }
        return hexString.toString();
    }
}