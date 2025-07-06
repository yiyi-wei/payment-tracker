/*
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-03 17:38:26
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-05 21:03:36
 * @FilePath: /payment-tracker/payment-tracker-analysis/src/main/java/io/github/paymenttracker/analysis/application/port/out/StorageService.java
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
package io.github.paymenttracker.analysis.application.port.out;

import java.io.IOException;
import java.io.InputStream;

/**
 * Interface for interacting with a blob storage service (e.g., AWS S3, Aliyun OSS).
 */
public interface StorageService {

    /**
     * Uploads a file from an InputStream to the storage.
     *
     * @param originalFilename The original name of the file being uploaded. This is used to determine the file extension.
     * @param inputStream      The InputStream containing the file data. The stream will be closed by the implementation.
     * @return The public URL of the uploaded file.
     * @throws IOException If an I/O error occurs during the upload process.
     */
    String upload(String originalFilename, InputStream inputStream) throws IOException;
}