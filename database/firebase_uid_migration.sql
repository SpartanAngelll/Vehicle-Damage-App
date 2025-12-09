-- Migrate tables to use Firebase UID as primary key
-- Run this after setting up RLS policies

-- Step 1: Update users table to use firebase_uid as primary key
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE users DROP COLUMN IF EXISTS id;
ALTER TABLE users ADD PRIMARY KEY (firebase_uid);

-- Step 2: Update foreign key references to use firebase_uid
-- Service professionals
ALTER TABLE service_professionals 
  DROP CONSTRAINT IF EXISTS service_professionals_user_id_fkey,
  ALTER COLUMN user_id TYPE VARCHAR(255),
  ADD CONSTRAINT service_professionals_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(firebase_uid) ON DELETE CASCADE;

-- Job requests
ALTER TABLE job_requests 
  DROP CONSTRAINT IF EXISTS job_requests_customer_id_fkey,
  ALTER COLUMN customer_id TYPE VARCHAR(255),
  ADD CONSTRAINT job_requests_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES users(firebase_uid) ON DELETE CASCADE;

-- Estimates
ALTER TABLE estimates 
  DROP CONSTRAINT IF EXISTS estimates_professional_id_fkey,
  ALTER COLUMN professional_id TYPE VARCHAR(255),
  ADD CONSTRAINT estimates_professional_id_fkey 
    FOREIGN KEY (professional_id) REFERENCES users(firebase_uid) ON DELETE CASCADE;

-- Chat rooms
ALTER TABLE chat_rooms 
  DROP CONSTRAINT IF EXISTS chat_rooms_customer_id_fkey,
  DROP CONSTRAINT IF EXISTS chat_rooms_professional_id_fkey,
  ALTER COLUMN customer_id TYPE VARCHAR(255),
  ALTER COLUMN professional_id TYPE VARCHAR(255),
  ADD CONSTRAINT chat_rooms_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES users(firebase_uid) ON DELETE CASCADE,
  ADD CONSTRAINT chat_rooms_professional_id_fkey 
    FOREIGN KEY (professional_id) REFERENCES users(firebase_uid) ON DELETE CASCADE;

-- Chat messages
ALTER TABLE chat_messages 
  DROP CONSTRAINT IF EXISTS chat_messages_sender_id_fkey,
  ALTER COLUMN sender_id TYPE VARCHAR(255),
  ADD CONSTRAINT chat_messages_sender_id_fkey 
    FOREIGN KEY (sender_id) REFERENCES users(firebase_uid) ON DELETE CASCADE;

-- Invoices
ALTER TABLE invoices 
  DROP CONSTRAINT IF EXISTS invoices_customer_id_fkey,
  DROP CONSTRAINT IF EXISTS invoices_professional_id_fkey,
  ALTER COLUMN customer_id TYPE VARCHAR(255),
  ALTER COLUMN professional_id TYPE VARCHAR(255),
  ADD CONSTRAINT invoices_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES users(firebase_uid) ON DELETE CASCADE,
  ADD CONSTRAINT invoices_professional_id_fkey 
    FOREIGN KEY (professional_id) REFERENCES users(firebase_uid) ON DELETE CASCADE;

-- Notifications
ALTER TABLE notifications 
  DROP CONSTRAINT IF EXISTS notifications_user_id_fkey,
  ALTER COLUMN user_id TYPE VARCHAR(255),
  ADD CONSTRAINT notifications_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(firebase_uid) ON DELETE CASCADE;

-- Notification preferences
ALTER TABLE notification_preferences 
  DROP CONSTRAINT IF EXISTS notification_preferences_user_id_fkey,
  ALTER COLUMN user_id TYPE VARCHAR(255),
  ADD CONSTRAINT notification_preferences_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(firebase_uid) ON DELETE CASCADE;

-- Email notifications
ALTER TABLE email_notifications 
  DROP CONSTRAINT IF EXISTS email_notifications_user_id_fkey,
  ALTER COLUMN user_id TYPE VARCHAR(255),
  ADD CONSTRAINT email_notifications_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(firebase_uid) ON DELETE SET NULL;

-- Audit logs
ALTER TABLE audit_logs 
  DROP CONSTRAINT IF EXISTS audit_logs_user_id_fkey,
  ALTER COLUMN user_id TYPE VARCHAR(255),
  ADD CONSTRAINT audit_logs_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(firebase_uid) ON DELETE SET NULL;

-- Update indexes
DROP INDEX IF EXISTS idx_users_firebase_uid;
DROP INDEX IF EXISTS idx_service_professionals_user_id;
DROP INDEX IF EXISTS idx_job_requests_customer_id;
DROP INDEX IF EXISTS idx_estimates_professional_id;
DROP INDEX IF EXISTS idx_chat_rooms_customer_id;
DROP INDEX IF EXISTS idx_chat_rooms_professional_id;
DROP INDEX IF EXISTS idx_chat_messages_sender_id;
DROP INDEX IF EXISTS idx_invoices_customer_id;
DROP INDEX IF EXISTS idx_invoices_professional_id;
DROP INDEX IF EXISTS idx_notifications_user_id;
DROP INDEX IF EXISTS idx_email_notifications_user_id;
DROP INDEX IF EXISTS idx_audit_logs_user_id;

CREATE INDEX IF NOT EXISTS idx_service_professionals_user_id ON service_professionals(user_id);
CREATE INDEX IF NOT EXISTS idx_job_requests_customer_id ON job_requests(customer_id);
CREATE INDEX IF NOT EXISTS idx_estimates_professional_id ON estimates(professional_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_customer_id ON chat_rooms(customer_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_professional_id ON chat_rooms(professional_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_invoices_customer_id ON invoices(customer_id);
CREATE INDEX IF NOT EXISTS idx_invoices_professional_id ON invoices(professional_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF EXISTS idx_email_notifications_user_id ON email_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);

