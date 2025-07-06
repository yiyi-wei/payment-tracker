package io.github.paymenttracker.analysis.adapter.out.persistence.repository;

import io.github.paymenttracker.analysis.adapter.out.persistence.entity.PaymentImageEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface PaymentImageJpaRepository extends JpaRepository<PaymentImageEntity, UUID> {

    Optional<PaymentImageEntity> findByImageHash(String imageHash);
}