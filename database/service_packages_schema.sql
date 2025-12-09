-- Service Packages Schema Migration
-- This adds support for pre-priced service packages that professionals can create and manage
-- Run this after the main schema is set up

-- Connect to the database
\c vehicle_damage_payments;

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================
-- SERVICE PACKAGES TABLE
-- ==============================================

-- Service packages table for pre-priced services
CREATE TABLE IF NOT EXISTS service_packages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    professional_id VARCHAR(255) NOT NULL, -- Firebase UID of the professional
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'JMD',
    duration_minutes INTEGER NOT NULL, -- Duration in minutes
    is_starting_from BOOLEAN DEFAULT FALSE, -- If true, price is "starting from"
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0, -- For custom ordering
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB -- For additional flexible data
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_service_packages_professional_id ON service_packages(professional_id);
CREATE INDEX IF NOT EXISTS idx_service_packages_is_active ON service_packages(is_active);
CREATE INDEX IF NOT EXISTS idx_service_packages_professional_active ON service_packages(professional_id, is_active);

-- Add comment
COMMENT ON TABLE service_packages IS 'Pre-priced service packages that professionals can create and customers can book directly';


