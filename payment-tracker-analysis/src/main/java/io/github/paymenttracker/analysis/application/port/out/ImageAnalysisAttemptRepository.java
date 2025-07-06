package io.github.paymenttracker.analysis.application.port.out;

import io.github.paymenttracker.analysis.domain.model.ImageAnalysisAttemptAgg;
import java.util.Optional;
import java.util.UUID;

public interface ImageAnalysisAttemptRepository {
    ImageAnalysisAttemptAgg save(ImageAnalysisAttemptAgg attempt);
    Optional<ImageAnalysisAttemptAgg> findById(UUID attemptId);
}