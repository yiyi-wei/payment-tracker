package io.github.paymenttracker.analysis.adapter.out.persistence;

import io.github.paymenttracker.analysis.adapter.out.persistence.mapper.AnalysisPersistenceMapper;
import io.github.paymenttracker.analysis.adapter.out.persistence.repository.ImageAnalysisAttemptJpaRepository;
import io.github.paymenttracker.analysis.application.port.out.ImageAnalysisAttemptRepository;
import io.github.paymenttracker.analysis.domain.model.ImageAnalysisAttemptAgg;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class ImageAnalysisAttemptPersistenceAdapter implements ImageAnalysisAttemptRepository {

    private final ImageAnalysisAttemptJpaRepository jpaRepository;
    private final AnalysisPersistenceMapper mapper;

    @Override
    public ImageAnalysisAttemptAgg save(ImageAnalysisAttemptAgg attempt) {
        var entity = mapper.toEntity(attempt);
        var savedEntity = jpaRepository.save(entity);
        return mapper.toDomain(savedEntity);
    }

    @Override
    public Optional<ImageAnalysisAttemptAgg> findById(UUID attemptId) {
        return jpaRepository.findById(attemptId).map(mapper::toDomain);
    }
}