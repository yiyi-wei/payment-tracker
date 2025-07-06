package io.github.paymenttracker.analysis.adapter.out.storage;

/**
 * @author Wei Han
 * @description
 * @date 05/07/2025 20:34
 * @domain www.weiyiyi.ltd
 */
public class OssUploadException extends RuntimeException {

    public OssUploadException(String message) {
        super(message);
    }

    public OssUploadException(String message, Throwable cause) {
        super(message, cause);
    }
}

