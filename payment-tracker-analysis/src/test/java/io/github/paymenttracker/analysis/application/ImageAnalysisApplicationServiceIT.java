/*
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-03 21:59:26
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-05 21:07:01
 * @FilePath: /payment-tracker/payment-tracker-analysis/src/test/java/io/github/paymenttracker/analysis/application/ImageAnalysisApplicationServiceIT.java
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
package io.github.paymenttracker.analysis.application;

import io.github.paymenttracker.analysis.application.port.in.UploadPaymentImageCommand;
import io.github.paymenttracker.analysis.application.port.out.PaymentImageRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import io.github.paymenttracker.analysis.domain.model.PaymentImageAgg;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.NONE)
@DisplayName("ImageAnalysisApplicationService 集成测试")
class ImageAnalysisApplicationServiceIT {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "create");
    }

    @Autowired
    private ImageAnalysisApplicationService imageAnalysisService;

    @Autowired
    private PaymentImageRepository paymentImageRepository;

    @Test
    @DisplayName("当上传新图片时，应成功将图片信息持久化到数据库")
    void should_persist_image_information_when_uploading_new_image() throws IOException {
        // Given
        var uploaderId = UUID.randomUUID();
        var imageBytes = "test-image-data".getBytes();
        var command = new UploadPaymentImageCommand(
            uploaderId,
            new ByteArrayInputStream(imageBytes),
            "test-integration.jpg",
            "image/jpeg",
            imageBytes.length
        );

        // When
        UUID paymentImageId = imageAnalysisService.handleImageUpload(command);

        // Then
        assertThat(paymentImageId).isNotNull();
        var savedImageOpt = paymentImageRepository.findById(paymentImageId);
        assertThat(savedImageOpt).isPresent();
        var savedImage = savedImageOpt.get();
        assertThat(savedImage.getUserId()).isEqualTo(uploaderId.toString());
        assertThat(savedImage.getOriginalFilename()).isEqualTo("test-integration.jpg");
        assertThat(savedImage.getStatus()).isEqualTo(PaymentImageAgg.Status.ANALYSIS_PENDING);
    }
}