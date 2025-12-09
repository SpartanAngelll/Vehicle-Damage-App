-- Verification Queries for Supabase Database Setup
-- Run these queries to verify your database was set up correctly

-- 1. Check all tables were created
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 2. Check extensions were enabled
SELECT extname, extversion 
FROM pg_extension 
WHERE extname IN ('uuid-ossp', 'pg_trgm');

-- 3. Verify seed data was inserted
SELECT 'Service Categories' as table_name, COUNT(*) as count FROM service_categories
UNION ALL
SELECT 'Notification Channels', COUNT(*) FROM notification_channels
UNION ALL
SELECT 'Notification Templates', COUNT(*) FROM notification_templates
UNION ALL
SELECT 'System Settings', COUNT(*) FROM system_settings;

-- 4. Check indexes were created
SELECT 
    schemaname,
    tablename,
    indexname
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 5. Check triggers were created
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- 6. Quick count of all tables (should be around 25+ tables)
SELECT COUNT(*) as total_tables
FROM information_schema.tables
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE';

