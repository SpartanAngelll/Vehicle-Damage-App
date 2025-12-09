-- Migrate to use Firebase UID as primary key
-- Migration: 20240101000004_firebase_uid_migration.sql

-- First, drop all foreign key constraints that depend on users.id
ALTER TABLE service_professionals DROP CONSTRAINT IF EXISTS service_professionals_user_id_fkey;
ALTER TABLE job_requests DROP CONSTRAINT IF EXISTS job_requests_customer_id_fkey;
ALTER TABLE estimates DROP CONSTRAINT IF EXISTS estimates_professional_id_fkey;
ALTER TABLE chat_rooms DROP CONSTRAINT IF EXISTS chat_rooms_customer_id_fkey;
ALTER TABLE chat_rooms DROP CONSTRAINT IF EXISTS chat_rooms_professional_id_fkey;
ALTER TABLE chat_messages DROP CONSTRAINT IF EXISTS chat_messages_sender_id_fkey;
ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_customer_id_fkey;
ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_professional_id_fkey;
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;
ALTER TABLE notification_preferences DROP CONSTRAINT IF EXISTS notification_preferences_user_id_fkey;
ALTER TABLE email_notifications DROP CONSTRAINT IF EXISTS email_notifications_user_id_fkey;
ALTER TABLE audit_logs DROP CONSTRAINT IF EXISTS audit_logs_user_id_fkey;

-- Update users table to use firebase_uid as primary key
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE users DROP COLUMN IF EXISTS id;
ALTER TABLE users ADD PRIMARY KEY (firebase_uid);

-- Update foreign key references
ALTER TABLE service_professionals 
  DROP CONSTRAINT IF EXISTS service_professionals_user_id_fkey,
  ALTER COLUMN user_id TYPE VARCHAR(255),
  ADD CONSTRAINT service_professionals_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(firebase_uid) ON DELETE CASCADE;

ALTER TABLE job_requests 
  DROP CONSTRAINT IF EXISTS job_requests_customer_id_fkey,
  ALTER COLUMN customer_id TYPE VARCHAR(255),
  ADD CONSTRAINT job_requests_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES users(firebase_uid) ON DELETE CASCADE;

ALTER TABLE estimates 
  DROP CONSTRAINT IF EXISTS estimates_professional_id_fkey,
  ALTER COLUMN professional_id TYPE VARCHAR(255),
  ADD CONSTRAINT estimates_professional_id_fkey 
    FOREIGN KEY (professional_id) REFERENCES users(firebase_uid) ON DELETE CASCADE;

ALTER TABLE chat_rooms 
  DROP CONSTRAINT IF EXISTS chat_rooms_customer_id_fkey,
  DROP CONSTRAINT IF EXISTS chat_rooms_professional_id_fkey,
  ALTER COLUMN customer_id TYPE VARCHAR(255),
  ALTER COLUMN professional_id TYPE VARCHAR(255),
  ADD CONSTRAINT chat_rooms_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES users(firebase_uid) ON DELETE CASCADE,
  ADD CONSTRAINT chat_rooms_professional_id_fkey 
    FOREIGN KEY (professional_id) REFERENCES users(firebase_uid) ON DELETE CASCADE;

ALTER TABLE chat_messages 
  DROP CONSTRAINT IF EXISTS chat_messages_sender_id_fkey,
  ALTER COLUMN sender_id TYPE VARCHAR(255),
  ADD CONSTRAINT chat_messages_sender_id_fkey 
    FOREIGN KEY (sender_id) REFERENCES users(firebase_uid) ON DELETE CASCADE;

ALTER TABLE invoices 
  DROP CONSTRAINT IF EXISTS invoices_customer_id_fkey,
  DROP CONSTRAINT IF EXISTS invoices_professional_id_fkey,
  ALTER COLUMN customer_id TYPE VARCHAR(255),
  ALTER COLUMN professional_id TYPE VARCHAR(255),
  ADD CONSTRAINT invoices_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES users(firebase_uid) ON DELETE CASCADE,
  ADD CONSTRAINT invoices_professional_id_fkey 
    FOREIGN KEY (professional_id) REFERENCES users(firebase_uid) ON DELETE CASCADE;

ALTER TABLE notifications 
  DROP CONSTRAINT IF EXISTS notifications_user_id_fkey,
  ALTER COLUMN user_id TYPE VARCHAR(255),
  ADD CONSTRAINT notifications_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(firebase_uid) ON DELETE CASCADE;

ALTER TABLE notification_preferences 
  DROP CONSTRAINT IF EXISTS notification_preferences_user_id_fkey,
  ALTER COLUMN user_id TYPE VARCHAR(255),
  ADD CONSTRAINT notification_preferences_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(firebase_uid) ON DELETE CASCADE;

ALTER TABLE email_notifications 
  DROP CONSTRAINT IF EXISTS email_notifications_user_id_fkey,
  ALTER COLUMN user_id TYPE VARCHAR(255),
  ADD CONSTRAINT email_notifications_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(firebase_uid) ON DELETE SET NULL;

ALTER TABLE audit_logs 
  DROP CONSTRAINT IF EXISTS audit_logs_user_id_fkey,
  ALTER COLUMN user_id TYPE VARCHAR(255),
  ADD CONSTRAINT audit_logs_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(firebase_uid) ON DELETE SET NULL;

