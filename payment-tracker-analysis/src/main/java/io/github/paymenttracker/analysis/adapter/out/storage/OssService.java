package io.github.paymenttracker.analysis.adapter.out.storage;

import com.aliyun.oss.ClientException;
import com.aliyun.oss.OSS;
import com.aliyun.oss.OSSException;
import com.aliyun.oss.model.OSSObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * @author Wei Han
 * @description
 * @date 05/07/2025 20:33
 * @domain www.weiyiyi.ltd
 */
@Service
public class OssService {

    private static final Logger logger = LoggerFactory.getLogger(OssService.class);
    private static final Pattern URL_PATTERN = Pattern.compile(".+\\.com/(.+)");

    private final OssProperties ossProperties;
    private final OSS ossClient;

    public OssService(OssProperties ossProperties, OSS ossClient) {
        this.ossProperties = ossProperties;
        this.ossClient = ossClient;
    }

    /**
     * 获取配置的存储桶名称
     *
     * @return OSS 存储桶名称
     */
    public String getBucketName() {
        return ossProperties.getBucketName();
    }

    /**
     * 获取 OSS 服务的区域
     *
     * @return OSS 区域
     */
    public String getRegion() {
        return ossProperties.getRegion();
    }

    /**
     * 获取 OSS endpoint
     *
     * @return OSS endpoint
     */
    public String getEndpoint() {
        return ossProperties.getEndpoint();
    }

    /**
     * 构建访问上传文件的 URL
     *
     * @param objectName 上传对象的名称
     * @return 访问上传对象的完整 URL
     */
    public String getObjectUrl(String objectName) {
        return String.format("https://%s.%s/%s",
                getBucketName(), getEndpoint(), objectName);
    }

    /**
     * 上传文件到 OSS
     *
     * @param inputStream 要上传的文件的输入流
     * @param objectName OSS 中对象的名称
     * @return 访问上传文件的 URL
     * @throws OssUploadException 上传失败时抛出
     */
    public String simpleUpload(InputStream inputStream, String objectName) {
        try (inputStream) {
            var putObject = ossClient.putObject(
                    ossProperties.getBucketName(),
                    objectName,
                    inputStream
            );

            if (putObject == null) {
                throw new IOException("上传失败: 返回结果为空");
            }

            return getObjectUrl(objectName);

        } catch (Exception e) {
            String errorMessage = switch (e) {
                case OSSException ossEx -> "OSS服务错误: " + ossEx.getMessage();
                case ClientException clientEx -> "OSS客户端错误: " + clientEx.getMessage();
                default -> "未知错误: " + e.getMessage();
            };

            logger.error("文件上传失败: {}", e.getMessage(), e);
            throw new OssUploadException(errorMessage, e);
        }
    }

    /**
     * 从 OSS 下载文件
     *
     * @param objectName OSS 中对象的名称
     * @return 下载的文件内容的字节数组
     * @throws OssUploadException 下载失败时抛出
     */
    public byte[] simpleDownload(String objectName) {
        String objectKey = objectName != null ? extractObjectKey(objectName) : null;

        try (OSSObject ossObject = ossClient.getObject(ossProperties.getBucketName(), objectKey);
             InputStream content = ossObject.getObjectContent()) {

            return content.readAllBytes();

        } catch (Exception e) {
            String errorMessage = switch (e) {
                case OSSException ossEx -> "OSS服务错误: " + ossEx.getMessage();
                case ClientException clientEx -> "OSS客户端错误: " + clientEx.getMessage();
                default -> "未知错误: " + e.getMessage();
            };

            logger.error("文件下载失败: {}", e.getMessage(), e);
            throw new OssUploadException(errorMessage, e);
        }
    }

    /**
     * 从完整 URL 或对象键中提取 OSS 对象键
     *
     * @param objectNameOrUrl OSS 对象键或完整 URL
     * @return 提取的对象键
     */
    private String extractObjectKey(String objectNameOrUrl) {
        // 如果不是 URL 格式，假定已经是对象键
        if (!objectNameOrUrl.startsWith("http")) {
            return objectNameOrUrl;
        }

        // 从 URL 中提取对象键
        Matcher matcher = URL_PATTERN.matcher(objectNameOrUrl);

        if (matcher.find()) {
            return matcher.group(1);
        } else {
            logger.warn("无法从 URL 中提取对象键: {}", objectNameOrUrl);
            // 如果无法提取，则使用原始值
            return objectNameOrUrl;
        }
    }
}

