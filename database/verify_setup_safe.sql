-- Safe Verification Queries - These won't fail if run multiple times
-- Run these in Supabase SQL Editor to verify your database setup

-- 1. Check all tables were created (should show ~25+ tables)
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

-- 3. Verify seed data was inserted (safe queries - won't error)
SELECT 
    'Service Categories' as data_type, 
    COUNT(*) as count,
    CASE WHEN COUNT(*) = 22 THEN '✅ Correct' ELSE '⚠️ Expected 22' END as status
FROM service_categories
UNION ALL
SELECT 
    'Notification Channels', 
    COUNT(*),
    CASE WHEN COUNT(*) = 8 THEN '✅ Correct' ELSE '⚠️ Expected 8' END
FROM notification_channels
UNION ALL
SELECT 
    'Notification Templates', 
    COUNT(*),
    CASE WHEN COUNT(*) = 10 THEN '✅ Correct' ELSE '⚠️ Expected 10' END
FROM notification_templates
UNION ALL
SELECT 
    'System Settings', 
    COUNT(*),
    CASE WHEN COUNT(*) = 10 THEN '✅ Correct' ELSE '⚠️ Expected 10' END
FROM system_settings;

-- 4. Quick summary - total tables count
SELECT 
    COUNT(*) as total_tables,
    CASE 
        WHEN COUNT(*) >= 25 THEN '✅ Good - All tables created'
        WHEN COUNT(*) >= 20 THEN '⚠️ Some tables missing'
        ELSE '❌ Many tables missing'
    END as status
FROM information_schema.tables
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE';

-- 5. Check key tables exist
SELECT 
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN '✅' ELSE '❌' END || ' users',
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'bookings') THEN '✅' ELSE '❌' END || ' bookings',
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payment_records') THEN '✅' ELSE '❌' END || ' payment_records',
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'professional_balances') THEN '✅' ELSE '❌' END || ' professional_balances',
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'service_packages') THEN '✅' ELSE '❌' END || ' service_packages';

