-- 触发器：更新updated_at字段的函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 创建用户表 (UserAgg)
CREATE TABLE users
(
    id                       VARCHAR(26) PRIMARY KEY,
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

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE
    ON users
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 创建支付方式表 (UserAgg的一部分)
CREATE TABLE payment_methods
(
    id            VARCHAR(26) PRIMARY KEY,
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

CREATE TRIGGER update_payment_methods_updated_at
    BEFORE UPDATE
    ON payment_methods
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- 创建AI提供商表
CREATE TABLE ai_providers
(
    id          VARCHAR(26) PRIMARY KEY,
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

CREATE TRIGGER update_ai_providers_updated_at
    BEFORE UPDATE
    ON ai_providers
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 创建API服务表
CREATE TABLE api_services
(
    id          VARCHAR(26) PRIMARY KEY,
    provider_id VARCHAR(26) REFERENCES ai_providers (id) ON DELETE CASCADE,
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

CREATE TRIGGER update_api_services_updated_at
    BEFORE UPDATE
    ON api_services
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE analysis_results
(
    id                VARCHAR(26) PRIMARY KEY,
    user_id           VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    service_id        VARCHAR(26) REFERENCES api_services (id),
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

CREATE TRIGGER update_analysis_results_updated_at
    BEFORE UPDATE
    ON analysis_results
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
CREATE INDEX idx_analysis_results_input_tsv ON analysis_results USING GIN (to_tsvector('english', input_data));

-- 创建分类体系表
CREATE TABLE categories
(
    id             VARCHAR(26) PRIMARY KEY,
    user_id        VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    name           VARCHAR(50)  NOT NULL,
    parent_id      VARCHAR(26) REFERENCES categories (id),
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

CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE
    ON categories
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 创建支付凭证图像表 (PaymentImageAgg)
CREATE TABLE payment_images
(
    id                    VARCHAR(26) PRIMARY KEY,
    user_id               VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    image_file_url        TEXT         NOT NULL,
    upload_time           TIMESTAMPTZ  NOT NULL,
    analysis_id           VARCHAR(255) REFERENCES analyses (id) ON DELETE CASCADE,
    status                VARCHAR(20) DEFAULT 'NOT_APPLICABLE' CHECK (status IN
                                                                      ('UPLOADED', 'ANALYZING',
                                                                       'ANALYZED', 'FAILED',
                                                                       'NOT_APPLICABLE')),
    created_at            TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    unique_hash           VARCHAR(64),
    -- 新增：记录上传平台信息
    platform              VARCHAR(50),
    -- 新增：图像处理元数据
    metadata              JSONB,
    CONSTRAINT unique_payment_image_hash UNIQUE (unique_hash)

);
COMMENT ON TABLE payment_images IS '支付凭证图像聚合根表';
COMMENT ON COLUMN payment_images.id IS '自增主键';
COMMENT ON COLUMN payment_images.user_id IS '业务生成的用户唯一标识';
COMMENT ON COLUMN payment_images.image_file_url IS '图像文件路径或URL';
COMMENT ON COLUMN payment_images.upload_time IS '上传时间';
COMMENT ON COLUMN payment_images.analysis_id IS '解析结果的外键';
COMMENT ON COLUMN payment_images.status IS '处理状态: pending/processing/success/failed';
COMMENT ON COLUMN payment_images.created_at IS '创建时间';
COMMENT ON COLUMN payment_images.updated_at IS '最后更新时间';
COMMENT ON COLUMN payment_images.platform IS '上传平台：Web/iOS/Android';
COMMENT ON COLUMN payment_images.unique_hash IS '取图片hash，快速判断图片是否上传过';
COMMENT ON COLUMN payment_images.metadata IS '图像处理元数据';

CREATE TRIGGER update_payment_images_updated_at
    BEFORE UPDATE
    ON payment_images
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 创建支付记录表 (PaymentRecordAgg)
CREATE TABLE payment_records
(
    id                 VARCHAR(26) PRIMARY KEY,
    user_id            VARCHAR(255)   NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    payment_method_id  VARCHAR(26) REFERENCES payment_methods (id),
    amount             DECIMAL(10, 2) NOT NULL,
    payment_date       TIMESTAMPTZ    NOT NULL,
    merchant           VARCHAR(255),
    category_id        VARCHAR(26) REFERENCES categories (id),
    image_id           VARCHAR(26) REFERENCES payment_images (id),
    analysis_result_id VARCHAR(26) REFERENCES analysis_results (id),
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

CREATE TRIGGER update_payment_records_updated_at
    BEFORE UPDATE
    ON payment_records
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- 创建图片上传记录表
CREATE TABLE payment_uploads
(
    id                 VARCHAR(26) PRIMARY KEY,
    user_id            VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    file_path          TEXT         NOT NULL,
    status             VARCHAR(20) DEFAULT 'pending',
    analysis_result_id varchar(26) REFERENCES analysis_results (id),
    created_at         TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    platform           VARCHAR(50)
);
COMMENT ON TABLE payment_uploads IS '支付凭证图片上传记录';
COMMENT ON COLUMN payment_uploads.status IS '处理状态: pending/processing/success/failed';
COMMENT ON COLUMN payment_uploads.created_at IS '创建时间';
COMMENT ON COLUMN payment_uploads.updated_at IS '最后更新时间';
COMMENT ON COLUMN payment_uploads.platform IS '上传平台：Web/iOS/Android';

-- 创建领域事件表
CREATE TABLE domain_events
(
    id             VARCHAR(26) PRIMARY KEY,
    event_type     VARCHAR(100) NOT NULL,
    aggregate_type VARCHAR(127) NOT NULL,
    aggregate_id   VARCHAR(255) NOT NULL,
    event_data     JSONB        NOT NULL,
    processed      BOOLEAN     DEFAULT FALSE,
    processed_at   TIMESTAMPTZ,
    -- 新增：发布者信息
    publisher      VARCHAR(127),
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

-- 创建分析表 (AnalyticsAgg)
CREATE TABLE analyses
(
    id                 VARCHAR(26) PRIMARY KEY,
    user_id            VARCHAR(255) NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    analysis_result_id VARCHAR(26) REFERENCES analysis_results (id) ON DELETE CASCADE,
    type               VARCHAR(50)  NOT NULL,
    data               JSONB,
    created_at         TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    -- 新增：分析参数和时间范围
    params             JSONB,
    time_range         JSONB,
    -- 新增：是否为系统自动生成
    auto_generated     BOOLEAN     DEFAULT FALSE,
    -- 新增：分析状态
    status             VARCHAR(20) DEFAULT 'pending',
    -- 新增：分析版本
    version            VARCHAR(20),
    -- 新增：分析摘要
    summary            TEXT
);
COMMENT ON TABLE analyses IS '分析聚合根表-强调和用户相关的';
COMMENT ON COLUMN analyses.type IS '分析类型（如趋势分析、类别分析、支付方式分析）';
COMMENT ON COLUMN analyses.analysis_result_id IS 'resultId 强调和 AI 分析过程相关';
COMMENT ON COLUMN analyses.created_at IS '创建时间';
COMMENT ON COLUMN analyses.updated_at IS '最后更新时间';
COMMENT ON COLUMN analyses.params IS '分析参数，JSON格式';
COMMENT ON COLUMN analyses.time_range IS '分析时间范围，JSON格式';
COMMENT ON COLUMN analyses.auto_generated IS '是否为系统自动生成的分析';
COMMENT ON COLUMN analyses.status IS '分析状态';
COMMENT ON COLUMN analyses.version IS '分析版本';
COMMENT ON COLUMN analyses.summary IS '分析摘要';

CREATE TRIGGER update_analyses_updated_at
    BEFORE UPDATE
    ON analyses
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 索引优化
CREATE INDEX idx_users_user_id ON users (user_id);
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_phone ON users (phone);
-- CREATE INDEX idx_login_history_user ON login_history (user_id);
-- CREATE INDEX idx_login_history_time ON login_history (login_time);
-- CREATE INDEX idx_login_history_platform ON login_history (platform);
CREATE INDEX idx_payment_methods_user ON payment_methods (user_id);
CREATE INDEX idx_payment_methods_type ON payment_methods (type);
-- CREATE INDEX idx_reminder_settings_user ON reminder_settings (user_id);
-- CREATE INDEX idx_reminder_settings_trigger ON reminder_settings (next_trigger_at);
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
-- CREATE INDEX idx_sync_tasks_user ON payment_sync_tasks (user_id);
-- CREATE INDEX idx_sync_tasks_next_sync ON payment_sync_tasks (next_sync_at);
-- CREATE INDEX idx_uploads_user ON payment_uploads (user_id);
-- CREATE INDEX idx_uploads_status ON payment_uploads (status);
-- CREATE INDEX idx_uploads_platform ON payment_uploads (platform);
CREATE INDEX idx_analyses_user ON analyses (user_id);
CREATE INDEX idx_analyses_type ON analyses (type);
-- CREATE INDEX idx_exports_user ON exports (user_id);
-- CREATE INDEX idx_exports_status ON exports (status);
-- CREATE INDEX idx_exports_is_shared ON exports (is_shared);
-- CREATE INDEX idx_exports_platform ON exports (platform);
-- CREATE INDEX idx_user_stats_user ON user_account_stats (user_id);
-- CREATE INDEX idx_payment_list_user ON payment_records_list (user_id);
-- CREATE INDEX idx_payment_list_date ON payment_records_list (payment_date);
-- CREATE INDEX idx_payment_list_category_id ON payment_records_list (category_id);
-- CREATE INDEX idx_payment_list_tags ON payment_records_list USING GIN (tags);
-- CREATE INDEX idx_analysis_data_user ON analysis_data (user_id);
-- CREATE INDEX idx_analysis_data_type ON analysis_data (type);
-- CREATE INDEX idx_reminders_list_user ON reminders_list (user_id);
-- CREATE INDEX idx_reminders_list_date ON reminders_list (reminder_date);
-- CREATE INDEX idx_reminders_list_notification ON reminders_list (notification_type);
-- CREATE INDEX idx_activity_logs_user ON user_activity_logs (user_id);
-- CREATE INDEX idx_activity_logs_type ON user_activity_logs (activity_type);
-- CREATE INDEX idx_activity_logs_platform ON user_activity_logs (platform);
-- CREATE INDEX idx_activity_logs_related_id ON user_activity_logs (related_id);
CREATE INDEX idx_domain_events_type ON domain_events (event_type);
CREATE INDEX idx_domain_events_aggregate ON domain_events (aggregate_type, aggregate_id);
CREATE INDEX idx_domain_events_processed ON domain_events (processed);
CREATE INDEX idx_payment_images_user ON payment_images (user_id);
CREATE INDEX idx_payment_images_status ON payment_images (status);
CREATE INDEX idx_payment_images_upload_time ON payment_images (upload_time);
CREATE INDEX idx_payment_images_platform ON payment_images (platform);
-- CREATE INDEX idx_payment_images_list_user ON payment_images_list (user_id);
-- CREATE INDEX idx_payment_images_list_upload_time ON payment_images_list (upload_time);
CREATE INDEX idx_payment_records_image ON payment_records (image_id);
-- CREATE INDEX idx_user_security_user_id ON user_security_settings (user_id);
-- CREATE INDEX idx_payment_shares_user ON payment_shares (user_id);
-- CREATE INDEX idx_payment_shares_record ON payment_shares (payment_record_id);
-- CREATE INDEX idx_payment_shares_status ON payment_shares (status);
-- CREATE INDEX idx_payment_shares_platform ON payment_shares (platform);
-- CREATE INDEX idx_payment_categories_user ON payment_categories_view (user_id);
-- CREATE INDEX idx_platform_settings_user ON platform_settings (user_id);
-- CREATE INDEX idx_platform_settings_platform ON platform_settings (platform);
