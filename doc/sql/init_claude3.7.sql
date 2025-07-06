-- 创建用户表 (UserAgg)
CREATE TABLE users
(
    id                       SERIAL PRIMARY KEY,
    user_id                  VARCHAR(255) UNIQUE NOT NULL,
    email                    VARCHAR(255) UNIQUE NOT NULL,
    phone                    VARCHAR(20) UNIQUE,
    password_hash            VARCHAR(255)        NOT NULL,
    encryption_key           BYTEA,
    two_factor_auth          BOOLEAN     DEFAULT FALSE,
    created_at               TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at               TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    -- 新增：支付方式集合和提醒设置集合的引用
    payment_methods_config   JSONB,
    reminder_settings_config JSONB,
    -- 新增：安全相关字段
    security_settings        JSONB,
    last_login_at            TIMESTAMPTZ
);
COMMENT ON TABLE users IS '用户聚合根表';
COMMENT ON COLUMN users.id IS '自增主键';
COMMENT ON COLUMN users.user_id IS '业务生成的用户唯一标识';
COMMENT ON COLUMN users.email IS '用户的电子邮件地址';
COMMENT ON COLUMN users.phone IS '用户的电话号码';
COMMENT ON COLUMN users.password_hash IS '用户的密码哈希';
COMMENT ON COLUMN users.encryption_key IS '用于数据安全的加密密钥';
COMMENT ON COLUMN users.two_factor_auth IS '是否启用双因素认证';
COMMENT ON COLUMN users.created_at IS '账户创建时间';
COMMENT ON COLUMN users.updated_at IS '最后更新时间';
COMMENT ON COLUMN users.payment_methods_config IS '支付方式配置';
COMMENT ON COLUMN users.reminder_settings_config IS '提醒设置配置';
COMMENT ON COLUMN users.security_settings IS '安全设置';
COMMENT ON COLUMN users.last_login_at IS '最后登录时间';

-- 创建登录记录表
CREATE TABLE login_history
(
    id           SERIAL PRIMARY KEY,
    user_id      VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    login_time   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    ip_address   INET,
    device_info  TEXT,
    login_status VARCHAR(20)  NOT NULL,
    platform     VARCHAR(50)  NOT NULL -- 新增：记录登录平台（Web/iOS/Android）
);
COMMENT ON TABLE login_history IS '存储用户登录历史';
COMMENT ON COLUMN login_history.user_id IS '业务生成的用户唯一标识';
COMMENT ON COLUMN login_history.login_time IS '登录时间';
COMMENT ON COLUMN login_history.ip_address IS '登录IP地址';
COMMENT ON COLUMN login_history.device_info IS '登录设备信息';
COMMENT ON COLUMN login_history.login_status IS '登录状态：success/failed';
COMMENT ON COLUMN login_history.platform IS '登录平台：Web/iOS/Android';

-- 创建支付方式表 (UserAgg的一部分)
CREATE TABLE payment_methods
(
    id            SERIAL PRIMARY KEY,
    user_id       VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    type          VARCHAR(50)  NOT NULL,
    details       JSONB,
    is_active     BOOLEAN     DEFAULT TRUE,
    created_at    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    display_order INT         DEFAULT 0
);
COMMENT ON TABLE payment_methods IS '支付方式表，用户聚合的一部分';
COMMENT ON COLUMN payment_methods.id IS '自增主键';
COMMENT ON COLUMN payment_methods.user_id IS '业务生成的用户唯一标识';
COMMENT ON COLUMN payment_methods.type IS '支付方式类型（如支付宝、微信支付）';
COMMENT ON COLUMN payment_methods.details IS '支付方式的额外详情';
COMMENT ON COLUMN payment_methods.is_active IS '支付方式是否有效';
COMMENT ON COLUMN payment_methods.created_at IS '支付方式添加时间';
COMMENT ON COLUMN payment_methods.updated_at IS '最后更新时间';
COMMENT ON COLUMN payment_methods.display_order IS '显示顺序';

-- 创建提醒设置表 (UserAgg的一部分)
CREATE TABLE reminder_settings
(
    id                    SERIAL PRIMARY KEY,
    user_id               VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    type                  VARCHAR(50)  NOT NULL,
    frequency             VARCHAR(50),
    cron_expression       VARCHAR(100),
    next_trigger_at       TIMESTAMPTZ,
    related_record_id     INT,
    is_active             BOOLEAN     DEFAULT TRUE,
    created_at            TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    -- 新增：通知渠道配置
    notification_channels JSONB,
    -- 新增：提醒优先级
    priority              VARCHAR(20) DEFAULT 'normal'
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

-- 创建分类体系表
CREATE TABLE categories
(
    id             SERIAL PRIMARY KEY,
    user_id        VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    name           VARCHAR(50)  NOT NULL,
    parent_id      INT REFERENCES categories (id),
    is_system      BOOLEAN     DEFAULT FALSE,
    created_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    -- 新增：支持分类图标和颜色，提高用户体验
    icon           VARCHAR(50),
    color          VARCHAR(20),
    -- 新增：分类规则
    category_rules JSONB,
    -- 新增：分类描述
    description    TEXT,
    -- 新增：显示顺序
    display_order  INT         DEFAULT 0,
    -- 新增：预算限额
    budget_limit   DECIMAL(10, 2)
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

-- 创建AI提供商表
CREATE TABLE ai_providers
(
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    description TEXT,
    api_key     VARCHAR(255),
    is_active   BOOLEAN     DEFAULT TRUE,
    created_at  TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE ai_providers IS '存储AI API提供商信息';
COMMENT ON COLUMN ai_providers.name IS 'AI提供商名称';
COMMENT ON COLUMN ai_providers.description IS '提供商描述';
COMMENT ON COLUMN ai_providers.api_key IS 'API密钥';
COMMENT ON COLUMN ai_providers.is_active IS '提供商是否有效';
COMMENT ON COLUMN ai_providers.created_at IS '提供商添加时间';
COMMENT ON COLUMN ai_providers.updated_at IS '最后更新时间';

-- 创建API服务表
CREATE TABLE api_services
(
    id          SERIAL PRIMARY KEY,
    provider_id INT REFERENCES ai_providers (id) ON DELETE CASCADE,
    name        VARCHAR(255) NOT NULL,
    endpoint    VARCHAR(255) NOT NULL,
    description TEXT,
    is_active   BOOLEAN     DEFAULT TRUE,
    created_at  TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE api_services IS '存储AI提供商的API服务信息';
COMMENT ON COLUMN api_services.provider_id IS '引用AI提供商表的外部键';
COMMENT ON COLUMN api_services.name IS 'API服务名称';
COMMENT ON COLUMN api_services.endpoint IS 'API端点URL';
COMMENT ON COLUMN api_services.description IS 'API服务描述';
COMMENT ON COLUMN api_services.is_active IS 'API服务是否有效';
COMMENT ON COLUMN api_services.created_at IS 'API服务创建时间';
COMMENT ON COLUMN api_services.updated_at IS '最后更新时间';

-- 创建分析结果表
CREATE TABLE analysis_results
(
    id                SERIAL PRIMARY KEY,
    user_id           VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    service_id        INT REFERENCES api_services (id),
    input_data        TEXT,
    output_data       JSONB,
    analysis_type     VARCHAR(50)  NOT NULL,
    analysis_duration INT,
    created_at        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE analysis_results IS '存储AI分析结果';

COMMENT ON COLUMN analysis_results.user_id IS '引用用户表的外部键';
COMMENT ON COLUMN analysis_results.service_id IS '引用API服务表的外部键';
COMMENT ON COLUMN analysis_results.input_data IS '分析的输入数据';
COMMENT ON COLUMN analysis_results.output_data IS '分析输出数据，JSON格式';
COMMENT ON COLUMN analysis_results.analysis_type IS '分析类型';
COMMENT ON COLUMN analysis_results.analysis_duration IS '分析耗时(毫秒)';
COMMENT ON COLUMN analysis_results.created_at IS '分析结果创建时间';
COMMENT ON COLUMN analysis_results.updated_at IS '最后更新时间';

-- 创建API权重表
CREATE TABLE api_weights
(
    id            SERIAL PRIMARY KEY,
    service_id    INT REFERENCES api_services (id) ON DELETE CASCADE,
    weight        INT NOT NULL DEFAULT 1,
    last_used_at  TIMESTAMPTZ,
    success_count INT          DEFAULT 0,
    error_count   INT          DEFAULT 0,
    created_at    TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE api_weights IS '存储API服务的权重，用于优先级调用';
COMMENT ON COLUMN api_weights.service_id IS '引用API服务表的外部键';
COMMENT ON COLUMN api_weights.weight IS '权重值';
COMMENT ON COLUMN api_weights.last_used_at IS '最后调用时间';
COMMENT ON COLUMN api_weights.success_count IS '成功调用次数';
COMMENT ON COLUMN api_weights.error_count IS '错误调用次数';
COMMENT ON COLUMN api_weights.created_at IS '权重分配时间';
COMMENT ON COLUMN api_weights.updated_at IS '最后更新时间';

-- 创建支付凭证图像表 (PaymentImageAgg)
CREATE TABLE payment_images
(
    id                    SERIAL PRIMARY KEY,
    user_id               VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    image_file_url        TEXT         NOT NULL,
    upload_time           TIMESTAMPTZ  NOT NULL,
    analysis_result       JSONB,
    status                VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'success', 'failed')),
    created_at            TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    unique_hash           VARCHAR(64),
    -- 新增：记录上传平台信息
    platform              VARCHAR(50),
    -- 新增：图像处理元数据
    metadata              JSONB,
    -- 新增：图像分类结果
    classification_result JSONB,
    CONSTRAINT unique_payment_image_hash UNIQUE (unique_hash)

);
COMMENT ON TABLE payment_images IS '支付凭证图像聚合根表';
COMMENT ON COLUMN payment_images.id IS '自增主键';
COMMENT ON COLUMN payment_images.user_id IS '业务生成的用户唯一标识';
COMMENT ON COLUMN payment_images.image_file_url IS '图像文件路径或URL';
COMMENT ON COLUMN payment_images.upload_time IS '上传时间';
COMMENT ON COLUMN payment_images.analysis_result IS 'AI分析结果，JSON格式';
COMMENT ON COLUMN payment_images.status IS '处理状态: pending/processing/success/failed';
COMMENT ON COLUMN payment_images.created_at IS '创建时间';
COMMENT ON COLUMN payment_images.updated_at IS '最后更新时间';
COMMENT ON COLUMN payment_images.platform IS '上传平台：Web/iOS/Android';
COMMENT ON COLUMN payment_images.unique_hash IS '取图片hash，快速判断图片是否上传过';
COMMENT ON COLUMN payment_images.metadata IS '图像处理元数据';
COMMENT ON COLUMN payment_images.classification_result IS '图像分类结果';

-- 创建支付凭证图像列表表（读模型）
CREATE TABLE payment_images_list
(
    id              SERIAL PRIMARY KEY,
    image_id        INT UNIQUE   NOT NULL REFERENCES payment_images (id) ON DELETE CASCADE,
    user_id         VARCHAR(255) NOT NULL,
    upload_time     TIMESTAMPTZ  NOT NULL,
    analysis_result JSONB,
    status          VARCHAR(20),
    updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE payment_images_list IS '支付凭证图像列表，优化查询性能';

-- 创建支付记录表 (PaymentRecordAgg)
CREATE TABLE payment_records
(
    id                 SERIAL PRIMARY KEY,
    user_id            VARCHAR(255)   NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    payment_method_id  INT REFERENCES payment_methods (id),
    amount             DECIMAL(10, 2) NOT NULL,
    payment_date       TIMESTAMPTZ    NOT NULL,
    merchant           VARCHAR(255),
    category_id        INT REFERENCES categories (id),
    image_id           INT REFERENCES payment_images (id),
    analysis_result_id INT REFERENCES analysis_results (id),
    source_type        VARCHAR(20)    NOT NULL DEFAULT 'manual',
    payment_status     VARCHAR(20)    NOT NULL DEFAULT 'success',
    retry_count        INT                     DEFAULT 0,
    unique_hash        VARCHAR(64),
    is_deleted         BOOLEAN                 DEFAULT FALSE,
    created_at         TIMESTAMPTZ             DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMPTZ             DEFAULT CURRENT_TIMESTAMP,
    -- 新增：支持记录备注和位置信息
    notes              TEXT,
    -- 新增：添加标签支持
    tags               VARCHAR(255)[],
    -- 新增：记录平台信息
    platform           VARCHAR(50),
    -- 新增：交易流水号
    transaction_id     VARCHAR(100),
    -- 新增：退款状态
    refund_status      VARCHAR(20),
    -- 添加 unique_hash 字段的唯一约束
    CONSTRAINT unique_payment_hash UNIQUE (unique_hash)
);

COMMENT ON TABLE payment_records IS '支付记录聚合根表';
COMMENT ON COLUMN payment_records.id IS '自增主键';
COMMENT ON COLUMN payment_records.user_id IS '业务生成的用户唯一标识';
COMMENT ON COLUMN payment_records.analysis_result_id IS '引用分析结果表的外部键';
COMMENT ON COLUMN payment_records.payment_method_id IS '支付方式ID';
COMMENT ON COLUMN payment_records.amount IS '支付金额';
COMMENT ON COLUMN payment_records.payment_date IS '支付日期和时间';
COMMENT ON COLUMN payment_records.merchant IS '支付商户或收款方';
COMMENT ON COLUMN payment_records.category_id IS '支付分类ID';
COMMENT ON COLUMN payment_records.source_type IS '记录来源: manual(手动)/sync(同步)/ai(AI解析)';
COMMENT ON COLUMN payment_records.payment_status IS '支付状态: success/failed/pending';
COMMENT ON COLUMN payment_records.retry_count IS '失败重试次数';
COMMENT ON COLUMN payment_records.unique_hash IS 'user_id,payment_method_id,amount,payment_date,merchant这几个字段拼接后取hash值写入这个去重字段';
COMMENT ON COLUMN payment_records.image_id IS '引用支付凭证图像表的外部键';
COMMENT ON COLUMN payment_records.is_deleted IS '是否已删除（软删除）';
COMMENT ON COLUMN payment_records.created_at IS '创建时间';
COMMENT ON COLUMN payment_records.updated_at IS '最后更新时间';
COMMENT ON COLUMN payment_records.notes IS '支付备注信息';
COMMENT ON COLUMN payment_records.tags IS '支付记录标签';
COMMENT ON COLUMN payment_records.platform IS '记录创建平台：Web/iOS/Android';
COMMENT ON COLUMN payment_records.transaction_id IS '交易流水号';
COMMENT ON COLUMN payment_records.refund_status IS '退款状态 - none(未退款)/completed(完成退款)/failed(退款失败)/cancelled(取消退款)';

-- 创建支付平台同步任务表 (PlatformSyncAgg)
CREATE TABLE payment_sync_tasks
(
    id             SERIAL PRIMARY KEY,
    user_id        VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    platform       VARCHAR(50)  NOT NULL,
    auth_token     TEXT         NOT NULL,
    last_sync_at   TIMESTAMPTZ,
    next_sync_at   TIMESTAMPTZ,
    sync_frequency VARCHAR(50),
    is_active      BOOLEAN     DEFAULT TRUE,
    created_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    -- 新增：同步配置参数
    sync_config    JSONB,
    -- 新增：错误计数
    error_count    INT         DEFAULT 0,
    -- 新增：最后错误信息
    last_error     TEXT,
    -- 新增：同步范围配置
    sync_scope     JSONB,
    -- 新增：同步优先级
    priority       VARCHAR(20) DEFAULT 'normal',
    -- 新增：重试策略
    retry_strategy JSONB
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

-- 创建图片上传记录表
CREATE TABLE payment_uploads
(
    id                 SERIAL PRIMARY KEY,
    user_id            VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    file_path          TEXT         NOT NULL,
    status             VARCHAR(20) DEFAULT 'pending',
    analysis_result_id INT REFERENCES analysis_results (id),
    created_at         TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    platform           VARCHAR(50)
);
COMMENT ON TABLE payment_uploads IS '支付凭证图片上传记录';
COMMENT ON COLUMN payment_uploads.status IS '处理状态: pending/processing/success/failed';
COMMENT ON COLUMN payment_uploads.created_at IS '创建时间';
COMMENT ON COLUMN payment_uploads.updated_at IS '最后更新时间';
COMMENT ON COLUMN payment_uploads.platform IS '上传平台：Web/iOS/Android';

-- 创建分析表 (AnalyticsAgg)
CREATE TABLE analyses
(
    id             SERIAL PRIMARY KEY,
    user_id        VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    type           VARCHAR(50)  NOT NULL,
    data           JSONB,
    created_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    -- 新增：分析参数和时间范围
    params         JSONB,
    time_range     JSONB,
    -- 新增：是否为系统自动生成
    auto_generated BOOLEAN     DEFAULT FALSE,
    -- 新增：分析状态
    status         VARCHAR(20) DEFAULT 'pending',
    -- 新增：分析版本
    version        VARCHAR(20),
    -- 新增：分析摘要
    summary        TEXT
);
COMMENT ON TABLE analyses IS '分析聚合根表';
COMMENT ON COLUMN analyses.type IS '分析类型（如趋势分析、类别分析、支付方式分析）';
COMMENT ON COLUMN analyses.created_at IS '创建时间';
COMMENT ON COLUMN analyses.updated_at IS '最后更新时间';
COMMENT ON COLUMN analyses.params IS '分析参数，JSON格式';
COMMENT ON COLUMN analyses.time_range IS '分析时间范围，JSON格式';
COMMENT ON COLUMN analyses.auto_generated IS '是否为系统自动生成的分析';
COMMENT ON COLUMN analyses.status IS '分析状态';
COMMENT ON COLUMN analyses.version IS '分析版本';
COMMENT ON COLUMN analyses.summary IS '分析摘要';

-- 创建提醒表 (ReminderAgg)
CREATE TABLE reminders
(
    id                  SERIAL PRIMARY KEY,
    user_id             VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    name                VARCHAR(100) NOT NULL,
    cron_expression     VARCHAR(100) NOT NULL,
    timezone            VARCHAR(50) DEFAULT 'Asia/Shanghai',
    enabled             BOOLEAN     DEFAULT TRUE,

    -- 提醒内容配置
    template_id         VARCHAR(50)  NOT NULL,
    template_params     JSONB,

    -- 触发条件
    trigger_conditions  JSONB,

    -- 通知配置
    notification_config JSONB,

    -- 执行配置
    retry_config        JSONB,
    max_executions      INT,
    start_at            TIMESTAMPTZ  NOT NULL,
    end_at              TIMESTAMPTZ,

    -- 执行状态
    last_execution_at   TIMESTAMPTZ,
    next_execution_at   TIMESTAMPTZ,
    execution_count     INT         DEFAULT 0,
    last_status         VARCHAR(20) DEFAULT 'pending',

    -- 元数据
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(255) NOT NULL,
    updated_by          VARCHAR(255) NOT NULL
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
CREATE TABLE reminder_executions
(
    id             SERIAL PRIMARY KEY,
    reminder_id    INT         NOT NULL REFERENCES reminders (id) ON DELETE CASCADE,
    execution_time TIMESTAMPTZ NOT NULL,
    status         VARCHAR(20) NOT NULL,
    error_message  TEXT,
    execution_data JSONB,
    created_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
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
CREATE INDEX idx_reminders_user ON reminders (user_id);
COMMENT ON INDEX idx_reminders_user IS '用户ID索引，用于快速查询用户的所有提醒';

CREATE INDEX idx_reminders_next_execution ON reminders (next_execution_at)
    WHERE enabled = true;
COMMENT ON INDEX idx_reminders_next_execution IS '下次执行时间索引，仅包含已启用的提醒，用于调度系统查询';

CREATE INDEX idx_reminder_executions_reminder ON reminder_executions (reminder_id);
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

-- 创建导出记录表
CREATE TABLE exports
(
    id            SERIAL PRIMARY KEY,
    user_id       VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    format        VARCHAR(10)  NOT NULL,
    storage_path  TEXT         NOT NULL,
    status        VARCHAR(20) DEFAULT 'pending',
    file_size     BIGINT,
    created_at    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    -- 新增：添加导出参数和分享功能
    export_params JSONB,
    -- 新增：添加是否为分享格式
    is_shared     BOOLEAN     DEFAULT FALSE,
    -- 新增：分享链接（如果适用）
    share_link    TEXT,
    -- 新增：分享过期时间（如果适用）
    expiry_time   TIMESTAMPTZ,
    -- 新增：导出平台
    platform      VARCHAR(50)
);
COMMENT ON TABLE exports IS '存储用户导出的数据记录';
COMMENT ON COLUMN exports.user_id IS '引用用户表的外部键';
COMMENT ON COLUMN exports.format IS '导出数据的格式（如CSV、Excel、PDF）';
COMMENT ON COLUMN exports.status IS '导出状态: pending/processing/completed/failed';
COMMENT ON COLUMN exports.created_at IS '导出记录创建时间';
COMMENT ON COLUMN exports.storage_path IS '文件存储路径';
COMMENT ON COLUMN exports.file_size IS '文件大小(字节)';
COMMENT ON COLUMN exports.updated_at IS '最后更新时间';
COMMENT ON COLUMN exports.export_params IS '导出参数，JSON格式';
COMMENT ON COLUMN exports.is_shared IS '是否为分享导出';
COMMENT ON COLUMN exports.share_link IS '分享链接URL';
COMMENT ON COLUMN exports.expiry_time IS '分享链接过期时间';
COMMENT ON COLUMN exports.platform IS '导出操作平台：Web/iOS/Android';

-- 创建用户账户统计表（读模型）
CREATE TABLE user_account_stats
(
    id                  SERIAL PRIMARY KEY,
    user_id             VARCHAR(255) UNIQUE NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    email               VARCHAR(255)        NOT NULL,
    phone               VARCHAR(20),
    registration_date   TIMESTAMPTZ         NOT NULL,
    login_count         INT            DEFAULT 0,
    last_login_time     TIMESTAMPTZ,
    updated_at          TIMESTAMPTZ    DEFAULT CURRENT_TIMESTAMP,
    -- 新增：平台使用统计
    web_login_count     INT            DEFAULT 0,
    ios_login_count     INT            DEFAULT 0,
    android_login_count INT            DEFAULT 0,
    -- 新增：支付记录统计
    payment_count       INT            DEFAULT 0,
    total_spend         DECIMAL(12, 2) DEFAULT 0.00,
    -- 新增：活跃度得分
    activity_score      INT            DEFAULT 0,
    -- 新增：用户状态
    user_status         VARCHAR(20)    DEFAULT 'active'
);
COMMENT ON TABLE user_account_stats IS '用户账户统计读模型表';
COMMENT ON COLUMN user_account_stats.user_id IS '引用用户表的外部键';
COMMENT ON COLUMN user_account_stats.email IS '用户的电子邮件地址';
COMMENT ON COLUMN user_account_stats.phone IS '用户的电话号码';
COMMENT ON COLUMN user_account_stats.registration_date IS '用户注册时间';
COMMENT ON COLUMN user_account_stats.login_count IS '用户登录次数';
COMMENT ON COLUMN user_account_stats.last_login_time IS '最后登录时间';
COMMENT ON COLUMN user_account_stats.updated_at IS '最后更新时间';
COMMENT ON COLUMN user_account_stats.web_login_count IS 'Web端登录次数';
COMMENT ON COLUMN user_account_stats.ios_login_count IS 'iOS端登录次数';
COMMENT ON COLUMN user_account_stats.android_login_count IS 'Android端登录次数';
COMMENT ON COLUMN user_account_stats.payment_count IS '支付记录总数';
COMMENT ON COLUMN user_account_stats.total_spend IS '总支出金额';
COMMENT ON COLUMN user_account_stats.activity_score IS '活跃度得分';
COMMENT ON COLUMN user_account_stats.user_status IS '用户状态';

-- 创建支付记录列表表（读模型）
CREATE TABLE payment_records_list
(
    id                  SERIAL PRIMARY KEY,
    payment_record_id   INT UNIQUE     NOT NULL REFERENCES payment_records (id) ON DELETE CASCADE,
    user_id             VARCHAR(255)   NOT NULL,
    amount              DECIMAL(10, 2) NOT NULL,
    payment_date        TIMESTAMPTZ    NOT NULL,
    merchant            VARCHAR(255),
    payment_method_type VARCHAR(50),
    category            VARCHAR(50),
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    -- 新增：支持更多查询条件
    category_id         INT,
    tags                VARCHAR(255)[],
    notes               TEXT
);
COMMENT ON TABLE payment_records_list IS '支付记录列表，优化查询性能';
COMMENT ON COLUMN payment_records_list.payment_record_id IS '引用支付记录表的外部键';
COMMENT ON COLUMN payment_records_list.user_id IS '用户ID';
COMMENT ON COLUMN payment_records_list.amount IS '支付金额';
COMMENT ON COLUMN payment_records_list.payment_date IS '支付日期和时间';
COMMENT ON COLUMN payment_records_list.merchant IS '支付商户';
COMMENT ON COLUMN payment_records_list.payment_method_type IS '支付方式类型';
COMMENT ON COLUMN payment_records_list.category IS '支付分类';
COMMENT ON COLUMN payment_records_list.updated_at IS '最后更新时间';
COMMENT ON COLUMN payment_records_list.category_id IS '分类ID';
COMMENT ON COLUMN payment_records_list.tags IS '标签数组';
COMMENT ON COLUMN payment_records_list.notes IS '备注信息';

-- 创建分析数据表（读模型）
CREATE TABLE analysis_data
(
    id            SERIAL PRIMARY KEY,
    analysis_id   INT UNIQUE   NOT NULL REFERENCES analyses (id) ON DELETE CASCADE,
    user_id       VARCHAR(255) NOT NULL,
    type          VARCHAR(50)  NOT NULL,
    data          JSONB,
    created_at    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    -- 新增：简短描述
    summary       TEXT,
    -- 新增：可视化配置
    visual_config JSONB
);
COMMENT ON TABLE analysis_data IS '分析数据视图，供快速访问';
COMMENT ON COLUMN analysis_data.analysis_id IS '引用分析表的外部键';
COMMENT ON COLUMN analysis_data.user_id IS '用户ID';
COMMENT ON COLUMN analysis_data.type IS '分析类型';
COMMENT ON COLUMN analysis_data.data IS '分析数据，JSON格式';
COMMENT ON COLUMN analysis_data.created_at IS '创建时间';
COMMENT ON COLUMN analysis_data.updated_at IS '最后更新时间';
COMMENT ON COLUMN analysis_data.summary IS '分析摘要描述';
COMMENT ON COLUMN analysis_data.visual_config IS '可视化配置，JSON格式';

-- 创建提醒列表表（读模型）
CREATE TABLE reminders_list
(
    id                SERIAL PRIMARY KEY,
    reminder_id       INT UNIQUE   NOT NULL REFERENCES reminders (id) ON DELETE CASCADE,
    user_id           VARCHAR(255) NOT NULL,
    payment_record_id INT,
    reminder_date     TIMESTAMPTZ  NOT NULL,
    message           TEXT,
    status            VARCHAR(20),
    updated_at        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    -- 新增：通知首选项
    notification_type VARCHAR(50),
    -- 新增：支付信息摘要
    payment_summary   TEXT
);
COMMENT ON TABLE reminders_list IS '提醒列表，优化查询性能';
COMMENT ON COLUMN reminders_list.reminder_id IS '引用提醒表的外部键';
COMMENT ON COLUMN reminders_list.user_id IS '用户ID';
COMMENT ON COLUMN reminders_list.payment_record_id IS '支付记录ID';
COMMENT ON COLUMN reminders_list.reminder_date IS '提醒日期和时间';
COMMENT ON COLUMN reminders_list.message IS '提醒消息';
COMMENT ON COLUMN reminders_list.status IS '提醒状态';
COMMENT ON COLUMN reminders_list.updated_at IS '最后更新时间';
COMMENT ON COLUMN reminders_list.notification_type IS '通知方式';
COMMENT ON COLUMN reminders_list.payment_summary IS '支付信息摘要';

-- 创建用户操作日志表
CREATE TABLE user_activity_logs
(
    id            SERIAL PRIMARY KEY,
    user_id       VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    activity_type VARCHAR(50)  NOT NULL,
    ip_address    INET,
    device_info   TEXT,
    details       JSONB,
    created_at    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    -- 新增：操作平台
    platform      VARCHAR(50),
    -- 新增：关联ID（比如支付记录ID）
    related_id    VARCHAR(255)
);
COMMENT ON TABLE user_activity_logs IS '用户操作审计日志';
COMMENT ON COLUMN user_activity_logs.details IS '操作详情，JSON格式';
COMMENT ON COLUMN user_activity_logs.platform IS '操作平台：Web/iOS/Android';
COMMENT ON COLUMN user_activity_logs.related_id IS '关联对象ID';

-- 创建领域事件表
CREATE TABLE domain_events
(
    id             SERIAL PRIMARY KEY,
    event_type     VARCHAR(100) NOT NULL,
    aggregate_type VARCHAR(50)  NOT NULL,
    aggregate_id   VARCHAR(255) NOT NULL,
    event_data     JSONB        NOT NULL,
    processed      BOOLEAN     DEFAULT FALSE,
    processed_at   TIMESTAMPTZ,
    -- 新增：发布者信息
    publisher      VARCHAR(100),
    -- 新增：事件版本
    event_version  VARCHAR(20),
    created_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP

);
COMMENT ON TABLE domain_events IS '存储领域事件，用于事件溯源和集成';
COMMENT ON COLUMN domain_events.event_type IS '事件类型';
COMMENT ON COLUMN domain_events.aggregate_type IS '聚合类型';
COMMENT ON COLUMN domain_events.aggregate_id IS '聚合ID';
COMMENT ON COLUMN domain_events.event_data IS '事件数据，JSON格式';
COMMENT ON COLUMN domain_events.processed IS '事件是否已处理';
COMMENT ON COLUMN domain_events.processed_at IS '事件处理时间';
COMMENT ON COLUMN domain_events.publisher IS '事件发布者';
COMMENT ON COLUMN domain_events.event_version IS '事件版本号';

-- 新增表：用户安全设置
CREATE TABLE user_security_settings
(
    id                      SERIAL PRIMARY KEY,
    user_id                 VARCHAR(255) UNIQUE NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    two_factor_auth_enabled BOOLEAN     DEFAULT FALSE,
    two_factor_auth_type    VARCHAR(20) DEFAULT 'none', -- none/sms/app
    pin_code_enabled        BOOLEAN     DEFAULT FALSE,
    biometric_auth_enabled  BOOLEAN     DEFAULT FALSE,
    session_timeout_minutes INT         DEFAULT 30,
    last_password_change    TIMESTAMPTZ,
    password_history        JSONB,
    created_at              TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE user_security_settings IS '用户安全设置';
COMMENT ON COLUMN user_security_settings.user_id IS '引用用户表的外部键';
COMMENT ON COLUMN user_security_settings.two_factor_auth_enabled IS '是否启用双因素认证';
COMMENT ON COLUMN user_security_settings.two_factor_auth_type IS '双因素认证类型';
COMMENT ON COLUMN user_security_settings.pin_code_enabled IS '是否启用PIN码';
COMMENT ON COLUMN user_security_settings.biometric_auth_enabled IS '是否启用生物认证';
COMMENT ON COLUMN user_security_settings.session_timeout_minutes IS '会话超时时间（分钟）';
COMMENT ON COLUMN user_security_settings.last_password_change IS '最后密码修改时间';
COMMENT ON COLUMN user_security_settings.password_history IS '密码历史记录';

-- 新增表：分享记录表
CREATE TABLE payment_shares
(
    id                SERIAL PRIMARY KEY,
    user_id           VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    payment_record_id INT REFERENCES payment_records (id),
    share_type        VARCHAR(20)  NOT NULL, -- pdf/link/email
    share_target      VARCHAR(255),
    share_link        TEXT,
    expiry_time       TIMESTAMPTZ,
    status            VARCHAR(20) DEFAULT 'active',
    created_at        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    platform          VARCHAR(50)
);
COMMENT ON TABLE payment_shares IS '支付记录分享信息';
COMMENT ON COLUMN payment_shares.user_id IS '引用用户表的外部键';
COMMENT ON COLUMN payment_shares.payment_record_id IS '引用支付记录表的外部键';
COMMENT ON COLUMN payment_shares.share_type IS '分享类型：pdf/link/email';
COMMENT ON COLUMN payment_shares.share_target IS '分享目标（如电子邮件地址）';
COMMENT ON COLUMN payment_shares.share_link IS '分享链接URL';
COMMENT ON COLUMN payment_shares.expiry_time IS '分享链接过期时间';
COMMENT ON COLUMN payment_shares.status IS '分享状态：active/expired/revoked';
COMMENT ON COLUMN payment_shares.platform IS '分享操作平台：Web/iOS/Android';

-- 新增表：支付分类视图（读模型）
CREATE TABLE payment_categories_view
(
    id             SERIAL PRIMARY KEY,
    category_id    INT UNIQUE   NOT NULL REFERENCES categories (id) ON DELETE CASCADE,
    user_id        VARCHAR(255) NOT NULL,
    name           VARCHAR(50)  NOT NULL,
    parent_name    VARCHAR(50),
    icon           VARCHAR(50),
    color          VARCHAR(20),
    is_system      BOOLEAN,
    total_payments INT            DEFAULT 0,
    total_amount   DECIMAL(12, 2) DEFAULT 0.00,
    updated_at     TIMESTAMPTZ    DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE payment_categories_view IS '支付分类视图，优化查询性能';
COMMENT ON COLUMN payment_categories_view.category_id IS '引用分类表的外部键';
COMMENT ON COLUMN payment_categories_view.user_id IS '用户ID';
COMMENT ON COLUMN payment_categories_view.name IS '分类名称';
COMMENT ON COLUMN payment_categories_view.parent_name IS '父分类名称';
COMMENT ON COLUMN payment_categories_view.icon IS '分类图标';
COMMENT ON COLUMN payment_categories_view.color IS '分类颜色';
COMMENT ON COLUMN payment_categories_view.is_system IS '是否为系统预设';
COMMENT ON COLUMN payment_categories_view.total_payments IS '该分类下的支付记录总数';
COMMENT ON COLUMN payment_categories_view.total_amount IS '该分类下的支付总金额';

-- 新增表：跨平台设置表
CREATE TABLE platform_settings
(
    id           SERIAL PRIMARY KEY,
    user_id      VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    platform     VARCHAR(50)  NOT NULL, -- web/ios/android
    settings     JSONB,
    device_id    VARCHAR(255),
    created_at   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_sync_at TIMESTAMPTZ
);
COMMENT ON TABLE platform_settings IS '用户跨平台设置';
COMMENT ON COLUMN platform_settings.user_id IS '引用用户表的外部键';
COMMENT ON COLUMN platform_settings.platform IS '平台类型：web/ios/android';
COMMENT ON COLUMN platform_settings.settings IS '平台特定设置，JSON格式';
COMMENT ON COLUMN platform_settings.device_id IS '设备ID';
COMMENT ON COLUMN platform_settings.last_sync_at IS '最后同步时间';

-- 索引优化
CREATE INDEX idx_users_user_id ON users (user_id);
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_phone ON users (phone);
CREATE INDEX idx_login_history_user ON login_history (user_id);
CREATE INDEX idx_login_history_time ON login_history (login_time);
CREATE INDEX idx_login_history_platform ON login_history (platform);
CREATE INDEX idx_payment_methods_user ON payment_methods (user_id);
CREATE INDEX idx_payment_methods_type ON payment_methods (type);
CREATE INDEX idx_reminder_settings_user ON reminder_settings (user_id);
CREATE INDEX idx_reminder_settings_trigger ON reminder_settings (next_trigger_at);
CREATE INDEX idx_categories_user ON categories (user_id);
CREATE INDEX idx_categories_parent ON categories (parent_id);
CREATE INDEX idx_analysis_results_user ON analysis_results (user_id);
CREATE INDEX idx_analysis_results_type ON analysis_results (analysis_type);
CREATE INDEX idx_payment_records_user ON payment_records (user_id);
CREATE INDEX idx_payment_records_date ON payment_records (payment_date);
CREATE INDEX idx_payment_records_category ON payment_records (category_id);
CREATE INDEX idx_payment_records_merchant ON payment_records (merchant);
CREATE INDEX idx_payment_records_method ON payment_records (payment_method_id);
CREATE INDEX idx_payment_records_status ON payment_records (payment_status);
CREATE INDEX idx_payment_records_tags ON payment_records USING GIN (tags);
CREATE INDEX idx_payment_records_platform ON payment_records (platform);
CREATE INDEX idx_sync_tasks_user ON payment_sync_tasks (user_id);
CREATE INDEX idx_sync_tasks_next_sync ON payment_sync_tasks (next_sync_at);
CREATE INDEX idx_uploads_user ON payment_uploads (user_id);
CREATE INDEX idx_uploads_status ON payment_uploads (status);
CREATE INDEX idx_uploads_platform ON payment_uploads (platform);
CREATE INDEX idx_analyses_user ON analyses (user_id);
CREATE INDEX idx_analyses_type ON analyses (type);
CREATE INDEX idx_exports_user ON exports (user_id);
CREATE INDEX idx_exports_status ON exports (status);
CREATE INDEX idx_exports_is_shared ON exports (is_shared);
CREATE INDEX idx_exports_platform ON exports (platform);
CREATE INDEX idx_user_stats_user ON user_account_stats (user_id);
CREATE INDEX idx_payment_list_user ON payment_records_list (user_id);
CREATE INDEX idx_payment_list_date ON payment_records_list (payment_date);
CREATE INDEX idx_payment_list_category_id ON payment_records_list (category_id);
CREATE INDEX idx_payment_list_tags ON payment_records_list USING GIN (tags);
CREATE INDEX idx_analysis_data_user ON analysis_data (user_id);
CREATE INDEX idx_analysis_data_type ON analysis_data (type);
CREATE INDEX idx_reminders_list_user ON reminders_list (user_id);
CREATE INDEX idx_reminders_list_date ON reminders_list (reminder_date);
CREATE INDEX idx_reminders_list_notification ON reminders_list (notification_type);
CREATE INDEX idx_activity_logs_user ON user_activity_logs (user_id);
CREATE INDEX idx_activity_logs_type ON user_activity_logs (activity_type);
CREATE INDEX idx_activity_logs_platform ON user_activity_logs (platform);
CREATE INDEX idx_activity_logs_related_id ON user_activity_logs (related_id);
CREATE INDEX idx_domain_events_type ON domain_events (event_type);
CREATE INDEX idx_domain_events_aggregate ON domain_events (aggregate_type, aggregate_id);
CREATE INDEX idx_domain_events_processed ON domain_events (processed);
CREATE INDEX idx_payment_images_user ON payment_images (user_id);
CREATE INDEX idx_payment_images_status ON payment_images (status);
CREATE INDEX idx_payment_images_upload_time ON payment_images (upload_time);
CREATE INDEX idx_payment_images_platform ON payment_images (platform);
CREATE INDEX idx_payment_images_list_user ON payment_images_list (user_id);
CREATE INDEX idx_payment_images_list_upload_time ON payment_images_list (upload_time);
CREATE INDEX idx_payment_records_image ON payment_records (image_id);
CREATE INDEX idx_user_security_user_id ON user_security_settings (user_id);
CREATE INDEX idx_payment_shares_user ON payment_shares (user_id);
CREATE INDEX idx_payment_shares_record ON payment_shares (payment_record_id);
CREATE INDEX idx_payment_shares_status ON payment_shares (status);
CREATE INDEX idx_payment_shares_platform ON payment_shares (platform);
CREATE INDEX idx_payment_categories_user ON payment_categories_view (user_id);
CREATE INDEX idx_platform_settings_user ON platform_settings (user_id);
CREATE INDEX idx_platform_settings_platform ON platform_settings (platform);

-- 触发器：更新updated_at字段的函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为所有需要的表添加触发器
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE
    ON users
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_methods_updated_at
    BEFORE UPDATE
    ON payment_methods
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reminder_settings_updated_at
    BEFORE UPDATE
    ON reminder_settings
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE
    ON categories
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ai_providers_updated_at
    BEFORE UPDATE
    ON ai_providers
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_api_services_updated_at
    BEFORE UPDATE
    ON api_services
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_analysis_results_updated_at
    BEFORE UPDATE
    ON analysis_results
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_api_weights_updated_at
    BEFORE UPDATE
    ON api_weights
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_records_updated_at
    BEFORE UPDATE
    ON payment_records
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_sync_tasks_updated_at
    BEFORE UPDATE
    ON payment_sync_tasks
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_uploads_updated_at
    BEFORE UPDATE
    ON payment_uploads
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_analyses_updated_at
    BEFORE UPDATE
    ON analyses
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reminders_updated_at
    BEFORE UPDATE
    ON reminders
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exports_updated_at
    BEFORE UPDATE
    ON exports
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_account_stats_updated_at
    BEFORE UPDATE
    ON user_account_stats
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_records_list_updated_at
    BEFORE UPDATE
    ON payment_records_list
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_analysis_data_updated_at
    BEFORE UPDATE
    ON analysis_data
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reminders_list_updated_at
    BEFORE UPDATE
    ON reminders_list
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_images_updated_at
    BEFORE UPDATE
    ON payment_images
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_images_list_updated_at
    BEFORE UPDATE
    ON payment_images_list
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_security_settings_updated_at
    BEFORE UPDATE
    ON user_security_settings
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_shares_updated_at
    BEFORE UPDATE
    ON payment_shares
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_categories_view_updated_at
    BEFORE UPDATE
    ON payment_categories_view
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_platform_settings_updated_at
    BEFORE UPDATE
    ON platform_settings
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 创建分析结果全文检索索引
CREATE INDEX idx_analysis_results_input_tsv ON analysis_results USING GIN (to_tsvector('english', input_data));


