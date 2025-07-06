package io.github.paymenttracker.analysis.adapter.out.persistence.mapper;

import io.github.paymenttracker.analysis.adapter.out.persistence.entity.ImageAnalysisAttemptEntity;
import io.github.paymenttracker.analysis.adapter.out.persistence.entity.PaymentImageEntity;
import io.github.paymenttracker.analysis.domain.model.ImageAnalysisAttemptAgg;
import io.github.paymenttracker.analysis.domain.model.PaymentImageAgg;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface AnalysisPersistenceMapper {

    PaymentImageEntity toEntity(PaymentImageAgg aggregate);

    @Mapping(target = "domainEvents", ignore = true)
    PaymentImageAgg toDomain(PaymentImageEntity entity);

    ImageAnalysisAttemptEntity toEntity(ImageAnalysisAttemptAgg aggregate);

    @Mapping(target = "domainEvents", ignore = true)
    ImageAnalysisAttemptAgg toDomain(ImageAnalysisAttemptEntity entity);
}