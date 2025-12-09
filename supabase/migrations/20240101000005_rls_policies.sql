-- Enable RLS and create policies for Firebase authentication
-- Migration: 20240101000005_rls_policies.sql

-- Helper function to get Firebase UID from JWT
-- Note: This function reads from auth.jwt() which is available in Supabase
CREATE OR REPLACE FUNCTION public.firebase_uid()
RETURNS TEXT AS $$
BEGIN
  RETURN (auth.jwt()->>'sub')::TEXT;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_professionals ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE estimates ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_confirmations ENABLE ROW LEVEL SECURITY;
ALTER TABLE professional_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Users policies
DROP POLICY IF EXISTS "Users can read own profile" ON users;
CREATE POLICY "Users can read own profile" ON users FOR SELECT USING (firebase_uid = public.firebase_uid());
DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (firebase_uid = public.firebase_uid());
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
CREATE POLICY "Users can insert own profile" ON users FOR INSERT WITH CHECK (firebase_uid = public.firebase_uid());
DROP POLICY IF EXISTS "Service professionals are publicly readable" ON service_professionals;
CREATE POLICY "Service professionals are publicly readable" ON service_professionals FOR SELECT USING (true);
DROP POLICY IF EXISTS "Professionals can update own profile" ON service_professionals;
CREATE POLICY "Professionals can update own profile" ON service_professionals FOR UPDATE USING (user_id = public.firebase_uid());
DROP POLICY IF EXISTS "Professionals can insert own profile" ON service_professionals;
CREATE POLICY "Professionals can insert own profile" ON service_professionals FOR INSERT WITH CHECK (user_id = public.firebase_uid());

-- Job requests policies
DROP POLICY IF EXISTS "Customers can manage own job requests" ON job_requests;
CREATE POLICY "Customers can manage own job requests" ON job_requests FOR ALL USING (customer_id = public.firebase_uid()) WITH CHECK (customer_id = public.firebase_uid());
DROP POLICY IF EXISTS "Professionals can view active job requests" ON job_requests;
CREATE POLICY "Professionals can view active job requests" ON job_requests FOR SELECT USING (status IN ('pending', 'in_progress'));

-- Estimates policies
DROP POLICY IF EXISTS "Professionals can manage own estimates" ON estimates;
CREATE POLICY "Professionals can manage own estimates" ON estimates FOR ALL USING (professional_id = public.firebase_uid()) WITH CHECK (professional_id = public.firebase_uid());
DROP POLICY IF EXISTS "Customers can view estimates for their requests" ON estimates;
CREATE POLICY "Customers can view estimates for their requests" ON estimates FOR SELECT USING (
  EXISTS (SELECT 1 FROM job_requests WHERE job_requests.id = estimates.job_request_id AND job_requests.customer_id = public.firebase_uid())
);

-- Bookings policies
DROP POLICY IF EXISTS "Users can view own bookings" ON bookings;
CREATE POLICY "Users can view own bookings" ON bookings FOR SELECT USING (customer_id = public.firebase_uid() OR professional_id = public.firebase_uid());
DROP POLICY IF EXISTS "Customers can create bookings" ON bookings;
CREATE POLICY "Customers can create bookings" ON bookings FOR INSERT WITH CHECK (customer_id = public.firebase_uid());
DROP POLICY IF EXISTS "Users can update own bookings" ON bookings;
CREATE POLICY "Users can update own bookings" ON bookings FOR UPDATE USING (customer_id = public.firebase_uid() OR professional_id = public.firebase_uid()) WITH CHECK (customer_id = public.firebase_uid() OR professional_id = public.firebase_uid());

-- Invoices policies
DROP POLICY IF EXISTS "Users can view own invoices" ON invoices;
CREATE POLICY "Users can view own invoices" ON invoices FOR SELECT USING (customer_id = public.firebase_uid() OR professional_id = public.firebase_uid());
DROP POLICY IF EXISTS "Professionals can create invoices" ON invoices;
CREATE POLICY "Professionals can create invoices" ON invoices FOR INSERT WITH CHECK (professional_id = public.firebase_uid());
DROP POLICY IF EXISTS "Users can update own invoices" ON invoices;
CREATE POLICY "Users can update own invoices" ON invoices FOR UPDATE USING (customer_id = public.firebase_uid() OR professional_id = public.firebase_uid());

-- Payment records policies
DROP POLICY IF EXISTS "Users can view own payment records" ON payment_records;
CREATE POLICY "Users can view own payment records" ON payment_records FOR SELECT USING (
  EXISTS (SELECT 1 FROM bookings WHERE bookings.id = payment_records.booking_id AND (bookings.customer_id = public.firebase_uid() OR bookings.professional_id = public.firebase_uid()))
);
DROP POLICY IF EXISTS "System can create payment records" ON payment_records;
CREATE POLICY "System can create payment records" ON payment_records FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Users can update own payment records" ON payment_records;
CREATE POLICY "Users can update own payment records" ON payment_records FOR UPDATE USING (
  EXISTS (SELECT 1 FROM bookings WHERE bookings.id = payment_records.booking_id AND (bookings.customer_id = public.firebase_uid() OR bookings.professional_id = public.firebase_uid()))
);

-- Payment confirmations policies
DROP POLICY IF EXISTS "Professionals can manage own confirmations" ON payment_confirmations;
CREATE POLICY "Professionals can manage own confirmations" ON payment_confirmations FOR ALL USING (professional_id = public.firebase_uid()) WITH CHECK (professional_id = public.firebase_uid());
DROP POLICY IF EXISTS "Customers can view confirmations for own bookings" ON payment_confirmations;
CREATE POLICY "Customers can view confirmations for own bookings" ON payment_confirmations FOR SELECT USING (
  EXISTS (SELECT 1 FROM bookings WHERE bookings.id = payment_confirmations.booking_id AND bookings.customer_id = public.firebase_uid())
);

-- Professional balances policies
DROP POLICY IF EXISTS "Professionals can view own balance" ON professional_balances;
CREATE POLICY "Professionals can view own balance" ON professional_balances FOR SELECT USING (professional_id = public.firebase_uid());
DROP POLICY IF EXISTS "System can update balances" ON professional_balances;
CREATE POLICY "System can update balances" ON professional_balances FOR UPDATE USING (true);

-- Payouts policies
DROP POLICY IF EXISTS "Professionals can view own payouts" ON payouts;
CREATE POLICY "Professionals can view own payouts" ON payouts FOR SELECT USING (professional_id = public.firebase_uid());
DROP POLICY IF EXISTS "Professionals can create own payouts" ON payouts;
CREATE POLICY "Professionals can create own payouts" ON payouts FOR INSERT WITH CHECK (professional_id = public.firebase_uid());

-- Reviews policies
DROP POLICY IF EXISTS "Users can view all reviews" ON reviews;
CREATE POLICY "Users can view all reviews" ON reviews FOR SELECT USING (is_public = true OR reviewer_id = public.firebase_uid() OR reviewee_id = public.firebase_uid());
DROP POLICY IF EXISTS "Users can create reviews for own bookings" ON reviews;
CREATE POLICY "Users can create reviews for own bookings" ON reviews FOR INSERT WITH CHECK (
  reviewer_id = public.firebase_uid() AND EXISTS (SELECT 1 FROM bookings WHERE bookings.id = reviews.booking_id AND (bookings.customer_id = public.firebase_uid() OR bookings.professional_id = public.firebase_uid()))
);
DROP POLICY IF EXISTS "Reviewers can update own reviews" ON reviews;
CREATE POLICY "Reviewers can update own reviews" ON reviews FOR UPDATE USING (reviewer_id = public.firebase_uid());

-- Notifications policies
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (user_id = public.firebase_uid());
DROP POLICY IF EXISTS "System can create notifications" ON notifications;
CREATE POLICY "System can create notifications" ON notifications FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (user_id = public.firebase_uid());

-- Notification preferences policies
DROP POLICY IF EXISTS "Users can manage own preferences" ON notification_preferences;
CREATE POLICY "Users can manage own preferences" ON notification_preferences FOR ALL USING (user_id = public.firebase_uid()) WITH CHECK (user_id = public.firebase_uid());

-- Email notifications policies
DROP POLICY IF EXISTS "Users can view own email notifications" ON email_notifications;
CREATE POLICY "Users can view own email notifications" ON email_notifications FOR SELECT USING (user_id = public.firebase_uid() OR user_id IS NULL);

-- Service packages policies
DROP POLICY IF EXISTS "Service packages are publicly readable" ON service_packages;
CREATE POLICY "Service packages are publicly readable" ON service_packages FOR SELECT USING (is_active = true);
DROP POLICY IF EXISTS "Professionals can manage own packages" ON service_packages;
CREATE POLICY "Professionals can manage own packages" ON service_packages FOR ALL USING (professional_id = public.firebase_uid()) WITH CHECK (professional_id = public.firebase_uid());

-- Chat rooms policies
DROP POLICY IF EXISTS "Users can view own chat rooms" ON chat_rooms;
CREATE POLICY "Users can view own chat rooms" ON chat_rooms FOR SELECT USING (customer_id = public.firebase_uid() OR professional_id = public.firebase_uid());
DROP POLICY IF EXISTS "System can create chat rooms" ON chat_rooms;
CREATE POLICY "System can create chat rooms" ON chat_rooms FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Users can update own chat rooms" ON chat_rooms;
CREATE POLICY "Users can update own chat rooms" ON chat_rooms FOR UPDATE USING (customer_id = public.firebase_uid() OR professional_id = public.firebase_uid());

-- Chat messages policies
DROP POLICY IF EXISTS "Users can view messages in own rooms" ON chat_messages;
CREATE POLICY "Users can view messages in own rooms" ON chat_messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM chat_rooms WHERE chat_rooms.id = chat_messages.chat_room_id AND (chat_rooms.customer_id = public.firebase_uid() OR chat_rooms.professional_id = public.firebase_uid()))
);
DROP POLICY IF EXISTS "Users can send messages in own rooms" ON chat_messages;
CREATE POLICY "Users can send messages in own rooms" ON chat_messages FOR INSERT WITH CHECK (
  sender_id = public.firebase_uid() AND EXISTS (SELECT 1 FROM chat_rooms WHERE chat_rooms.id = chat_messages.chat_room_id AND (chat_rooms.customer_id = public.firebase_uid() OR chat_rooms.professional_id = public.firebase_uid()))
);

-- Audit logs policies
DROP POLICY IF EXISTS "Users can view own audit logs" ON audit_logs;
CREATE POLICY "Users can view own audit logs" ON audit_logs FOR SELECT USING (user_id = public.firebase_uid() OR user_id IS NULL);
DROP POLICY IF EXISTS "System can create audit logs" ON audit_logs;
CREATE POLICY "System can create audit logs" ON audit_logs FOR INSERT WITH CHECK (true);

-- System settings policies
DROP POLICY IF EXISTS "Public settings are readable" ON system_settings;
CREATE POLICY "Public settings are readable" ON system_settings FOR SELECT USING (is_public = true);
DROP POLICY IF EXISTS "Admins can manage settings" ON system_settings;
CREATE POLICY "Admins can manage settings" ON system_settings FOR ALL USING (
  EXISTS (SELECT 1 FROM users WHERE users.firebase_uid = public.firebase_uid() AND users.role = 'admin')
);

