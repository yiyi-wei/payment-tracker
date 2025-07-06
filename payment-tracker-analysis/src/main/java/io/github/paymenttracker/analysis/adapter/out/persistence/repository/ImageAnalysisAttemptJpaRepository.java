package io.github.paymenttracker.analysis.adapter.out.persistence.repository;

import io.github.paymenttracker.analysis.adapter.out.persistence.entity.ImageAnalysisAttemptEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface ImageAnalysisAttemptJpaRepository extends JpaRepository<ImageAnalysisAttemptEntity, UUID> {
}