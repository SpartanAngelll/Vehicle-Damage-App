-- Initial database schema
-- Migration: 20240101000000_initial_schema.sql

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Users table (main user profiles)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firebase_uid VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(20),
    full_name VARCHAR(255),
    display_name VARCHAR(255),
    profile_photo_url TEXT,
    role VARCHAR(50) NOT NULL CHECK (role IN ('owner', 'repairman', 'serviceProfessional')),
    bio TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fcm_token TEXT,
    last_token_update TIMESTAMP WITH TIME ZONE,
    metadata JSONB
);

-- Service professionals extended profile
CREATE TABLE IF NOT EXISTS service_professionals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    business_name VARCHAR(255),
    business_address TEXT,
    business_phone VARCHAR(20),
    website VARCHAR(255),
    years_of_experience INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    total_reviews INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    service_areas TEXT[],
    specializations TEXT[],
    certifications TEXT[],
    service_category_ids TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Service categories
CREATE TABLE IF NOT EXISTS service_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    icon_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Job requests
CREATE TABLE IF NOT EXISTS job_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    service_category_id UUID NOT NULL REFERENCES service_categories(id),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    location TEXT NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    budget_min DECIMAL(10, 2),
    budget_max DECIMAL(10, 2),
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    media_urls TEXT[],
    important_points TEXT[],
    preferred_date DATE,
    preferred_time TIME,
    is_urgent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Estimates
CREATE TABLE IF NOT EXISTS estimates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_request_id UUID NOT NULL REFERENCES job_requests(id) ON DELETE CASCADE,
    professional_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'JMD',
    estimated_duration_hours INTEGER,
    deliverables TEXT[],
    important_points TEXT[],
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
    valid_until TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Bookings
CREATE TABLE IF NOT EXISTS bookings (
    id VARCHAR(255) PRIMARY KEY,
    estimate_id UUID REFERENCES estimates(id) ON DELETE SET NULL,
    chat_room_id UUID,
    customer_id VARCHAR(255) NOT NULL,
    professional_id VARCHAR(255) NOT NULL,
    customer_name VARCHAR(255) NOT NULL,
    professional_name VARCHAR(255) NOT NULL,
    service_title VARCHAR(255) NOT NULL,
    service_description TEXT NOT NULL,
    agreed_price DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'JMD',
    scheduled_start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    scheduled_end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    service_location TEXT NOT NULL,
    deliverables TEXT[],
    important_points TEXT[],
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'on_my_way', 'in_progress', 'started', 'completed', 'cancelled', 'disputed', 'reviewed')),
    notes TEXT,
    start_pin_hash VARCHAR(255),
    status_notes TEXT,
    on_my_way_at TIMESTAMP WITH TIME ZONE,
    job_started_at TIMESTAMP WITH TIME ZONE,
    job_completed_at TIMESTAMP WITH TIME ZONE,
    job_accepted_at TIMESTAMP WITH TIME ZONE,
    travel_mode VARCHAR(20) CHECK (travel_mode IN ('customer_location', 'shop_location')),
    customer_address TEXT,
    shop_address TEXT,
    travel_fee DECIMAL(10, 2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Chat rooms (metadata only, actual chat in Firestore)
CREATE TABLE IF NOT EXISTS chat_rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id VARCHAR(255) REFERENCES bookings(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    professional_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    last_message_at TIMESTAMP WITH TIME ZONE,
    last_message_text TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Chat messages (metadata only, actual messages in Firestore)
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message_text TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'system')),
    media_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Invoices
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id VARCHAR(255) NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    professional_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    total_amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'JMD',
    deposit_percentage INTEGER DEFAULT 0,
    deposit_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    balance_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'paid', 'overdue', 'cancelled')),
    sent_at TIMESTAMP WITH TIME ZONE,
    due_date TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Payment records
CREATE TABLE IF NOT EXISTS payment_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
    booking_id VARCHAR(255) NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('deposit', 'balance', 'full', 'refund')),
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'JMD',
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'paid', 'failed', 'cancelled')),
    payment_method VARCHAR(50),
    transaction_id VARCHAR(255),
    processed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    deposit_percentage INTEGER DEFAULT 0,
    total_amount DECIMAL(10, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Payment status history
CREATE TABLE IF NOT EXISTS payment_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_id UUID NOT NULL REFERENCES payment_records(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(255),
    notes TEXT
);

-- Payment confirmations
CREATE TABLE IF NOT EXISTS payment_confirmations (
    booking_id VARCHAR(255) PRIMARY KEY REFERENCES bookings(id) ON DELETE CASCADE,
    professional_id VARCHAR(255) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    confirmed_at TIMESTAMP WITH TIME ZONE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Professional balances
CREATE TABLE IF NOT EXISTS professional_balances (
    professional_id VARCHAR(255) PRIMARY KEY,
    available_balance DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total_earned DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total_paid_out DECIMAL(10, 2) NOT NULL DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Payouts
CREATE TABLE IF NOT EXISTS payouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    professional_id VARCHAR(255) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'JMD',
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'success', 'failed', 'cancelled')),
    payment_processor_transaction_id VARCHAR(255),
    payment_processor_response JSONB,
    completed_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Service packages
CREATE TABLE IF NOT EXISTS service_packages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    professional_id VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'JMD',
    duration_minutes INTEGER NOT NULL,
    is_starting_from BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    priority VARCHAR(20) NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'read', 'failed')),
    data JSONB,
    action_buttons JSONB,
    scheduled_for TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    fcm_message_id VARCHAR(255),
    sendgrid_message_id VARCHAR(255),
    method VARCHAR(20) CHECK (method IN ('fcm', 'email', 'sms')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Notification templates
CREATE TABLE IF NOT EXISTS notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_type VARCHAR(50) NOT NULL UNIQUE,
    title_template TEXT NOT NULL,
    body_template TEXT NOT NULL,
    default_data JSONB,
    default_action_buttons JSONB,
    default_priority VARCHAR(20) NOT NULL DEFAULT 'normal',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Notification channels
CREATE TABLE IF NOT EXISTS notification_channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id VARCHAR(100) NOT NULL UNIQUE,
    channel_name VARCHAR(255) NOT NULL,
    description TEXT,
    importance_level INTEGER DEFAULT 3,
    enable_vibration BOOLEAN DEFAULT TRUE,
    enable_sound BOOLEAN DEFAULT TRUE,
    sound_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Notification preferences
CREATE TABLE IF NOT EXISTS notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL,
    enabled BOOLEAN DEFAULT TRUE,
    email_enabled BOOLEAN DEFAULT TRUE,
    push_enabled BOOLEAN DEFAULT TRUE,
    sms_enabled BOOLEAN DEFAULT FALSE,
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    timezone VARCHAR(50) DEFAULT 'UTC',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB,
    UNIQUE(user_id, notification_type)
);

-- Email notifications
CREATE TABLE IF NOT EXISTS email_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    to_email VARCHAR(255) NOT NULL,
    to_name VARCHAR(255),
    subject TEXT NOT NULL,
    html_content TEXT,
    text_content TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'failed', 'bounced')),
    sendgrid_message_id VARCHAR(255),
    error_message TEXT,
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Reviews
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id VARCHAR(255) NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    reviewer_id VARCHAR(255) NOT NULL,
    reviewee_id VARCHAR(255) NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(255),
    comment TEXT,
    is_public BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- System settings
CREATE TABLE IF NOT EXISTS system_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    setting_key VARCHAR(255) NOT NULL UNIQUE,
    setting_value TEXT NOT NULL,
    data_type VARCHAR(20) DEFAULT 'string' CHECK (data_type IN ('string', 'number', 'boolean', 'json')),
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Audit logs
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

