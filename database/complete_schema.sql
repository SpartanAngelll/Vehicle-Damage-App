-- Complete Database Schema for Vehicle Damage App
-- This includes all tables needed for full functionality including notifications, email service, and all app features

-- Connect to the database
\c vehicle_damage_payments;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ==============================================
-- CORE USER AND AUTHENTICATION TABLES
-- ==============================================

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
    service_areas TEXT[], -- Array of service area names
    specializations TEXT[], -- Array of specialization keywords
    certifications TEXT[], -- Array of certification names
    service_category_ids TEXT[], -- Array of service category IDs
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- ==============================================
-- SERVICE CATEGORIES AND REQUESTS
-- ==============================================

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

-- Job requests (replaces damage reports for multi-category support)
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
    media_urls TEXT[], -- Array of media file URLs
    important_points TEXT[], -- Array of important points
    preferred_date DATE,
    preferred_time TIME,
    is_urgent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- ==============================================
-- ESTIMATES AND BOOKINGS
-- ==============================================

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
    deliverables TEXT[], -- Array of deliverables
    important_points TEXT[], -- Array of important points
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
    valid_until TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Bookings
CREATE TABLE IF NOT EXISTS bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    estimate_id UUID NOT NULL REFERENCES estimates(id) ON DELETE CASCADE,
    chat_room_id UUID NOT NULL,
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    professional_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    customer_name VARCHAR(255) NOT NULL,
    professional_name VARCHAR(255) NOT NULL,
    service_title VARCHAR(255) NOT NULL,
    service_description TEXT NOT NULL,
    agreed_price DECIMAL(10, 2) NOT NULL,
    scheduled_start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    scheduled_end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    location TEXT NOT NULL,
    deliverables TEXT[],
    important_points TEXT[],
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'on_my_way', 'in_progress', 'completed', 'cancelled', 'disputed')),
    notes TEXT,
    customer_pin VARCHAR(10),
    status_notes TEXT,
    confirmed_at TIMESTAMP WITH TIME ZONE,
    on_my_way_at TIMESTAMP WITH TIME ZONE,
    job_started_at TIMESTAMP WITH TIME ZONE,
    job_completed_at TIMESTAMP WITH TIME ZONE,
    job_accepted_at TIMESTAMP WITH TIME ZONE,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    travel_mode VARCHAR(20) CHECK (travel_mode IN ('customer_location', 'shop_location')),
    customer_address TEXT,
    shop_address TEXT,
    travel_fee DECIMAL(10, 2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- ==============================================
-- CHAT AND MESSAGING
-- ==============================================

-- Chat rooms
CREATE TABLE IF NOT EXISTS chat_rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    professional_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    last_message_at TIMESTAMP WITH TIME ZONE,
    last_message_text TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Chat messages
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

-- ==============================================
-- PAYMENT AND INVOICING
-- ==============================================

-- Invoices
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
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
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('deposit', 'balance', 'full', 'refund')),
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'JMD',
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
    payment_method VARCHAR(50),
    transaction_id VARCHAR(255),
    processed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Payment status history
CREATE TABLE IF NOT EXISTS payment_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_record_id UUID NOT NULL REFERENCES payment_records(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- ==============================================
-- CASH-OUT AND EARNINGS
-- ==============================================

-- Professional balances
CREATE TABLE IF NOT EXISTS professional_balances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    professional_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    available_balance DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total_earned DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total_paid_out DECIMAL(10, 2) NOT NULL DEFAULT 0,
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Payouts
CREATE TABLE IF NOT EXISTS payouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    professional_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'JMD',
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
    payment_processor_transaction_id VARCHAR(255),
    payment_processor_response JSONB,
    completed_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Payout status history
CREATE TABLE IF NOT EXISTS payout_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payout_id UUID NOT NULL REFERENCES payouts(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- ==============================================
-- NOTIFICATION SYSTEM
-- ==============================================

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

-- Email notifications log
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

-- ==============================================
-- REVIEWS AND RATINGS
-- ==============================================

-- Reviews
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reviewee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(255),
    comment TEXT,
    is_public BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- ==============================================
-- SYSTEM AND AUDIT TABLES
-- ==============================================

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

-- ==============================================
-- INDEXES FOR PERFORMANCE
-- ==============================================

-- User indexes
CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);

-- Service professional indexes
CREATE INDEX IF NOT EXISTS idx_service_professionals_user_id ON service_professionals(user_id);
CREATE INDEX IF NOT EXISTS idx_service_professionals_available ON service_professionals(is_available);
CREATE INDEX IF NOT EXISTS idx_service_professionals_rating ON service_professionals(average_rating);

-- Job request indexes
CREATE INDEX IF NOT EXISTS idx_job_requests_customer_id ON job_requests(customer_id);
CREATE INDEX IF NOT EXISTS idx_job_requests_category_id ON job_requests(service_category_id);
CREATE INDEX IF NOT EXISTS idx_job_requests_status ON job_requests(status);
CREATE INDEX IF NOT EXISTS idx_job_requests_created_at ON job_requests(created_at);
CREATE INDEX IF NOT EXISTS idx_job_requests_location ON job_requests USING GIST (ll_to_earth(latitude, longitude));

-- Estimate indexes
CREATE INDEX IF NOT EXISTS idx_estimates_job_request_id ON estimates(job_request_id);
CREATE INDEX IF NOT EXISTS idx_estimates_professional_id ON estimates(professional_id);
CREATE INDEX IF NOT EXISTS idx_estimates_status ON estimates(status);

-- Booking indexes
CREATE INDEX IF NOT EXISTS idx_bookings_customer_id ON bookings(customer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_professional_id ON bookings(professional_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_scheduled_start ON bookings(scheduled_start_time);

-- Chat indexes
CREATE INDEX IF NOT EXISTS idx_chat_rooms_customer_id ON chat_rooms(customer_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_professional_id ON chat_rooms(professional_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_booking_id ON chat_rooms(booking_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_id ON chat_messages(chat_room_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at);

-- Payment indexes
CREATE INDEX IF NOT EXISTS idx_invoices_booking_id ON invoices(booking_id);
CREATE INDEX IF NOT EXISTS idx_invoices_customer_id ON invoices(customer_id);
CREATE INDEX IF NOT EXISTS idx_invoices_professional_id ON invoices(professional_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_payment_records_invoice_id ON payment_records(invoice_id);
CREATE INDEX IF NOT EXISTS idx_payment_records_status ON payment_records(status);

-- Notification indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON notifications(status);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_scheduled_for ON notifications(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_email_notifications_user_id ON email_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_email_notifications_status ON email_notifications(status);
CREATE INDEX IF NOT EXISTS idx_email_notifications_created_at ON email_notifications(created_at);

-- Review indexes
CREATE INDEX IF NOT EXISTS idx_reviews_booking_id ON reviews(booking_id);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewer_id ON reviews(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewee_id ON reviews(reviewee_id);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON reviews(rating);

-- Audit log indexes
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource_type ON audit_logs(resource_type);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);

-- ==============================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- ==============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at trigger to all relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_service_professionals_updated_at BEFORE UPDATE ON service_professionals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_service_categories_updated_at BEFORE UPDATE ON service_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_job_requests_updated_at BEFORE UPDATE ON job_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_estimates_updated_at BEFORE UPDATE ON estimates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_chat_rooms_updated_at BEFORE UPDATE ON chat_rooms FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payment_records_updated_at BEFORE UPDATE ON payment_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_professional_balances_updated_at BEFORE UPDATE ON professional_balances FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payouts_updated_at BEFORE UPDATE ON payouts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_notification_templates_updated_at BEFORE UPDATE ON notification_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_notification_channels_updated_at BEFORE UPDATE ON notification_channels FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_notification_preferences_updated_at BEFORE UPDATE ON notification_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON reviews FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON system_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==============================================
-- INITIAL DATA SEEDING
-- ==============================================

-- Insert default service categories
INSERT INTO service_categories (name, description, icon_name, sort_order) VALUES
('Auto Body Repair', 'Collision damage, dents, scratches, and paint work', 'car_repair', 1),
('Mechanical Repair', 'Engine, transmission, brakes, and other mechanical issues', 'wrench', 2),
('Electrical Systems', 'Battery, alternator, starter, and electrical components', 'electrical', 3),
('Interior Repair', 'Seats, dashboard, electronics, and interior components', 'interior', 4),
('Glass Repair', 'Windshield, windows, and glass replacement', 'glass', 5),
('Tire Services', 'Tire replacement, balancing, and alignment', 'tire', 6),
('Detailing', 'Car wash, waxing, and interior cleaning', 'detailing', 7),
('Emergency Services', 'Roadside assistance and emergency repairs', 'emergency', 8),
('Customization', 'Performance upgrades and custom modifications', 'custom', 9),
('Inspection', 'Safety inspections and diagnostic services', 'inspection', 10),
('Towing', 'Vehicle towing and transport services', 'towing', 11),
('Paint & Body', 'Professional painting and bodywork', 'paint', 12),
('AC & Heating', 'Air conditioning and heating system repair', 'ac', 13),
('Exhaust Systems', 'Muffler, catalytic converter, and exhaust repair', 'exhaust', 14),
('Suspension', 'Shocks, struts, and suspension system repair', 'suspension', 15),
('Transmission', 'Automatic and manual transmission repair', 'transmission', 16),
('Engine Repair', 'Engine diagnostics, repair, and maintenance', 'engine', 17),
('Brake Services', 'Brake pad, rotor, and brake system repair', 'brakes', 18),
('Oil Change', 'Oil change and fluid maintenance services', 'oil', 19),
('Battery Services', 'Battery replacement and electrical testing', 'battery', 20),
('Diagnostics', 'Computer diagnostics and trouble code reading', 'diagnostics', 21),
('General Maintenance', 'Routine maintenance and tune-ups', 'maintenance', 22)
ON CONFLICT (name) DO NOTHING;

-- Insert default notification channels
INSERT INTO notification_channels (channel_id, channel_name, description, importance_level) VALUES
('damage_reports', 'Damage Reports', 'Notifications for new damage reports and service requests', 4),
('estimate_requests', 'Estimate Requests', 'Notifications when estimates are requested or submitted', 4),
('estimate_updates', 'Estimate Updates', 'Notifications for estimate status changes', 3),
('booking_reminders', 'Booking Reminders', 'Reminder notifications for upcoming appointments', 3),
('chat_messages', 'Chat Messages', 'Real-time notifications for new chat messages', 2),
('payment_updates', 'Payment Updates', 'Notifications for payment status changes', 4),
('system_alerts', 'System Alerts', 'Important system-wide notifications', 5),
('marketing', 'Marketing', 'Promotional and marketing notifications', 1)
ON CONFLICT (channel_id) DO NOTHING;

-- Insert default notification templates
INSERT INTO notification_templates (notification_type, title_template, body_template, default_priority) VALUES
('new_job_request', 'New Service Request: {{service_title}}', 'You have a new {{service_category}} request in your area. Tap to view details.', 'high'),
('estimate_submitted', 'New Estimate Received', '{{professional_name}} has submitted an estimate for {{service_title}} - ${{price}}', 'normal'),
('estimate_accepted', 'Estimate Accepted', 'Your estimate for {{service_title}} has been accepted!', 'normal'),
('booking_confirmed', 'Booking Confirmed', 'Your {{service_title}} appointment is confirmed for {{date}} at {{time}}', 'normal'),
('booking_reminder_24h', 'Appointment Tomorrow', 'Reminder: Your {{service_title}} appointment is tomorrow at {{time}}', 'normal'),
('booking_reminder_1h', 'Appointment Starting Soon', 'Your {{service_title}} appointment starts in 1 hour', 'high'),
('chat_message', 'New Message from {{sender_name}}', '{{message_preview}}', 'normal'),
('payment_received', 'Payment Received', 'Payment of ${{amount}} has been received for {{service_title}}', 'normal'),
('payout_processed', 'Payout Processed', 'Your payout of ${{amount}} has been processed successfully', 'normal'),
('system_maintenance', 'System Maintenance', '{{message}}', 'normal')
ON CONFLICT (notification_type) DO NOTHING;

-- Insert default system settings
INSERT INTO system_settings (setting_key, setting_value, data_type, description, is_public) VALUES
('app_name', 'Vehicle Damage App', 'string', 'Application name', true),
('app_version', '1.0.0', 'string', 'Current application version', true),
('maintenance_mode', 'false', 'boolean', 'Whether the app is in maintenance mode', true),
('max_file_size_mb', '10', 'number', 'Maximum file upload size in MB', true),
('supported_file_types', '["jpg", "jpeg", "png", "gif", "mp4", "mov"]', 'json', 'Supported file types for uploads', true),
('default_currency', 'JMD', 'string', 'Default currency for the application', true),
('booking_reminder_hours', '[24, 1]', 'json', 'Hours before booking to send reminders', false),
('notification_retry_attempts', '3', 'number', 'Number of retry attempts for failed notifications', false),
('email_fallback_enabled', 'true', 'boolean', 'Whether to use email as fallback for notifications', false),
('fcm_enabled', 'true', 'boolean', 'Whether FCM notifications are enabled', false)
ON CONFLICT (setting_key) DO NOTHING;

-- ==============================================
-- VIEWS FOR COMMON QUERIES
-- ==============================================

-- View for active service professionals with ratings
CREATE OR REPLACE VIEW active_service_professionals AS
SELECT 
    u.id,
    u.firebase_uid,
    u.email,
    u.full_name,
    u.profile_photo_url,
    sp.business_name,
    sp.business_address,
    sp.business_phone,
    sp.website,
    sp.years_of_experience,
    sp.average_rating,
    sp.total_reviews,
    sp.is_available,
    sp.service_areas,
    sp.specializations,
    sp.certifications,
    sp.service_category_ids,
    u.created_at,
    u.updated_at
FROM users u
JOIN service_professionals sp ON u.id = sp.user_id
WHERE u.is_active = true 
  AND u.role = 'serviceProfessional'
  AND sp.is_available = true;

-- View for job request statistics
CREATE OR REPLACE VIEW job_request_stats AS
SELECT 
    sc.name as category_name,
    COUNT(jr.id) as total_requests,
    COUNT(CASE WHEN jr.status = 'pending' THEN 1 END) as pending_requests,
    COUNT(CASE WHEN jr.status = 'in_progress' THEN 1 END) as in_progress_requests,
    COUNT(CASE WHEN jr.status = 'completed' THEN 1 END) as completed_requests,
    AVG(jr.budget_max - jr.budget_min) as avg_budget_range,
    COUNT(CASE WHEN jr.is_urgent = true THEN 1 END) as urgent_requests
FROM service_categories sc
LEFT JOIN job_requests jr ON sc.id = jr.service_category_id
GROUP BY sc.id, sc.name, sc.sort_order
ORDER BY sc.sort_order;

-- View for professional earnings summary
CREATE OR REPLACE VIEW professional_earnings_summary AS
SELECT 
    u.id as professional_id,
    u.full_name as professional_name,
    pb.available_balance,
    pb.total_earned,
    pb.total_paid_out,
    COUNT(p.id) as total_payouts,
    COUNT(CASE WHEN p.status = 'completed' THEN 1 END) as completed_payouts,
    COUNT(CASE WHEN p.status = 'pending' THEN 1 END) as pending_payouts,
    MAX(p.created_at) as last_payout_date
FROM users u
JOIN professional_balances pb ON u.id = pb.professional_id
LEFT JOIN payouts p ON u.id = p.professional_id
WHERE u.role = 'serviceProfessional'
GROUP BY u.id, u.full_name, pb.available_balance, pb.total_earned, pb.total_paid_out;

-- ==============================================
-- FUNCTIONS FOR COMMON OPERATIONS
-- ==============================================

-- Function to update professional balance after payment
CREATE OR REPLACE FUNCTION update_professional_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process completed payments
    IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
        -- Update professional balance
        INSERT INTO professional_balances (professional_id, available_balance, total_earned)
        VALUES (NEW.professional_id, NEW.amount, NEW.amount)
        ON CONFLICT (professional_id) 
        DO UPDATE SET
            available_balance = professional_balances.available_balance + NEW.amount,
            total_earned = professional_balances.total_earned + NEW.amount,
            last_updated_at = CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update professional balance on payment completion
CREATE TRIGGER trigger_update_professional_balance
    AFTER INSERT OR UPDATE ON payment_records
    FOR EACH ROW
    EXECUTE FUNCTION update_professional_balance();

-- Function to update professional balance after payout
CREATE OR REPLACE FUNCTION update_professional_balance_after_payout()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process completed payouts
    IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
        -- Update professional balance
        UPDATE professional_balances 
        SET 
            available_balance = available_balance - NEW.amount,
            total_paid_out = total_paid_out + NEW.amount,
            last_updated_at = CURRENT_TIMESTAMP
        WHERE professional_id = NEW.professional_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update professional balance on payout completion
CREATE TRIGGER trigger_update_professional_balance_after_payout
    AFTER INSERT OR UPDATE ON payouts
    FOR EACH ROW
    EXECUTE FUNCTION update_professional_balance_after_payout();

-- ==============================================
-- GRANTS AND PERMISSIONS
-- ==============================================

-- Grant necessary permissions to application user
-- Note: Replace 'app_user' with your actual application database user
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO app_user;

COMMIT;
