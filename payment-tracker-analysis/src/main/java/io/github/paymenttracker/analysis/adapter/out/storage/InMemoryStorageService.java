/*
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-03 17:39:10
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-05 21:01:20
 * @FilePath: /payment-tracker/payment-tracker-analysis/src/main/java/io/github/paymenttracker/analysis/adapter/out/storage/InMemoryStorageService.java
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
package io.github.paymenttracker.analysis.adapter.out.storage;

import io.github.paymenttracker.analysis.application.port.out.StorageService;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.io.FilenameUtils;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

@Slf4j
@Component
public class InMemoryStorageService implements StorageService {

    @Resource
    private OssService ossService;

    @Override
    public String upload(String originalFilename, InputStream inputStream) throws IOException {
        log.info("[STORAGE-SERVICE] Uploading, original filename: {}", originalFilename);

        try (inputStream) {
            String extension = FilenameUtils.getExtension(originalFilename);
            if (extension == null || extension.isBlank()) {
                // Fallback to a default extension if none is found
                extension = "jpeg";
            }

            // Generate a unique object name to prevent overwrites and organize files
            String datePath = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy/MM/dd"));
            String uniqueFileName = UUID.randomUUID() + "." + extension;
            String objectName = datePath + "/" + uniqueFileName;

            log.info("[STORAGE-SERVICE] Generated object name: {}", objectName);

            // Perform the upload
            //return ossService.simpleUpload(inputStream, objectName);
            return "https://pay-tracker-alpha.oss-cn-beijing.aliyuncs" +
                    ".com/2025/07/05/146a7f1d-c51d-4a92-b7be-072bf16517e0" +
                    ".jpg?Expires=1751774901&OSSAccessKeyId=TMP.3KntSNrkb31EbaeAgS4PVafnAV61jbg1BABdoeK6xAYa12YGKvQDcLfqTAkzvvqtQcyzjBxS3LfiyYtwajDCXgVN5Z1HK2&Signature=93Lih2SnGS7te%2B%2B4clHpTgc8pHw%3D";
        } catch (Exception e) {
            log.error("[STORAGE-SERVICE] Failed to upload file {}", originalFilename, e);
            // Re-throw a more specific exception or a custom one
            throw new IOException("Failed to upload file to storage", e);
        }
    }
}