-- =================================================================
-- AI Payment Result Recognition Bounded Context
-- Database Initialization Script
--
-- Target RDBMS: PostgreSQL
-- Author: AI Assistant
-- Created on: 2025-07-03
--
-- This script is generated based on the domain model defined in:
-- doc/domain-puml/ai_analysis_context.puml
-- =================================================================

-- Drop existing objects if they exist to ensure a clean setup
DROP TABLE IF EXISTS user_confirmations;
DROP TABLE IF EXISTS image_analysis_attempts;
DROP TABLE IF EXISTS payment_images;
DROP TYPE IF EXISTS analysis_status;
DROP TYPE IF EXISTS confirmation_type;


-- =============================================
-- Enums for State and Type
-- =============================================

-- Represents the status of an AI analysis attempt.
CREATE TYPE analysis_status AS ENUM (
    'PENDING_ANALYSIS',
    'ANALYZING',
    'ANALYSIS_SUCCEEDED',
    'ANALYSIS_FAILED',
    'PENDING_CONFIRMATION',
    'CONFIRMED',
    'REJECTED'
);

-- Represents the type of user confirmation for an analysis result.
CREATE TYPE confirmation_type AS ENUM (
    'ACCEPTED',
    'MODIFIED',
    'REJECTED'
);


-- =============================================
-- Core Tables
-- =============================================

--
-- Table: payment_images
-- Stores basic information about uploaded payment images.
-- Corresponds to the PaymentImageAgg aggregate root.
--
CREATE TABLE payment_images (
    payment_image_id UUID PRIMARY KEY,
    uploader_id UUID NOT NULL,
    image_url VARCHAR(2048) NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE payment_images IS 'Stores metadata for uploaded payment images, acting as the entry point for the analysis process.';
COMMENT ON COLUMN payment_images.payment_image_id IS 'Primary key, unique identifier for the payment image.';
COMMENT ON COLUMN payment_images.uploader_id IS 'Identifier of the user who uploaded the image.';
COMMENT ON COLUMN payment_images.image_url IS 'URL where the uploaded image is stored.';
COMMENT ON COLUMN payment_images.uploaded_at IS 'Timestamp when the image was originally uploaded.';


--
-- Table: image_analysis_attempts
-- Records each attempt to analyze a payment image using AI.
-- Corresponds to the ImageAnalysisAttemptAgg aggregate root.
--
CREATE TABLE image_analysis_attempts (
    attempt_id UUID PRIMARY KEY,
    payment_image_id UUID NOT NULL REFERENCES payment_images(payment_image_id),
    status analysis_status NOT NULL,
    ai_context JSONB,
    raw_analysis_result TEXT,
    parsed_payment_details JSONB,
    failure_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE image_analysis_attempts IS 'Core table tracking each individual AI analysis attempt for a payment image.';
COMMENT ON COLUMN image_analysis_attempts.attempt_id IS 'Primary key, unique identifier for a single analysis attempt.';
COMMENT ON COLUMN image_analysis_attempts.payment_image_id IS 'Foreign key linking to the payment image being analyzed.';
COMMENT ON COLUMN image_analysis_attempts.status IS 'The current status of the analysis attempt (e.g., PENDING, SUCCEEDED, FAILED).';
COMMENT ON COLUMN image_analysis_attempts.ai_context IS 'Stores AI invocation details like model name, prompt version, and timestamps. Maps to AIInvocationContext VO.';
COMMENT ON COLUMN image_analysis_attempts.raw_analysis_result IS 'The raw, unprocessed result returned by the AI model.';
COMMENT ON COLUMN image_analysis_attempts.parsed_payment_details IS 'Structured payment data extracted from the raw result. Maps to ParsedPaymentDetails VO.';
COMMENT ON COLUMN image_analysis_attempts.failure_reason IS 'Records the reason for failure if the analysis did not succeed.';


--
-- Table: user_confirmations
-- Stores the user''s final confirmation of an analysis result.
-- Corresponds to the UserConfirmation entity.
--
CREATE TABLE user_confirmations (
    confirmation_id UUID PRIMARY KEY,
    attempt_id UUID NOT NULL REFERENCES image_analysis_attempts(attempt_id),
    confirmed_by UUID NOT NULL,
    confirmed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    confirmation_type confirmation_type NOT NULL,
    corrected_details JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE user_confirmations IS 'Stores the user''s final decision on the accuracy of an AI analysis attempt.';
COMMENT ON COLUMN user_confirmations.confirmation_id IS 'Primary key, unique identifier for the confirmation record.';
COMMENT ON COLUMN user_confirmations.attempt_id IS 'Foreign key linking to the specific analysis attempt being confirmed.';
COMMENT ON COLUMN user_confirmations.confirmed_by IS 'Identifier of the user who provided the confirmation.';
COMMENT ON COLUMN user_confirmations.confirmation_type IS 'The type of confirmation (e.g., ACCEPTED, MODIFIED, REJECTED).';
COMMENT ON COLUMN user_confirmations.corrected_details IS 'If the user modified the result, this field stores the corrected data. Maps to ParsedPaymentDetails VO.';


-- =============================================
-- Indexes for Performance
-- =============================================
CREATE INDEX idx_image_analysis_attempts_payment_image_id ON image_analysis_attempts(payment_image_id);
CREATE INDEX idx_user_confirmations_attempt_id ON user_confirmations(attempt_id);

-- =============================================
-- Triggers for updated_at timestamp
-- =============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_payment_images_updated_at
BEFORE UPDATE ON payment_images
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_image_analysis_attempts_updated_at
BEFORE UPDATE ON image_analysis_attempts
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_confirmations_updated_at
BEFORE UPDATE ON user_confirmations
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- =================================================================
-- End of Script
-- =================================================================