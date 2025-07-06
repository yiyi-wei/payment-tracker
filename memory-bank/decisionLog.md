<!--
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-02 16:05:32
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-06 12:48:28
 * @FilePath: /payment-tracker/memory-bank/decisionLog.md
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
-->
# Decision Log

This file records architectural and implementation decisions using a list format.
2025-07-02 16:05:23 - Log of updates made.

*

---
### Decision
[2025-07-02 16:05:23] - 确定项目核心架构与技术选型

**Rationale:**
为了应对Pay-Tracker项目的复杂性、可扩展性和长期维护性，我们选择了经过行业验证的、成熟且强大的架构模式和技术栈。
*   **DDD (Domain-Driven Design)**: 使我们能够将复杂的业务逻辑分解为独立的、高内聚的限界上下文（Bounded Contexts），让代码模型与业务领域保持一致。
*   **六边形架构 (Hexagonal Architecture)**: 通过将核心业务逻辑与外部依赖（如UI、数据库、消息队列）解耦，实现了高度的可测试性和灵活性。应用的核心不受外部技术选择的影响。
*   **CQRS (Command Query Responsibility Segregation)**: 将命令（写操作）和查询（读操作）分离，可以针对性地优化读写两端，提高系统性能和可伸缩性。
*   **事件驱动 (Event-Driven)**: 模块间的通信通过异步事件（使用RocketMQ）进行，降低了模块间的耦合度，增强了系统的弹性和响应能力，特别是对于AI分析这种长时任务。
*   **技术栈**: Java 21, Spring Boot, Spring Data JPA, PostgreSQL, RocketMQ, LangChain4j 提供了强大的生态支持、高性能和AI集成能力。

**Implementation Details:**
*   项目将划分为多个Maven模块，每个模块对应一个限界上下文或共享内核。
*   模块间通信将通过`payment-tracker-shared-kernel`中定义的事件，并由RocketMQ进行传递。
*   `payment-tracker-app`模块负责应用的最终装配和启动。
- **Timestamp:** 2025-07-05 13:31:12
- **Decision:** Switched from `roo mcp exec` to a direct `docker run` command.
- **Reason:** The `roo` command was not found in the environment's PATH (`zsh: command not found: roo`). The direct Docker command, derived from `mcp_settings.json`, provides an equivalent alternative to execute the SQL script against the MCP server.
- **Timestamp:** 2025-07-05 13:35:08
- **Decision:** Stopped all running `crystaldba/postgres-mcp` containers.
- **Reason:** The presence of multiple running containers was suspected to cause resource contention, preventing the database initialization script from completing. A clean environment is required for a reliable execution attempt.- **[2025-07-05 14:00:15]** - `[DevOps]` - **Decision**: Used the `postgres` MCP to directly execute the SQL script for initializing the 'AI Analysis' bounded context schema. **Reason**: This is the standard and most direct method for database schema deployment in this project. **Outcome**: Schema created successfully.
---
### Decision
[2025-07-06 12:22:36] - 选定AI模型并设计集成方案

**Rationale:**
为了将项目中的模拟AI分析替换为真实的AI服务调用，需要选择一个具体的AI模型并设计相应的技术实现方案。根据用户提供的配置，我们确定了最适合当前需求的模型和服务。

*   **AI模型选型**: 选用阿里云达摩院的 `qwen2.5-vl-7b-instruct` 模型。这是一个强大的视觉语言模型，非常适合处理包含图像和文本的支付凭证分析任务。
*   **集成技术**: 采用 `LangChain4j` 框架。它为Java提供了与大语言模型交互的标准化、高级别的API，能够简化与AI服务的集成代码，并且通过简单的配置即可切换不同的模型，符合我们六边形架构中“可替换组件”的理念。
*   **架构设计**:
    *   定义了一个出站端口 `AIAnalysisPort`，用于解耦应用核心与外部AI服务。
    *   创建了一个出站适配器 `LangChain4jAIAnalysisAdapter`，负责使用 `LangChain4j` 调用AI服务的具体实现。
    *   这种设计遵循了六边形架构，确保了系统的灵活性和可测试性。

**Implementation Details:**
*   AI服务的配置信息（API Key, model name, base URL）将存储在 `application.yml` 中，并通过环境变量进行管理，以确保安全性。
*   具体的实现伪代码已保存在 `doc/technical/ai_analysis_real_service_pseudocode.md` 中。


---
### Decision
[2025-07-06 12:27:13] - 正式确定并记录AI服务集成的系统架构

**Rationale:**
在完成了集成真实AI服务（阿里云通义千问）的伪代码设计后，需要将此设计正式体现在项目的核心架构文档中，以确保所有团队成员对设计有统一的理解，并为后续的开发工作提供清晰的指引。本次更新旨在将抽象的伪代码转化为具体的、可视化的架构蓝图。

**Implementation Details:**
*   **更新架构图**: 在 `doc/domain-puml/ai_analysis_context.puml` 中，新增了一个基于六边形架构的组件图。该图清晰地展示了新引入的出站端口 `AIAnalysisPort`、出站适配器 `LangChain4jAIAnalysisAdapter`，以及它们与应用核心、外部AI服务之间的交互关系。
*   **更新技术文档**: 在 `doc/technical/technical.md` 中，新增了“AI服务集成架构”章节。该章节详细阐述了设计原则、核心组件职责、数据流，并嵌入了新的架构图和相关配置，为开发者提供了完整的实现上下文。
*   **遵循既定模式**: 本次设计严格遵循了项目既有的DDD和六边形架构原则，保证了系统的解耦性、可测试性和可扩展性。

---
**Decision Date:** 2025-07-06 12:48
**Author:** 🛡️ 安全审查员
**Context:** Performed a security review of the AI service integration, focusing on `LangChain4jAIAnalysisAdapter.java`, `ImageAnalysisRequestListener.java`, and configuration files.

**Decision/Action Taken:**
1.  **Identified Critical Vulnerability:** Hardcoded credentials (Database password, Aliyun OSS keys) and insecure API key handling (OpenAI key with a default fallback) were found in `application.yml`.
2.  **Mitigation:** Modified `application.yml` to remove all hardcoded secrets. All sensitive values (`DB_PASSWORD`, `OPENAI_API_KEY`, `ALIYUN_OSS_ACCESS_KEY`, `ALIYUN_OSS_SECRET_KEY`) are now loaded exclusively from environment variables. This prevents secret leakage through the codebase.

**Rationale:**
Hardcoding credentials is a severe security risk, exposing the application and its data to unauthorized access if the configuration file is compromised. Moving to an environment variable-based approach is a standard security best practice that decouples secrets from the source code.

**Impact:**
- **Positive:** Significantly improved the security posture of the application.
- **Action Required:** The deployment process must now ensure that all required environment variables are securely set in the production environment. A review of the git history is recommended to ensure no secrets were ever committed.
