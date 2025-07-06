package io.github.paymenttracker.analysis.adapter.out.storage;

import com.aliyun.oss.OSS;
import com.aliyun.oss.OSSClientBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * @author Wei Han
 * @description
 * @date 05/07/2025 20:32
 * @domain www.weiyiyi.ltd
 */
@Configuration
public class OssConfig {

    private final OssProperties ossProperties;
    public OssConfig(OssProperties ossProperties) {
        this.ossProperties = ossProperties;
    }
    /**
     * 创建并配置 OSS 客户端
     *
     * @return 配置好的 OSS 客户端
     */
    @Bean
    public OSS ossClient() {
        return new OSSClientBuilder().build(
                ossProperties.getEndpoint(),
                ossProperties.getAccessKey(),
                ossProperties.getSecretKey()
        );
    }
}
