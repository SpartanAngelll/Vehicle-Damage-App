-- Notification system database schema for PostgreSQL
-- This extends the existing database with notification tracking and history

-- Notifications table for tracking all notifications
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(255) NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    priority VARCHAR(20) NOT NULL DEFAULT 'normal',
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    data JSONB,
    action_buttons JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    scheduled_for TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    metadata JSONB
);

-- Notification templates table
CREATE TABLE IF NOT EXISTS notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_type VARCHAR(50) NOT NULL UNIQUE,
    title_template TEXT NOT NULL,
    body_template TEXT NOT NULL,
    default_data JSONB,
    default_action_buttons JSONB,
    default_priority VARCHAR(20) NOT NULL DEFAULT 'normal',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Notification channels table
CREATE TABLE IF NOT EXISTS notification_channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    importance VARCHAR(20) NOT NULL DEFAULT 'normal',
    enable_sound BOOLEAN NOT NULL DEFAULT true,
    enable_vibration BOOLEAN NOT NULL DEFAULT true,
    enable_lights BOOLEAN NOT NULL DEFAULT false,
    sound_file VARCHAR(255),
    light_color VARCHAR(7), -- Hex color code
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User notification preferences table
CREATE TABLE IF NOT EXISTS notification_preferences (
    user_id VARCHAR(255) PRIMARY KEY,
    enable_push_notifications BOOLEAN NOT NULL DEFAULT true,
    enable_email_notifications BOOLEAN NOT NULL DEFAULT true,
    enable_sms_notifications BOOLEAN NOT NULL DEFAULT false,
    type_preferences JSONB NOT NULL DEFAULT '{}',
    priority_overrides JSONB NOT NULL DEFAULT '{}',
    quiet_hours_start TEXT[] NOT NULL DEFAULT '{"22:00"}',
    quiet_hours_end TEXT[] NOT NULL DEFAULT '{"08:00"}',
    quiet_days INTEGER[] NOT NULL DEFAULT '{}',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Notification delivery logs table for audit trail
CREATE TABLE IF NOT EXISTS notification_delivery_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
    delivery_method VARCHAR(20) NOT NULL, -- 'push', 'email', 'sms'
    delivery_status VARCHAR(20) NOT NULL, -- 'sent', 'delivered', 'failed', 'bounced'
    external_id VARCHAR(255), -- External service ID (FCM message ID, email ID, etc.)
    delivered_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    retry_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Booking reminder schedules table
CREATE TABLE IF NOT EXISTS booking_reminder_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id VARCHAR(255) NOT NULL,
    reminder_type VARCHAR(20) NOT NULL, -- '24h', '1h'
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
    notification_id UUID REFERENCES notifications(id) ON DELETE SET NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'scheduled', -- 'scheduled', 'sent', 'cancelled', 'failed'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP WITH TIME ZONE
);

-- Email notification queue table
CREATE TABLE IF NOT EXISTS email_notification_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
    to_email VARCHAR(255) NOT NULL,
    to_name VARCHAR(255),
    subject TEXT NOT NULL,
    html_content TEXT NOT NULL,
    text_content TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'sent', 'failed', 'bounced'
    scheduled_for TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    retry_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON notifications(status);
CREATE INDEX IF NOT EXISTS idx_notifications_scheduled_for ON notifications(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

CREATE INDEX IF NOT EXISTS idx_notification_delivery_logs_notification_id ON notification_delivery_logs(notification_id);
CREATE INDEX IF NOT EXISTS idx_notification_delivery_logs_delivery_method ON notification_delivery_logs(delivery_method);
CREATE INDEX IF NOT EXISTS idx_notification_delivery_logs_status ON notification_delivery_logs(delivery_status);

CREATE INDEX IF NOT EXISTS idx_booking_reminder_schedules_booking_id ON booking_reminder_schedules(booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_reminder_schedules_scheduled_for ON booking_reminder_schedules(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_booking_reminder_schedules_status ON booking_reminder_schedules(status);

CREATE INDEX IF NOT EXISTS idx_email_notification_queue_status ON email_notification_queue(status);
CREATE INDEX IF NOT EXISTS idx_email_notification_queue_scheduled_for ON email_notification_queue(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_email_notification_queue_to_email ON email_notification_queue(to_email);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_notification_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at for notification_templates
CREATE TRIGGER update_notification_templates_updated_at 
    BEFORE UPDATE ON notification_templates 
    FOR EACH ROW 
    EXECUTE FUNCTION update_notification_updated_at_column();

-- Trigger to automatically update updated_at for notification_preferences
CREATE TRIGGER update_notification_preferences_updated_at 
    BEFORE UPDATE ON notification_preferences 
    FOR EACH ROW 
    EXECUTE FUNCTION update_notification_updated_at_column();

-- Function to clean up old notifications
CREATE OR REPLACE FUNCTION cleanup_old_notifications(days_old INTEGER DEFAULT 30)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM notifications 
    WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '1 day' * days_old
    AND status IN ('delivered', 'read', 'failed');
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ language 'plpgsql';

-- Function to get notification statistics
CREATE OR REPLACE FUNCTION get_notification_stats(user_id_param VARCHAR(255) DEFAULT NULL)
RETURNS TABLE (
    total_notifications BIGINT,
    pending_notifications BIGINT,
    sent_notifications BIGINT,
    delivered_notifications BIGINT,
    failed_notifications BIGINT,
    read_notifications BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_notifications,
        COUNT(*) FILTER (WHERE status = 'pending') as pending_notifications,
        COUNT(*) FILTER (WHERE status = 'sent') as sent_notifications,
        COUNT(*) FILTER (WHERE status = 'delivered') as delivered_notifications,
        COUNT(*) FILTER (WHERE status = 'failed') as failed_notifications,
        COUNT(*) FILTER (WHERE status = 'read') as read_notifications
    FROM notifications
    WHERE (user_id_param IS NULL OR user_id = user_id_param);
END;
$$ language 'plpgsql';

-- Insert default notification templates
INSERT INTO notification_templates (notification_type, title_template, body_template, default_action_buttons, default_priority) VALUES
('booking_reminder_24h', 'Booking Reminder - {{service_title}}', 'Your {{service_title}} appointment is scheduled for tomorrow at {{scheduled_time}}. Location: {{location}}', '{"view_booking": "View Booking", "reschedule": "Reschedule"}', 'high'),
('booking_reminder_1h', 'Booking Starting Soon - {{service_title}}', 'Your {{service_title}} appointment starts in 1 hour at {{location}}', '{"view_booking": "View Booking", "contact_professional": "Contact Professional"}', 'urgent'),
('new_chat_message', 'New Message from {{sender_name}}', '{{message_preview}}', '{"reply": "Reply", "view_chat": "View Chat"}', 'high'),
('new_estimate', 'New Estimate Received', '{{professional_name}} has submitted an estimate for {{service_title}} - {{price}}', '{"view_estimate": "View Estimate", "accept": "Accept"}', 'high'),
('new_service_request', 'New Service Request Available', 'A new {{service_category}} request is available in your area', '{"view_request": "View Request", "submit_estimate": "Submit Estimate"}', 'high'),
('booking_status_update', 'Booking Status Update', 'Your {{service_title}} booking status has been updated to {{status}}', '{"view_booking": "View Booking"}', 'normal'),
('payment_update', 'Payment Update', 'Your payment for {{service_title}} has been {{status}}', '{"view_payment": "View Payment"}', 'normal'),
('system_alert', 'System Alert', '{{message}}', '{"view_details": "View Details"}', 'high')
ON CONFLICT (notification_type) DO NOTHING;

-- Insert default notification channels
INSERT INTO notification_channels (name, description, importance, enable_sound, enable_vibration) VALUES
('booking_notifications', 'Booking Notifications', 'high', true, true),
('chat_notifications', 'Chat Notifications', 'high', true, true),
('estimate_notifications', 'Estimate Notifications', 'high', true, true),
('request_notifications', 'Request Notifications', 'high', true, true),
('system_notifications', 'System Notifications', 'max', true, true)
ON CONFLICT (name) DO NOTHING;

-- Create a view for notification analytics
CREATE OR REPLACE VIEW notification_analytics AS
SELECT 
    n.notification_type,
    n.priority,
    n.status,
    COUNT(*) as count,
    AVG(EXTRACT(EPOCH FROM (n.sent_at - n.created_at))) as avg_delivery_time_seconds,
    AVG(EXTRACT(EPOCH FROM (n.read_at - n.sent_at))) as avg_read_time_seconds
FROM notifications n
GROUP BY n.notification_type, n.priority, n.status;

-- Create a view for user notification preferences with defaults
CREATE OR REPLACE VIEW user_notification_preferences_with_defaults AS
SELECT 
    u.user_id,
    COALESCE(np.enable_push_notifications, true) as enable_push_notifications,
    COALESCE(np.enable_email_notifications, true) as enable_email_notifications,
    COALESCE(np.enable_sms_notifications, false) as enable_sms_notifications,
    COALESCE(np.type_preferences, '{}'::jsonb) as type_preferences,
    COALESCE(np.priority_overrides, '{}'::jsonb) as priority_overrides,
    COALESCE(np.quiet_hours_start, ARRAY['22:00']) as quiet_hours_start,
    COALESCE(np.quiet_hours_end, ARRAY['08:00']) as quiet_hours_end,
    COALESCE(np.quiet_days, ARRAY[]::integer[]) as quiet_days
FROM (SELECT DISTINCT user_id FROM notifications) u
LEFT JOIN notification_preferences np ON u.user_id = np.user_id;
