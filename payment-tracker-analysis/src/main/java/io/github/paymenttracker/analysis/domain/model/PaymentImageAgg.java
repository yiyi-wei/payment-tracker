/*
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-03 17:36:22
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-06 12:41:12
 * @FilePath: /payment-tracker/payment-tracker-analysis/src/main/java/io/github/paymenttracker/analysis/domain/model/PaymentImageAgg.java
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
package io.github.paymenttracker.analysis.domain.model;

import io.github.paymenttracker.analysis.domain.common.BaseAggregateRoot;
import io.github.paymenttracker.analysis.domain.event.ImageAnalysisRequestedEvent;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

import java.time.Instant;
import java.util.UUID;

@Getter
@SuperBuilder
@NoArgsConstructor
public class PaymentImageAgg extends BaseAggregateRoot<UUID> {

    private String userId;
    private String originalFilename;
    private String contentType;
    private Long size;
    private String imageHash;
    private String imageUrl;
    private Status status;
    private Instant createdAt;

    public enum Status {
        UPLOADED, ANALYSIS_PENDING, ANALYSIS_COMPLETED, ANALYSIS_FAILED
    }

    private PaymentImageAgg(UUID id, String userId, String originalFilename, String contentType, Long size, String imageHash, String imageUrl) {
        super(id);
        this.userId = userId;
        this.originalFilename = originalFilename;
        this.contentType = contentType;
        this.size = size;
        this.imageHash = imageHash;
        this.imageUrl = imageUrl;
        this.status = Status.UPLOADED;
        this.createdAt = Instant.now();
    }

    public static PaymentImageAgg create(String userId, String originalFilename, String contentType, Long size, String imageHash, String imageUrl) {
        return new PaymentImageAgg(UUID.randomUUID(), userId, originalFilename, contentType, size, imageHash, imageUrl);
    }

    public void requestAnalysis() {
        if (this.status == Status.UPLOADED || this.status == Status.ANALYSIS_FAILED) {
            this.status = Status.ANALYSIS_PENDING;
            registerEvent(new ImageAnalysisRequestedEvent(this.getId(), this.imageUrl));
        }
    }
}