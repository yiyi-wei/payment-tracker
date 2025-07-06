# Technical Documentation

## Database Design

### JSONB Fields in Users Table

#### payment_methods_config

用户支付方式配置，使用JSONB存储以提供灵活的配置管理。

**结构说明：**

- default_method: 默认支付方式ID
- methods: 支付方式配置集合
  - type: 支付方式类型（ALIPAY/WECHAT/BANK_CARD等）
  - name: 支付方式名称
  - account: 关联账号
  - is_default: 是否默认支付方式
  - auto_sync: 是否自动同步
  - sync_frequency: 同步频率
  - last_sync_at: 最后同步时间
  - merchant_filters: 商户过滤规则
  - amount_limits: 金额限制

**优势：**

1. 灵活配置：无需修改表结构即可添加新的支付方式属性
2. 查询效率：JSONB支持索引，可快速检索特定配置
3. 版本管理：便于进行配置版本控制
4. 减少关联查询：将相关配置集中存储，减少表连接

#### reminder_settings_config

用户提醒设置配置，使用JSONB存储以支持多样化的提醒规则。

**结构说明：**

- default_reminder: 默认提醒配置ID
- reminders: 提醒配置集合
  - type: 提醒类型（BUDGET/RECURRING等）
  - name: 提醒名称
  - enabled: 是否启用
  - frequency: 提醒频率
  - notification_channels: 通知渠道配置
  - conditions: 触发条件

**优势：**

1. 多样化规则：支持复杂的提醒规则配置
2. 通知渠道整合：统一管理多个通知渠道
3. 条件触发：支持灵活的触发条件配置
4. 配置继承：支持默认配置和个性化配置

### 使用建议

1. **查询优化**

```sql
CREATE TABLE reminder_settings
(
    id                SERIAL PRIMARY KEY,
    user_id           VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    type              VARCHAR(50)  NOT NULL,
    frequency         VARCHAR(50),
    cron_expression   VARCHAR(100),
    next_trigger_at   TIMESTAMPTZ,
    related_record_id INT,
    is_active         BOOLEAN     DEFAULT TRUE,
    created_at        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    -- 新增：通知渠道配置
    notification_channels JSONB,
    -- 新增：提醒优先级
    priority VARCHAR(20) DEFAULT 'normal'
);
COMMENT ON TABLE reminder_settings IS '提醒设置表，用户聚合的一部分';
COMMENT ON COLUMN reminder_settings.id IS '自增主键';
COMMENT ON COLUMN reminder_settings.user_id IS '业务生成的用户唯一标识';
COMMENT ON COLUMN reminder_settings.type IS '提醒类型（如周期性提醒）';
COMMENT ON COLUMN reminder_settings.frequency IS '提醒频率（如每日）';
COMMENT ON COLUMN reminder_settings.cron_expression IS '定时任务表达式';
COMMENT ON COLUMN reminder_settings.next_trigger_at IS '下次触发时间';
COMMENT ON COLUMN reminder_settings.is_active IS '提醒设置是否有效';
COMMENT ON COLUMN reminder_settings.created_at IS '提醒设置创建时间';
COMMENT ON COLUMN reminder_settings.updated_at IS '最后更新时间';
COMMENT ON COLUMN reminder_settings.notification_channels IS '通知渠道配置';
COMMENT ON COLUMN reminder_settings.priority IS '提醒优先级';
```

这个表的中：notification_channels字段的设计思路：
这个字段用于存储用户的多渠道通知配置，允许用户为不同的提醒设置多种通知方式。

```json
{
  "email": {
    "enabled": true,
    "address": "user@example.com",
    "template": "default_email"
  },
  "sms": {
    "enabled": true,
    "phoneNumber": "+8613800138000",
    "template": "default_sms"
  },
  "push": {
    "enabled": true,
    "deviceTokens": ["token1", "token2"],
    "sound": "default"
  },
  "wechat": {
    "enabled": true,
    "openId": "wx_openid_123",
    "template": "payment_reminder"
  }
}
```

payment_methods_config 设计思路

```json
{
  "default_method": "alipay_001",
  "methods": {
    "alipay_001": {
      "type": "ALIPAY",
      "name": "我的支付宝",
      "account": "13800138000",
      "is_default": true,
      "auto_sync": true,
      "sync_frequency": "DAILY",
      "last_sync_at": "2024-03-20T10:00:00Z",
      "merchant_filters": ["淘宝", "天猫"],
      "amount_limits": {
        "min": 0.01,
        "max": 50000
      }
    },
    "wechat_001": {
      "type": "WECHAT",
      "name": "微信支付",
      "account": "wx_openid_123",
      "is_default": false,
      "auto_sync": true,
      "sync_frequency": "REALTIME",
      "last_sync_at": "2024-03-20T10:00:00Z"
    }
  }
}
```

reminder_settings_config 设计思路：

```json
{
  {
  "default_reminder": "monthly_budget",
  "reminders": {
    "monthly_budget": {
      "type": "BUDGET",
      "name": "月度预算提醒",
      "enabled": true,
      "threshold": 5000.00,
      "frequency": "MONTHLY",
      "notification_channels": {
        "email": {
          "enabled": true,
          "template": "budget_alert"
        },
        "sms": {
          "enabled": false
        }
      },
      "conditions": {
        "categories": ["food", "entertainment"],
        "exclude_methods": ["company_card"]
      }
    },
    "subscription_payment": {
      "type": "RECURRING",
      "name": "订阅付款提醒",
      "enabled": true,
      "frequency": "MONTHLY",
      "day_of_month": 15,
      "notification_channels": {
        "email": {
          "enabled": true,
          "advance_days": 3
        }
      }
    }
  }
}
```

```pgsql
CREATE TABLE users
(
id              SERIAL PRIMARY KEY,
user_id         VARCHAR(255) UNIQUE NOT NULL,
email           VARCHAR(255) UNIQUE NOT NULL,
phone           VARCHAR(20) UNIQUE,
password_hash   VARCHAR(255)        NOT NULL,
encryption_key  BYTEA,
two_factor_auth BOOLEAN     DEFAULT FALSE,
created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
-- 新增：支付方式集合和提醒设置集合的引用
payment_methods_config JSONB,
reminder_settings_config JSONB,
-- 新增：安全相关字段
security_settings JSONB,
last_login_at   TIMESTAMPTZ
);
```

```pgsql
-- 创建分类体系表
CREATE TABLE categories
(
    id         SERIAL PRIMARY KEY,
    user_id    VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    name       VARCHAR(50)  NOT NULL,
    parent_id  INT REFERENCES categories (id),
    is_system  BOOLEAN     DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    -- 新增：支持分类图标和颜色，提高用户体验
    icon       VARCHAR(50),
    color      VARCHAR(20),
    -- 新增：分类规则
    category_rules JSONB,
    -- 新增：分类描述
    description TEXT,
    -- 新增：显示顺序
    display_order INT DEFAULT 0,
    -- 新增：预算限额
    budget_limit DECIMAL(10, 2)
);
COMMENT ON TABLE categories IS '支付分类聚合根表';
COMMENT ON COLUMN categories.id IS '自增主键';
COMMENT ON COLUMN categories.user_id IS '业务生成的用户唯一标识';
COMMENT ON COLUMN categories.name IS '分类名称';
COMMENT ON COLUMN categories.parent_id IS '父分类ID';
COMMENT ON COLUMN categories.is_system IS '是否为系统预置分类';
COMMENT ON COLUMN categories.updated_at IS '最后更新时间';
COMMENT ON COLUMN categories.icon IS '分类图标';
COMMENT ON COLUMN categories.color IS '分类显示颜色';
COMMENT ON COLUMN categories.category_rules IS '分类规则';
COMMENT ON COLUMN categories.description IS '分类描述';
COMMENT ON COLUMN categories.display_order IS '显示顺序';
COMMENT ON COLUMN categories.budget_limit IS '预算限额';
```

category_rules 设计方案

```json
{
  "matching_rules": {
    "keywords": {
      "include": ["餐饮", "美食", "饭店"],
      "exclude": ["外卖配送费"]
    },
    "merchants": {
      "include": ["肯德基", "麦当劳"],
      "exclude": ["美团优选"]
    },
    "amount_range": {
      "min": 10.00,
      "max": 1000.00
    }
  },
  "auto_categorize": {
    "enabled": true,
    "confidence_threshold": 0.8
  },
  "sub_categories_rules": {
    "fast_food": {
      "keywords": ["快餐", "外卖"],
      "merchants": ["麦当劳", "肯德基"],
      "amount_range": {
        "max": 100.00
      }
    },
    "fine_dining": {
      "keywords": ["餐厅", "酒店"],
      "amount_range": {
        "min": 100.00
      }
    }
  },
  "ai_learning": {
    "enabled": true,
    "learning_threshold": 10,
    "last_trained_at": "2024-03-20T10:00:00Z"
  }
}
```

PaymentImageAgg

```pgsql
-- 创建支付凭证图像表 (PaymentImageAgg)
CREATE TABLE payment_images
(
    id              SERIAL PRIMARY KEY,
    user_id         VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    image_file      TEXT         NOT NULL,
    upload_time     TIMESTAMPTZ  NOT NULL,
    analysis_result JSONB,
    status          VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'success', 'failed')),
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    -- 新增：记录上传平台信息
    platform        VARCHAR(50),
    -- 新增：图像处理元数据
    metadata        JSONB,
    -- 新增：OCR识别结果
    ocr_result      JSONB,
    -- 新增：图像分类结果
    classification_result JSONB
);
```

metadata:

作用：存储图像的技术元数据信息

```json
{
  "image_info": {
    "width": 1080,
    "height": 1920,
    "format": "JPEG",
    "size_bytes": 1024000,
    "dpi": 300
  },
  "device_info": {
    "model": "iPhone 14 Pro",
    "os_version": "iOS 17.2",
    "app_version": "1.2.0"
  },
  "location": {
    "latitude": 31.2304,
    "longitude": 121.4737,
    "timestamp": "2024-03-20T10:00:00Z"
  },
  "processing": {
    "compression_ratio": 0.8,
    "preprocessing_steps": ["resize", "enhance"]
  }
}
```

classification_result

作用：存储OCR文字识别的详细结果

```json
{
  "payment_type": {
    "category": "ALIPAY",
    "confidence": 0.95
  },
  "merchant_category": {
    "primary": "餐饮",
    "secondary": "快餐",
    "confidence": 0.88
  },
  "transaction_type": {
    "category": "消费",
    "confidence": 0.97
  },
  "suggested_categories": [
    {
      "id": "food_delivery",
      "name": "外卖配送",
      "confidence": 0.92
    },
    {
      "id": "restaurant",
      "name": "餐厅",
      "confidence": 0.85
    }
  ],
  "analysis_timestamp": "2024-03-20T10:00:00Z"
}
```

PlatformSyncAgg

```pgsql
-- 创建支付平台同步任务表 (PlatformSyncAgg)
CREATE TABLE payment_sync_tasks
(
    id                SERIAL PRIMARY KEY,
    user_id           VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    platform          VARCHAR(50)  NOT NULL,
    auth_token        TEXT         NOT NULL,
    last_sync_at      TIMESTAMPTZ,
    next_sync_at      TIMESTAMPTZ,
    sync_frequency    VARCHAR(50),
    is_active         BOOLEAN     DEFAULT TRUE,
    created_at        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    -- 新增：同步配置参数
    sync_config       JSONB,
    -- 新增：错误计数
    error_count       INT         DEFAULT 0,
    -- 新增：最后错误信息
    last_error        TEXT,
    -- 新增：同步范围配置
    sync_scope        JSONB,
    -- 新增：同步优先级
    priority          VARCHAR(20) DEFAULT 'normal',
    -- 新增：重试策略
    retry_strategy    JSONB
);
COMMENT ON TABLE payment_sync_tasks IS '平台同步聚合根表';
COMMENT ON COLUMN payment_sync_tasks.platform IS '支付平台类型: 支付宝/微信等';
COMMENT ON COLUMN payment_sync_tasks.auth_token IS '平台授权令牌';
COMMENT ON COLUMN payment_sync_tasks.last_sync_at IS '上次同步时间';
COMMENT ON COLUMN payment_sync_tasks.next_sync_at IS '下次同步时间';
COMMENT ON COLUMN payment_sync_tasks.sync_frequency IS '同步频率';
COMMENT ON COLUMN payment_sync_tasks.is_active IS '同步任务是否有效';
COMMENT ON COLUMN payment_sync_tasks.created_at IS '创建时间';
COMMENT ON COLUMN payment_sync_tasks.updated_at IS '最后更新时间';
COMMENT ON COLUMN payment_sync_tasks.sync_config IS '同步配置参数，JSON格式';
COMMENT ON COLUMN payment_sync_tasks.error_count IS '同步错误次数';
COMMENT ON COLUMN payment_sync_tasks.last_error IS '最后一次同步错误信息';
COMMENT ON COLUMN payment_sync_tasks.sync_scope IS '同步范围配置';
COMMENT ON COLUMN payment_sync_tasks.priority IS '同步优先级';
COMMENT ON COLUMN payment_sync_tasks.retry_strategy IS '重试策略';

```

sync_config

作用：存储同步任务的详细配置参数

```json
{
  "sync_mode": "INCREMENTAL",  // 增量同步或全量同步
  "batch_size": 100,           // 每批次处理数量
  "timeout_seconds": 300,      // 超时时间
  "filters": {
    "min_amount": 1.00,
    "max_amount": 50000.00,
    "exclude_types": ["退款", "红包"]
  },
  "notification": {
    "success": true,           // 是否通知同步成功
    "failure": true,           // 是否通知同步失败
    "channels": ["email"]      // 通知渠道
  },
  "data_mapping": {            // 数据字段映射配置
    "merchant_name": "shop_name",
    "transaction_time": "pay_time"
  }
}
```

sync_scope

作用：定义同步任务的数据范围

```json
{
  "time_range": {
    "start": "2024-01-01T00:00:00Z",
    "end": "2024-03-20T23:59:59Z"
  },
  "transaction_types": [
    "PAYMENT",
    "REFUND",
    "TRANSFER"
  ],
  "merchants": {
    "include": ["淘宝", "天猫"],
    "exclude": ["闲鱼"]
  },
  "amount_range": {
    "min": 0.01,
    "max": 50000.00
  },
  "categories": [
    "shopping",
    "entertainment"
  ]
}
```

retry_strategy

作用：定义同步失败时的重试策略

```json
{
  "max_attempts": 3,
  "backoff_type": "EXPONENTIAL",  // 指数退避
  "initial_delay_seconds": 60,
  "max_delay_seconds": 3600,
  "retry_conditions": {
    "error_types": [
      "NETWORK_ERROR",
      "TIMEOUT_ERROR"
    ],
    "exclude_errors": [
      "AUTH_ERROR",
      "INVALID_PARAMETER"
    ]
  },
  "notification_threshold": 2,     // 重试次数达到阈值时通知
  "fallback_action": "MANUAL"      // 重试失败后的处理方式
}
```

ReminderAgg

```pgsql
-- 创建提醒表 (ReminderAgg)
CREATE TABLE reminders (
    id                SERIAL PRIMARY KEY,
    user_id           VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    name              VARCHAR(100) NOT NULL,                
    cron_expression   VARCHAR(100) NOT NULL,               
    timezone          VARCHAR(50) DEFAULT 'Asia/Shanghai',  
    enabled           BOOLEAN DEFAULT TRUE,                 
  
    -- 提醒内容配置
    template_id       VARCHAR(50) NOT NULL,                
    template_params   JSONB,                               
  
    -- 触发条件
    trigger_conditions JSONB,                              
  
    -- 通知配置
    notification_config JSONB,                             
  
    -- 执行配置
    retry_config      JSONB,                               
    max_executions    INT,                                 
    start_at          TIMESTAMPTZ NOT NULL,                
    end_at            TIMESTAMPTZ,                         
  
    -- 执行状态
    last_execution_at TIMESTAMPTZ,                         
    next_execution_at TIMESTAMPTZ,                         
    execution_count   INT DEFAULT 0,                       
    last_status       VARCHAR(20) DEFAULT 'pending',       
  
    -- 元数据
    created_at        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by        VARCHAR(255) NOT NULL,               
    updated_by        VARCHAR(255) NOT NULL                
);

-- 表注释
COMMENT ON TABLE reminders IS '基于Cron的提醒聚合根表，用于管理系统中的所有定时提醒任务';

-- 字段注释
COMMENT ON COLUMN reminders.id IS '提醒ID，主键';
COMMENT ON COLUMN reminders.user_id IS '用户ID，关联users表';
COMMENT ON COLUMN reminders.name IS '提醒名称，用于用户识别提醒用途';
COMMENT ON COLUMN reminders.cron_expression IS 'Cron表达式，定义提醒的执行时间规则';
COMMENT ON COLUMN reminders.timezone IS '时区设置，用于确保在正确的时区执行提醒';
COMMENT ON COLUMN reminders.enabled IS '是否启用该提醒';

COMMENT ON COLUMN reminders.template_id IS '提醒模板ID，关联消息模板';
COMMENT ON COLUMN reminders.template_params IS '模板参数，用于填充提醒模板的动态内容';

COMMENT ON COLUMN reminders.trigger_conditions IS '触发条件配置，JSON格式，定义提醒触发的具体条件';
COMMENT ON COLUMN reminders.notification_config IS '通知配置，JSON格式，定义如何发送通知';

COMMENT ON COLUMN reminders.retry_config IS '重试配置，JSON格式，定义失败后的重试策略';
COMMENT ON COLUMN reminders.max_executions IS '最大执行次数，null表示无限制';
COMMENT ON COLUMN reminders.start_at IS '提醒开始生效时间';
COMMENT ON COLUMN reminders.end_at IS '提醒结束时间，null表示永不结束';

COMMENT ON COLUMN reminders.last_execution_at IS '上次执行时间';
COMMENT ON COLUMN reminders.next_execution_at IS '下次计划执行时间';
COMMENT ON COLUMN reminders.execution_count IS '已执行次数统计';
COMMENT ON COLUMN reminders.last_status IS '上次执行状态：pending/running/success/failed';

COMMENT ON COLUMN reminders.created_at IS '记录创建时间';
COMMENT ON COLUMN reminders.updated_at IS '记录最后更新时间';
COMMENT ON COLUMN reminders.created_by IS '创建者ID';
COMMENT ON COLUMN reminders.updated_by IS '最后更新者ID';

-- 创建提醒执行历史表
CREATE TABLE reminder_executions (
    id                SERIAL PRIMARY KEY,
    reminder_id       INT NOT NULL REFERENCES reminders (id) ON DELETE CASCADE,
    execution_time    TIMESTAMPTZ NOT NULL,                
    status           VARCHAR(20) NOT NULL,                 
    error_message    TEXT,                                 
    execution_data   JSONB,                                
    created_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 表注释
COMMENT ON TABLE reminder_executions IS '提醒执行历史表，记录每次提醒执行的详细信息';

-- 字段注释
COMMENT ON COLUMN reminder_executions.id IS '执行记录ID，主键';
COMMENT ON COLUMN reminder_executions.reminder_id IS '关联的提醒ID';
COMMENT ON COLUMN reminder_executions.execution_time IS '实际执行时间';
COMMENT ON COLUMN reminder_executions.status IS '执行状态：success/failed/timeout等';
COMMENT ON COLUMN reminder_executions.error_message IS '执行失败时的错误信息';
COMMENT ON COLUMN reminder_executions.execution_data IS '执行相关的详细数据，JSON格式';
COMMENT ON COLUMN reminder_executions.created_at IS '记录创建时间';

-- 创建索引
CREATE INDEX idx_reminders_user ON reminders(user_id);
COMMENT ON INDEX idx_reminders_user IS '用户ID索引，用于快速查询用户的所有提醒';

CREATE INDEX idx_reminders_next_execution ON reminders(next_execution_at) 
WHERE enabled = true;
COMMENT ON INDEX idx_reminders_next_execution IS '下次执行时间索引，仅包含已启用的提醒，用于调度系统查询';

CREATE INDEX idx_reminder_executions_reminder ON reminder_executions(reminder_id);
COMMENT ON INDEX idx_reminder_executions_reminder IS '提醒ID索引，用于快速查询提醒的执行历史';

-- 创建状态检查约束
ALTER TABLE reminders 
ADD CONSTRAINT valid_reminder_status 
CHECK (last_status IN ('pending', 'running', 'success', 'failed', 'timeout'));

-- 创建时间范围检查约束
ALTER TABLE reminders 
ADD CONSTRAINT valid_reminder_timerange 
CHECK (start_at < end_at OR end_at IS NULL);

-- 创建执行次数检查约束
ALTER TABLE reminders 
ADD CONSTRAINT valid_execution_count 
CHECK (execution_count >= 0);

-- 创建执行状态检查约束
ALTER TABLE reminder_executions 
ADD CONSTRAINT valid_execution_status 
CHECK (status IN ('success', 'failed', 'timeout', 'skipped'));

```

tigger_conditions

触发提醒的条件

```json
{
  "type": "AND",
  "conditions": [
    {
      "type": "AMOUNT_RANGE",
      "min": 100.00,
      "max": 1000.00
    },
    {
      "type": "CATEGORY",
      "categories": ["餐饮", "购物"]
    },
    {
      "type": "BALANCE_CHECK",
      "minimum_balance": 1000.00
    }
  ]
}
```


notification_config

通知的配置

```json
{
  "channels": [
    {
      "type": "APP_PUSH",
      "template": "payment_reminder",
      "priority": "high"
    },
    {
      "type": "EMAIL",
      "template": "payment_reminder_email",
      "delay_minutes": 5
    }
  ],
  "quiet_hours": {
    "enabled": true,
    "start": "22:00",
    "end": "08:00",
    "timezone": "Asia/Shanghai"
  },
  "batch_strategy": "IMMEDIATE"
}
```

retry_config

重试的配置

```json
{
  "max_attempts": 3,
  "backoff_type": "EXPONENTIAL",
  "initial_delay_seconds": 60,
  "max_delay_seconds": 3600,
  "retry_on_status": ["failed", "timeout"]
}
```


---

## AI Service Integration Architecture

This section details the architecture for integrating a real-world AI service (Alibaba Qwen via LangChain4j) into the `payment-tracker-analysis` bounded context, adhering to the principles of Hexagonal Architecture.

### 1. Architectural Design

The design introduces a clear separation between the application's core logic and the external AI service. This is achieved by defining an outbound port (`AIAnalysisPort`) that represents the contract for AI analysis, and an outbound adapter (`LangChain4jAIAnalysisAdapter`) that provides the concrete implementation for this port.

This approach offers several key advantages:
- **Decoupling**: The application core is not tied to a specific AI provider or library.
- **Testability**: The application core can be tested in isolation by mocking the `AIAnalysisPort`. The adapter can be tested independently.
- **Replaceability**: To switch to a different AI service (e.g., from Alibaba to Google Gemini), only a new adapter needs to be created, with no changes to the core business logic.

### 2. Core Components

#### a. `AIAnalysisPort` (Outbound Port)
- **Type**: Java Interface
- **Location**: `io.github.paymenttracker.analysis.application.port.out`
- **Responsibility**: Defines the contract for analyzing a payment image. It dictates *what* the application needs (e.g., a method `analyzePaymentImage(URL imageUrl)`) without specifying *how* it's done.

#### b. `LangChain4jAIAnalysisAdapter` (Outbound Adapter)
- **Type**: Spring `@Component`
- **Location**: `io.github.paymenttracker.analysis.adapter.out.ai`
- **Responsibility**: Implements the `AIAnalysisPort`. It contains the specific logic to interact with the Alibaba Qwen service using the LangChain4j framework. It handles prompt creation, API calls, and exception mapping.

### 3. Data Flow and Interaction Diagram

The following diagram illustrates the interaction between the components, from the initial event to the final interaction with the external AI service.

```plantuml
@startuml AI Service Integration - Hexagonal View

!include ./doc/domain-puml/ai_analysis_context.puml!Hexagonal_Architecture_View

@enduml
```

**Flow Description:**
1.  An **`ImageAnalysisRequestedEvent`** is published when a new payment image is uploaded.
2.  The **`ImageAnalysisRequestListener`** (inbound adapter) catches this event.
3.  It calls the **`ImageAnalysisApplicationService`** (application core) to orchestrate the analysis process.
4.  The application service interacts with the **`ImageAnalysisAttemptAgg`** domain aggregate to manage state.
5.  To perform the actual analysis, the service calls the **`analyzePaymentImage`** method on the **`AIAnalysisPort`**.
6.  Spring's dependency injection provides the **`LangChain4jAIAnalysisAdapter`** as the implementation for the port.
7.  The adapter uses **LangChain4j** to construct the request and calls the external **Alibaba Qwen AI Service**.
8.  The result is returned through the port to the application service, which then updates the aggregate and publishes success or failure events.

### 4. Configuration

The connection to the AI service is managed via external configuration in `application.yml`, preventing hardcoded secrets and allowing for easy environment-specific setup.

**File:** `payment-tracker-app/src/main/resources/application.yml`
```yaml
langchain4j:
  open-ai:
    chat-model:
      api-key: ${QWEN_API_KEY} # Best practice: Use environment variables
      model-name: qwen2.5-vl-7b-instruct
      base-url: https://dashscope.aliyuncs.com/compatible-mode/v1
      log-requests: true
      log-responses: true
```
