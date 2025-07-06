package io.github.paymenttracker.analysis.application.port.in;

import java.util.UUID;

public interface ImageAnalysisUseCase {

    UUID handleImageUpload(UploadPaymentImageCommand command);

    void handleAnalysisSuccess(RecordAnalysisSuccessCommand command);

    void handleAnalysisFailure(RecordAnalysisFailureCommand command);

}