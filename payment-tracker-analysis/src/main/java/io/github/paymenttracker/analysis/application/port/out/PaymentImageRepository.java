package io.github.paymenttracker.analysis.application.port.out;

import io.github.paymenttracker.analysis.domain.model.PaymentImageAgg;
import java.util.Optional;
import java.util.UUID;

public interface PaymentImageRepository {
    Optional<PaymentImageAgg> findByHash(String imageHash);
    PaymentImageAgg save(PaymentImageAgg paymentImage);
    Optional<PaymentImageAgg> findById(UUID paymentImageId);
}