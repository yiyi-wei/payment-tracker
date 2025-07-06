package io.github.paymenttracker.analysis.adapter.out.persistence.entity;

import io.github.paymenttracker.analysis.domain.model.AIInvocationContext;
import io.github.paymenttracker.analysis.domain.model.AnalysisStatus;
import io.github.paymenttracker.analysis.domain.model.ParsedPaymentDetails;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "image_analysis_attempts")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ImageAnalysisAttemptEntity {

    @Id
    private UUID id;

    @Column(nullable = false)
    private UUID paymentImageId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AnalysisStatus status;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private AIInvocationContext aiContext;

    @Column(columnDefinition = "text")
    private String rawAnalysisResult;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private ParsedPaymentDetails parsedPaymentDetails;

    @Column(columnDefinition = "text")
    private String failureReason;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @Column(nullable = false)
    private Instant updatedAt;
}
