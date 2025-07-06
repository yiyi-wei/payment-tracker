# Payment Tracker

Payment Tracker 是一个功能强大的跨平台支付记录跟踪工具，旨在帮助用户轻松管理、监控和分析他们的财务支出。项目利用现代化的架构（DDD、六边形架构、CQRS）和技术栈（Java 21, Spring Boot, AI集成），提供安全、可靠且智能的支付管理体验。

## 核心功能

*   **多平台支持**: 设计支持 Web、iOS 和 Android，随时随地访问您的数据。
*   **智能记录**: 通过图片上传，利用 AI 技术自动解析和录入支付凭证。
*   **全面追踪**: 支持自动同步和手动添加多种支付方式的记录。
*   **深度分析**: 提供消费趋势、支出分类和支付方式等多维度的数据分析图表。
*   **安全保障**: 所有敏感数据均经过加密处理，并支持二次验证，确保您的财务信息安全无虞。

## 技术栈

*   **后端**: Java 21, Spring Boot 3, Spring Data JPA
*   **数据库**: PostgreSQL
*   **消息队列**: Apache RocketMQ
*   **AI 集成**: LangChain4j (当前集成阿里云通义千问 `qwen2.5-vl-7b-instruct` 模型)
*   **架构**: DDD, 六边形架构, CQRS, 事件驱动

## 安装与启动

1.  **克隆仓库**:
    ```bash
    git clone [your-repository-url]
    cd payment-tracker
    ```

2.  **配置环境变量**:
    在运行应用前，请务必设置以下环境变量。这是保障数据库、云存储和AI服务安全的关键步骤。

3.  **构建并运行项目**:
    ```bash
    ./mvnw spring-boot:run
    ```
    应用将在 `http://localhost:8080` 启动。

---

## 配置与运行

为了确保应用的正常运行和安全性，所有敏感配置都必须通过环境变量进行设置。请勿将任何密钥或密码硬编码在代码或配置文件中。

以下是必须设置的环境变量列表：

| 环境变量                  | 描述                                               | 示例值                               |
| ------------------------- | -------------------------------------------------- | ------------------------------------ |
| `DB_PASSWORD`             | 连接到 PostgreSQL 数据库所需的密码。               | `your_strong_database_password`      |
| `ALIYUN_OSS_ACCESS_KEY`   | 阿里云对象存储 (OSS) 的 Access Key ID。            | `your_aliyun_oss_access_key`         |
| `ALIYUN_OSS_SECRET_KEY`   | 阿里云对象存储 (OSS) 的 Access Key Secret。        | `your_aliyun_oss_secret_key`         |
| `OPENAI_API_KEY`          | AI 服务（例如 OpenAI 或兼容的 API）的 API Key。    | `your_ai_service_api_key`            |
| `ROCKETMQ_NAME_SERVER`    | RocketMQ Name Server 的地址。 (可选, 默认为 `localhost:9876`) | `your_rocketmq_server:9876`          |

**如何设置环境变量:**

*   **Linux / macOS**:
    ```bash
    export DB_PASSWORD="your_strong_database_password"
    export ALIYUN_OSS_ACCESS_KEY="your_aliyun_oss_access_key"
    # ... 其他变量
    ```

*   **Windows (Command Prompt)**:
    ```cmd
    set DB_PASSWORD="your_strong_database_password"
    set ALIYUN_OSS_ACCESS_KEY="your_aliyun_oss_access_key"
    # ... 其他变量
    ```

*   **Docker Compose**:
    在 `docker-compose.yml` 文件中，您可以为服务添加 `environment` 部分：
    ```yaml
    services:
      your-app-service:
        image: your-app-image
        environment:
          - DB_PASSWORD=your_strong_database_password
          - ALIYUN_OSS_ACCESS_KEY=your_aliyun_oss_access_key
          - ALIYUN_OSS_SECRET_KEY=your_aliyun_oss_secret_key
          - OPENAI_API_KEY=your_ai_service_api_key