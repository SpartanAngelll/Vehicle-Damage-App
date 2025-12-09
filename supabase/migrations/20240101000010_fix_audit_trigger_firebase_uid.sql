-- Fix audit trigger to work with firebase_uid schema (users table has no id column)
-- Migration: 20240101000010_fix_audit_trigger_firebase_uid.sql
-- This fixes the audit trigger to work after migration 20240101000004 which changed users to use firebase_uid as PK

-- Update the audit trigger function to handle tables with different primary key types
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
  v_resource_id_text TEXT;
BEGIN
  -- Determine action type
  IF TG_OP = 'INSERT' THEN
    v_action := 'create';
    v_new_values := to_jsonb(NEW);
    
    -- Handle users table (uses firebase_uid as PK, not id)
    IF TG_TABLE_NAME = 'users' THEN
      -- For users table, store firebase_uid in metadata since resource_id is UUID type
      v_resource_id := NULL;  -- Can't convert firebase_uid (VARCHAR) to UUID
      v_resource_id_text := NEW.firebase_uid;
    ELSE
      -- For other tables, try to get id as UUID
      BEGIN
        -- Use to_jsonb to convert record to jsonb first
        v_resource_id := (to_jsonb(NEW)->>'id')::UUID;
        v_resource_id_text := NULL;
      EXCEPTION WHEN OTHERS THEN
        -- If id doesn't exist or is not UUID, set to NULL and store in metadata
        v_resource_id := NULL;
        v_resource_id_text := to_jsonb(NEW)->>'id';
      END;
    END IF;
    
    v_old_values := NULL;
    
  ELSIF TG_OP = 'UPDATE' THEN
    v_action := 'update';
    v_old_values := to_jsonb(OLD);
    v_new_values := to_jsonb(NEW);
    
    -- Handle users table
    IF TG_TABLE_NAME = 'users' THEN
      v_resource_id := NULL;
      v_resource_id_text := NEW.firebase_uid;
    ELSE
      BEGIN
        -- Use to_jsonb to convert record to jsonb first
        v_resource_id := (to_jsonb(NEW)->>'id')::UUID;
        v_resource_id_text := NULL;
      EXCEPTION WHEN OTHERS THEN
        v_resource_id := NULL;
        v_resource_id_text := to_jsonb(NEW)->>'id';
      END;
    END IF;
    
  ELSIF TG_OP = 'DELETE' THEN
    v_action := 'delete';
    v_old_values := to_jsonb(OLD);
    v_new_values := NULL;
    
    -- Handle users table
    IF TG_TABLE_NAME = 'users' THEN
      v_resource_id := NULL;
      v_resource_id_text := OLD.firebase_uid;
    ELSE
      BEGIN
        -- Use to_jsonb to convert record to jsonb first
        v_resource_id := (to_jsonb(OLD)->>'id')::UUID;
        v_resource_id_text := NULL;
      EXCEPTION WHEN OTHERS THEN
        v_resource_id := NULL;
        v_resource_id_text := to_jsonb(OLD)->>'id';
      END;
    END IF;
  END IF;
  
  -- Create audit log entry
  -- Cast TG_TABLE_NAME to VARCHAR to match function signature
  PERFORM public.create_audit_log(
    p_action := (v_action || '_' || TG_TABLE_NAME)::VARCHAR(100),
    p_resource_type := TG_TABLE_NAME::VARCHAR(50),
    p_resource_id := v_resource_id,
    p_old_values := v_old_values,
    p_new_values := v_new_values,
    p_metadata := jsonb_build_object(
      'operation', TG_OP,
      'table', TG_TABLE_NAME::TEXT,
      'resource_id_text', COALESCE(v_resource_id_text, '')
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

-- Also update get_current_user_id function since users table no longer has id column
-- This function should return firebase_uid as TEXT, not UUID
-- Need to drop and recreate because we're changing the return type
-- Drop with CASCADE to handle any dependencies
DROP FUNCTION IF EXISTS public.get_current_user_id() CASCADE;

CREATE FUNCTION public.get_current_user_id()
RETURNS TEXT  -- Changed from UUID to TEXT
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  firebase_uid_text TEXT;
BEGIN
  -- Extract Firebase UID from JWT
  firebase_uid_text := public.firebase_uid();
  
  -- Return the firebase_uid directly (it's now the primary key)
  RETURN firebase_uid_text;
END;
$$;

-- Update create_audit_log function to accept TEXT user_id
-- Note: This requires changing the audit_logs.user_id column type or handling it differently
-- For now, we'll keep user_id as VARCHAR in the function but the table might need updating
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
  v_user_id TEXT;  -- Changed from UUID to TEXT
  v_firebase_uid TEXT;
  v_user_exists BOOLEAN;
BEGIN
  -- Get current user ID (now returns firebase_uid as TEXT)
  v_user_id := public.get_current_user_id();
  v_firebase_uid := public.firebase_uid();
  
  -- Check if user exists in users table (to avoid foreign key constraint violation)
  IF v_user_id IS NOT NULL THEN
    SELECT EXISTS(SELECT 1 FROM users WHERE firebase_uid = v_user_id) INTO v_user_exists;
    IF NOT v_user_exists THEN
      -- User doesn't exist yet, set to NULL to avoid foreign key constraint violation
      v_user_id := NULL;
    END IF;
  END IF;
  
  -- Generate log ID
  v_log_id := uuid_generate_v4();
  
  -- Insert audit log entry
  -- Note: audit_logs.user_id is VARCHAR(255) after firebase_uid migration
  -- user_id can be NULL if user doesn't exist in users table yet
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
    v_user_id,  -- NULL if user doesn't exist, otherwise the firebase_uid
    p_action,
    p_resource_type,
    p_resource_id,
    p_old_values,
    p_new_values,
    NULL, -- ip_address
    NULL, -- user_agent
    COALESCE(p_metadata, '{}'::JSONB) || 
      jsonb_build_object('firebase_uid', COALESCE(v_firebase_uid, '')),
    CURRENT_TIMESTAMP
  );
  
  RETURN v_log_id;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.create_audit_log(VARCHAR, VARCHAR, UUID, JSONB, JSONB, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_audit_log(VARCHAR, VARCHAR, UUID, JSONB, JSONB, JSONB) TO anon;

-- Grant execute permission for get_current_user_id
GRANT EXECUTE ON FUNCTION public.get_current_user_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_current_user_id() TO anon;

-- Add comment for documentation
COMMENT ON FUNCTION public.audit_trigger_function() IS 
'Automatically logs INSERT, UPDATE, and DELETE operations. Updated to work with firebase_uid schema where users table uses firebase_uid as primary key instead of UUID id.';

COMMENT ON FUNCTION public.get_current_user_id() IS 
'Returns the current user firebase_uid as TEXT. Updated to work with firebase_uid schema.';

