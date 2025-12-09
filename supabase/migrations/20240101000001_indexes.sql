-- Create indexes for performance
-- Migration: 20240101000001_indexes.sql

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
CREATE INDEX IF NOT EXISTS idx_payment_records_booking_id ON payment_records(booking_id);
CREATE INDEX IF NOT EXISTS idx_payment_records_status ON payment_records(status);
CREATE INDEX IF NOT EXISTS idx_payment_records_type ON payment_records(type);
CREATE INDEX IF NOT EXISTS idx_payment_status_history_payment_id ON payment_status_history(payment_id);

-- Service packages indexes
CREATE INDEX IF NOT EXISTS idx_service_packages_professional_id ON service_packages(professional_id);
CREATE INDEX IF NOT EXISTS idx_service_packages_is_active ON service_packages(is_active);
CREATE INDEX IF NOT EXISTS idx_service_packages_professional_active ON service_packages(professional_id, is_active);

-- Professional balances indexes
CREATE INDEX IF NOT EXISTS idx_professional_balances_professional_id ON professional_balances(professional_id);

-- Payouts indexes
CREATE INDEX IF NOT EXISTS idx_payouts_professional_id ON payouts(professional_id);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON payouts(status);

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

