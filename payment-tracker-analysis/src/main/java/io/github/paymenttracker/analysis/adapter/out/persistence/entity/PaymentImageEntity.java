/*
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-03 17:39:47
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-04 11:06:38
 * @FilePath: /payment-tracker/payment-tracker-analysis/src/main/java/io/github/paymenttracker/analysis/adapter/out/persistence/entity/PaymentImageEntity.java
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
package io.github.paymenttracker.analysis.adapter.out.persistence.entity;

import io.github.paymenttracker.analysis.domain.model.PaymentImageAgg;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "payment_images")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class PaymentImageEntity {

    @Id
    private UUID id;

    @Column(nullable = false)
    private String userId;

    @Column
    private String originalFilename;

    @Column
    private String contentType;

    @Column
    private Long size;

    @Column(nullable = false, unique = true)
    private String imageHash;

    @Column(nullable = false, length = 2048)
    private String imageUrl;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PaymentImageAgg.Status status;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;
}