-- Audit Logging Setup for Supabase
-- This script creates automatic audit logging for user actions
-- Run this in Supabase SQL Editor after setting up your database

-- ==============================================
-- Helper Function: Get Current User ID from Firebase UID
-- ==============================================
-- This function gets the UUID user_id from the users table
-- based on the Firebase UID in the JWT token

CREATE OR REPLACE FUNCTION public.get_current_user_id()
RETURNS UUID
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  firebase_uid_text TEXT;
  user_uuid UUID;
BEGIN
  -- Extract Firebase UID from JWT
  firebase_uid_text := public.firebase_uid();
  
  -- If no Firebase UID, return NULL
  IF firebase_uid_text IS NULL THEN
    RETURN NULL;
  END IF;
  
  -- Get the UUID from users table
  SELECT id INTO user_uuid
  FROM users
  WHERE firebase_uid = firebase_uid_text
  LIMIT 1;
  
  RETURN user_uuid;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_current_user_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_current_user_id() TO anon;

-- ==============================================
-- Audit Logging Function
-- ==============================================
-- This function creates audit log entries automatically

CREATE OR REPLACE FUNCTION public.create_audit_log(
  p_action VARCHAR(100),
  p_resource_type VARCHAR(50),
  p_resource_id UUID DEFAULT NULL,
  p_old_values JSONB DEFAULT NULL,
  p_new_values JSONB DEFAULT NULL,
  p_metadata JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_log_id UUID;
  v_user_id UUID;
  v_firebase_uid TEXT;
BEGIN
  -- Get current user ID
  v_user_id := public.get_current_user_id();
  v_firebase_uid := public.firebase_uid();
  
  -- Generate log ID
  v_log_id := uuid_generate_v4();
  
  -- Insert audit log entry
  INSERT INTO audit_logs (
    id,
    user_id,
    action,
    resource_type,
    resource_id,
    old_values,
    new_values,
    ip_address,
    user_agent,
    metadata,
    created_at
  ) VALUES (
    v_log_id,
    v_user_id,
    p_action,
    p_resource_type,
    p_resource_id,
    p_old_values,
    p_new_values,
    -- Note: IP and user agent would need to be passed from application
    -- For now, we'll leave them NULL
    NULL, -- ip_address
    NULL, -- user_agent
    COALESCE(p_metadata, '{}'::JSONB) || 
      jsonb_build_object('firebase_uid', v_firebase_uid),
    CURRENT_TIMESTAMP
  );
  
  RETURN v_log_id;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.create_audit_log(VARCHAR, VARCHAR, UUID, JSONB, JSONB, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_audit_log(VARCHAR, VARCHAR, UUID, JSONB, JSONB, JSONB) TO anon;

-- ==============================================
-- Automatic Audit Triggers
-- ==============================================
-- These triggers automatically log INSERT, UPDATE, and DELETE operations

-- Function to log changes automatically
CREATE OR REPLACE FUNCTION public.audit_trigger_function()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_action VARCHAR(100);
  v_old_values JSONB;
  v_new_values JSONB;
  v_resource_id UUID;
BEGIN
  -- Determine action type
  IF TG_OP = 'INSERT' THEN
    v_action := 'create';
    v_new_values := to_jsonb(NEW);
    v_resource_id := NEW.id;
    v_old_values := NULL;
  ELSIF TG_OP = 'UPDATE' THEN
    v_action := 'update';
    v_old_values := to_jsonb(OLD);
    v_new_values := to_jsonb(NEW);
    v_resource_id := NEW.id;
  ELSIF TG_OP = 'DELETE' THEN
    v_action := 'delete';
    v_old_values := to_jsonb(OLD);
    v_new_values := NULL;
    v_resource_id := OLD.id;
  END IF;
  
  -- Create audit log entry
  PERFORM public.create_audit_log(
    p_action := v_action || '_' || TG_TABLE_NAME,
    p_resource_type := TG_TABLE_NAME,
    p_resource_id := v_resource_id,
    p_old_values := v_old_values,
    p_new_values := v_new_values,
    p_metadata := jsonb_build_object(
      'operation', TG_OP,
      'table', TG_TABLE_NAME
    )
  );
  
  -- Return appropriate record
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$;

-- ==============================================
-- Apply Audit Triggers to Key Tables
-- ==============================================
-- Enable automatic audit logging for important tables

-- Users table
DROP TRIGGER IF EXISTS audit_users_trigger ON users;
CREATE TRIGGER audit_users_trigger
  AFTER INSERT OR UPDATE OR DELETE ON users
  FOR EACH ROW
  EXECUTE FUNCTION public.audit_trigger_function();

-- Job requests table
DROP TRIGGER IF EXISTS audit_job_requests_trigger ON job_requests;
CREATE TRIGGER audit_job_requests_trigger
  AFTER INSERT OR UPDATE OR DELETE ON job_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.audit_trigger_function();

-- Estimates table
DROP TRIGGER IF EXISTS audit_estimates_trigger ON estimates;
CREATE TRIGGER audit_estimates_trigger
  AFTER INSERT OR UPDATE OR DELETE ON estimates
  FOR EACH ROW
  EXECUTE FUNCTION public.audit_trigger_function();

-- Bookings table
DROP TRIGGER IF EXISTS audit_bookings_trigger ON bookings;
CREATE TRIGGER audit_bookings_trigger
  AFTER INSERT OR UPDATE OR DELETE ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.audit_trigger_function();

-- Invoices table
DROP TRIGGER IF EXISTS audit_invoices_trigger ON invoices;
CREATE TRIGGER audit_invoices_trigger
  AFTER INSERT OR UPDATE OR DELETE ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION public.audit_trigger_function();

-- Payment records table
DROP TRIGGER IF EXISTS audit_payment_records_trigger ON payment_records;
CREATE TRIGGER audit_payment_records_trigger
  AFTER INSERT OR UPDATE OR DELETE ON payment_records
  FOR EACH ROW
  EXECUTE FUNCTION public.audit_trigger_function();

-- Reviews table
DROP TRIGGER IF EXISTS audit_reviews_trigger ON reviews;
CREATE TRIGGER audit_reviews_trigger
  AFTER INSERT OR UPDATE OR DELETE ON reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.audit_trigger_function();

-- Service professionals table
DROP TRIGGER IF EXISTS audit_service_professionals_trigger ON service_professionals;
CREATE TRIGGER audit_service_professionals_trigger
  AFTER INSERT OR UPDATE OR DELETE ON service_professionals
  FOR EACH ROW
  EXECUTE FUNCTION public.audit_trigger_function();

-- Service packages table
DROP TRIGGER IF EXISTS audit_service_packages_trigger ON service_packages;
CREATE TRIGGER audit_service_packages_trigger
  AFTER INSERT OR UPDATE OR DELETE ON service_packages
  FOR EACH ROW
  EXECUTE FUNCTION public.audit_trigger_function();

-- ==============================================
-- Optional: Login/Logout Tracking
-- ==============================================
-- Function to log user login/logout events
-- Call this from your application when users sign in/out

CREATE OR REPLACE FUNCTION public.log_user_login()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_log_id UUID;
  v_user_id UUID;
BEGIN
  v_user_id := public.get_current_user_id();
  
  -- Create login audit log
  v_log_id := uuid_generate_v4();
  
  INSERT INTO audit_logs (
    id,
    user_id,
    action,
    resource_type,
    resource_id,
    metadata,
    created_at
  ) VALUES (
    v_log_id,
    v_user_id,
    'user_login',
    'authentication',
    v_user_id,
    jsonb_build_object(
      'firebase_uid', public.firebase_uid(),
      'timestamp', CURRENT_TIMESTAMP
    ),
    CURRENT_TIMESTAMP
  );
  
  -- Update last_login_at in users table
  IF v_user_id IS NOT NULL THEN
    UPDATE users
    SET last_login_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_user_id;
  END IF;
  
  RETURN v_log_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.log_user_logout()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_log_id UUID;
  v_user_id UUID;
BEGIN
  v_user_id := public.get_current_user_id();
  
  -- Create logout audit log
  v_log_id := uuid_generate_v4();
  
  INSERT INTO audit_logs (
    id,
    user_id,
    action,
    resource_type,
    resource_id,
    metadata,
    created_at
  ) VALUES (
    v_log_id,
    v_user_id,
    'user_logout',
    'authentication',
    v_user_id,
    jsonb_build_object(
      'firebase_uid', public.firebase_uid(),
      'timestamp', CURRENT_TIMESTAMP
    ),
    CURRENT_TIMESTAMP
  );
  
  RETURN v_log_id;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.log_user_login() TO authenticated;
GRANT EXECUTE ON FUNCTION public.log_user_logout() TO authenticated;

-- ==============================================
-- Verification Queries
-- ==============================================
-- Run these to verify audit logging is working:

-- 1. Check if triggers are created
-- SELECT trigger_name, event_object_table, action_timing, event_manipulation
-- FROM information_schema.triggers
-- WHERE trigger_schema = 'public'
-- AND trigger_name LIKE 'audit_%'
-- ORDER BY event_object_table, trigger_name;

-- 2. Test by creating/updating a record and checking audit_logs
-- INSERT INTO users (firebase_uid, email, role) 
-- VALUES ('test-uid-123', 'test@example.com', 'owner');
-- 
-- SELECT * FROM audit_logs 
-- WHERE resource_type = 'users' 
-- ORDER BY created_at DESC 
-- LIMIT 5;

-- 3. View recent audit logs
-- SELECT 
--   al.id,
--   al.action,
--   al.resource_type,
--   u.email,
--   al.created_at
-- FROM audit_logs al
-- LEFT JOIN users u ON al.user_id = u.id
-- ORDER BY al.created_at DESC
-- LIMIT 20;

-- ==============================================
-- IMPORTANT NOTES
-- ==============================================
-- 1. Audit logs are automatically created for INSERT, UPDATE, DELETE operations
--    on the tables listed above
--
-- 2. For login/logout tracking, call log_user_login() and log_user_logout()
--    from your application code
--
-- 3. The audit_logs table stores:
--    - User ID (UUID from users table)
--    - Action type (create_users, update_bookings, etc.)
--    - Resource type (table name)
--    - Resource ID (record ID)
--    - Old and new values (JSONB)
--    - Metadata (including Firebase UID)
--
-- 4. RLS policies allow users to view their own audit logs
--
-- 5. To add audit logging to more tables, create triggers using the same pattern:
--    CREATE TRIGGER audit_[table_name]_trigger
--      AFTER INSERT OR UPDATE OR DELETE ON [table_name]
--      FOR EACH ROW
--      EXECUTE FUNCTION public.audit_trigger_function();

