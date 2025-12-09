-- Seed initial data
-- Migration: 20240101000003_seed_data.sql

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
ON CONFLICT DO NOTHING;

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

