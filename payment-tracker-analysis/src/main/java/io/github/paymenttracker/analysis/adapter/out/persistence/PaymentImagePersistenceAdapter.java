package io.github.paymenttracker.analysis.adapter.out.persistence;

import io.github.paymenttracker.analysis.adapter.out.persistence.mapper.AnalysisPersistenceMapper;
import io.github.paymenttracker.analysis.adapter.out.persistence.repository.PaymentImageJpaRepository;
import io.github.paymenttracker.analysis.application.port.out.PaymentImageRepository;
import io.github.paymenttracker.analysis.domain.model.PaymentImageAgg;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class PaymentImagePersistenceAdapter implements PaymentImageRepository {

    private final PaymentImageJpaRepository jpaRepository;
    private final AnalysisPersistenceMapper mapper;

    @Override
    public Optional<PaymentImageAgg> findByHash(String imageHash) {
        return jpaRepository.findByImageHash(imageHash).map(mapper::toDomain);
    }

    @Override
    public PaymentImageAgg save(PaymentImageAgg paymentImage) {
        var entity = mapper.toEntity(paymentImage);
        var savedEntity = jpaRepository.save(entity);
        return mapper.toDomain(savedEntity);
    }

    @Override
    public Optional<PaymentImageAgg> findById(UUID paymentImageId) {
        return jpaRepository.findById(paymentImageId).map(mapper::toDomain);
    }
}