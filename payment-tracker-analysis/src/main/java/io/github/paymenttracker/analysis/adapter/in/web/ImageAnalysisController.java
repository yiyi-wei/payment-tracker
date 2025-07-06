/*
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-03 17:42:03
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-04 10:18:42
 * @FilePath: /payment-tracker/payment-tracker-analysis/src/main/java/io/github/paymenttracker/analysis/adapter/in/web/ImageAnalysisController.java
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
package io.github.paymenttracker.analysis.adapter.in.web;

import io.github.paymenttracker.analysis.application.port.in.ImageAnalysisUseCase;
import io.github.paymenttracker.analysis.application.port.in.UploadPaymentImageCommand;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/v1/analysis")
@RequiredArgsConstructor
public class ImageAnalysisController {

    private final ImageAnalysisUseCase imageAnalysisUseCase;

    @PostMapping(value = "/upload", consumes = "multipart/form-data")
    public ResponseEntity<UploadResponse> uploadPaymentImage(
        @RequestParam("file") MultipartFile file,
        @RequestParam("uploaderId") UUID uploaderId) {

        log.info("Received image upload request for uploader: {}", uploaderId);

        if (file.isEmpty()) {
            log.warn("Upload request for uploader {} failed: file is empty.", uploaderId);
            return ResponseEntity.badRequest().body(new UploadResponse(null, "File cannot be empty."));
        }

        try {
            var command = new UploadPaymentImageCommand(
                uploaderId,
                file.getInputStream(),
                file.getOriginalFilename(),
                file.getContentType(),
                file.getSize()
            );
            UUID paymentImageId = imageAnalysisUseCase.handleImageUpload(command);
            log.info("Successfully processed image upload for uploader: {}. Payment image ID: {}", uploaderId, paymentImageId);
            return ResponseEntity.accepted().body(new UploadResponse(paymentImageId, "Upload successful, analysis requested."));
        } catch (IOException e) {
            log.error("Failed to read file bytes for uploader: {}", uploaderId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new UploadResponse(null, "Failed to read file."));
        } catch (Exception e) {
            log.error("An unexpected error occurred during file upload for uploader: {}", uploaderId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new UploadResponse(null, "An unexpected error occurred."));
        }
    }

    public record UploadResponse(UUID paymentImageId, String message) {}
}