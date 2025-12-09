-- Verification queries for booking trigger fix migration
-- Run these in Supabase SQL Editor to verify the migration was applied correctly

-- 1. Check that the function exists and has the updated comment
SELECT 
    proname as function_name,
    pg_get_functiondef(oid) as function_definition
FROM pg_proc 
WHERE proname = 'populate_booking_related_tables'
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- 2. Check the function comment (should mention the fix)
SELECT 
    obj_description(oid, 'pg_proc') as function_comment
FROM pg_proc 
WHERE proname = 'populate_booking_related_tables'
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- 3. Verify the trigger is still attached to the bookings table
SELECT 
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND event_object_table = 'bookings'
AND trigger_name = 'trigger_populate_booking_tables';

-- 4. Check that chat_room_id column in bookings table is UUID type
SELECT 
    column_name,
    data_type,
    udt_name
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'bookings'
AND column_name = 'chat_room_id';

