-- ==============================================
-- BOOKING DATA QUERIES FOR SUPABASE
-- ==============================================

-- 1. VIEW ALL BOOKINGS (Basic Info)
-- Shows all bookings with key information
SELECT 
    id,
    customer_id,
    professional_id,
    customer_name,
    professional_name,
    service_title,
    agreed_price,
    currency,
    status,
    scheduled_start_time,
    scheduled_end_time,
    service_location,
    created_at,
    updated_at
FROM bookings
ORDER BY created_at DESC;

-- 2. VIEW ALL BOOKINGS (Detailed)
-- Shows complete booking information including all fields
SELECT 
    id,
    customer_id,
    professional_id,
    customer_name,
    professional_name,
    service_title,
    service_description,
    agreed_price,
    currency,
    scheduled_start_time,
    scheduled_end_time,
    service_location,
    deliverables,
    important_points,
    status,
    travel_mode,
    customer_address,
    shop_address,
    travel_fee,
    notes,
    status_notes,
    on_my_way_at,
    job_started_at,
    job_completed_at,
    job_accepted_at,
    estimate_id,
    chat_room_id,
    created_at,
    updated_at
FROM bookings
ORDER BY created_at DESC;

-- 3. VIEW BOOKINGS BY STATUS
-- Filter bookings by status (e.g., 'confirmed', 'completed', 'pending')
SELECT 
    id,
    customer_name,
    professional_name,
    service_title,
    status,
    scheduled_start_time,
    scheduled_end_time,
    agreed_price,
    currency,
    created_at
FROM bookings
WHERE status = 'confirmed'  -- Change to: 'pending', 'confirmed', 'on_my_way', 'in_progress', 'completed', 'cancelled'
ORDER BY scheduled_start_time ASC;

-- 4. VIEW BOOKINGS FOR A SPECIFIC CUSTOMER
-- Replace 'YOUR_FIREBASE_UID' with the actual Firebase UID
SELECT 
    id,
    professional_name,
    service_title,
    status,
    scheduled_start_time,
    scheduled_end_time,
    agreed_price,
    currency,
    service_location,
    created_at
FROM bookings
WHERE customer_id = 'YOUR_FIREBASE_UID'
ORDER BY scheduled_start_time DESC;

-- 5. VIEW BOOKINGS FOR A SPECIFIC PROFESSIONAL
-- Replace 'YOUR_FIREBASE_UID' with the actual Firebase UID
SELECT 
    id,
    customer_name,
    service_title,
    status,
    scheduled_start_time,
    scheduled_end_time,
    agreed_price,
    currency,
    service_location,
    created_at
FROM bookings
WHERE professional_id = 'YOUR_FIREBASE_UID'
ORDER BY scheduled_start_time DESC;

-- 6. VIEW UPCOMING BOOKINGS
-- Shows bookings scheduled for the future
SELECT 
    id,
    customer_name,
    professional_name,
    service_title,
    status,
    scheduled_start_time,
    scheduled_end_time,
    agreed_price,
    currency,
    service_location
FROM bookings
WHERE scheduled_start_time > NOW()
    AND status IN ('pending', 'confirmed', 'on_my_way')
ORDER BY scheduled_start_time ASC;

-- 7. VIEW RECENT BOOKINGS (Last 30 Days)
SELECT 
    id,
    customer_name,
    professional_name,
    service_title,
    status,
    scheduled_start_time,
    scheduled_end_time,
    agreed_price,
    currency,
    created_at
FROM bookings
WHERE created_at >= NOW() - INTERVAL '30 days'
ORDER BY created_at DESC;

-- 8. VIEW BOOKINGS WITH TRAVEL FEES
-- Shows bookings that include travel fees
SELECT 
    id,
    customer_name,
    professional_name,
    service_title,
    travel_mode,
    customer_address,
    shop_address,
    travel_fee,
    agreed_price,
    currency,
    (agreed_price + travel_fee) as total_price
FROM bookings
WHERE travel_fee > 0
ORDER BY created_at DESC;

-- 9. VIEW BOOKING STATISTICS
-- Summary statistics about bookings
SELECT 
    COUNT(*) as total_bookings,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_bookings,
    COUNT(*) FILTER (WHERE status = 'confirmed') as confirmed_bookings,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_bookings,
    COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled_bookings,
    SUM(agreed_price) as total_revenue,
    AVG(agreed_price) as average_booking_price,
    MIN(created_at) as first_booking_date,
    MAX(created_at) as latest_booking_date
FROM bookings;

-- 10. VIEW BOOKINGS WITH WORKFLOW TIMESTAMPS
-- Shows bookings with their workflow progression timestamps
SELECT 
    id,
    customer_name,
    professional_name,
    service_title,
    status,
    scheduled_start_time,
    on_my_way_at,
    job_started_at,
    job_completed_at,
    job_accepted_at,
    CASE 
        WHEN job_completed_at IS NOT NULL THEN 'Completed'
        WHEN job_started_at IS NOT NULL THEN 'In Progress'
        WHEN on_my_way_at IS NOT NULL THEN 'On My Way'
        WHEN status = 'confirmed' THEN 'Confirmed'
        ELSE 'Pending'
    END as workflow_status
FROM bookings
WHERE status IN ('confirmed', 'on_my_way', 'in_progress', 'completed')
ORDER BY scheduled_start_time DESC;

-- 11. VIEW BOOKINGS BY DATE RANGE
-- Replace dates with your desired range
SELECT 
    id,
    customer_name,
    professional_name,
    service_title,
    status,
    scheduled_start_time,
    scheduled_end_time,
    agreed_price,
    currency
FROM bookings
WHERE scheduled_start_time >= '2025-01-01'::timestamp
    AND scheduled_start_time < '2025-02-01'::timestamp
ORDER BY scheduled_start_time ASC;

-- 12. VIEW BOOKINGS WITH DELIVERABLES
-- Shows bookings that have deliverables specified
SELECT 
    id,
    customer_name,
    professional_name,
    service_title,
    deliverables,
    important_points,
    status,
    scheduled_start_time
FROM bookings
WHERE deliverables IS NOT NULL 
    AND array_length(deliverables, 1) > 0
ORDER BY created_at DESC;

-- 13. QUICK COUNT BY STATUS
-- Quick overview of booking statuses
SELECT 
    status,
    COUNT(*) as count
FROM bookings
GROUP BY status
ORDER BY count DESC;

-- 14. VIEW BOOKINGS WITH CUSTOMER AND PROFESSIONAL INFO
-- Join with users table if you want to see user details
-- Note: This requires the users table to have matching firebase_uid
SELECT 
    b.id,
    b.customer_id,
    b.professional_id,
    b.customer_name,
    b.professional_name,
    b.service_title,
    b.status,
    b.scheduled_start_time,
    b.agreed_price,
    b.currency,
    u_customer.email as customer_email,
    u_professional.email as professional_email
FROM bookings b
LEFT JOIN users u_customer ON b.customer_id = u_customer.firebase_uid
LEFT JOIN users u_professional ON b.professional_id = u_professional.firebase_uid
ORDER BY b.created_at DESC;

-- 15. VIEW BOOKING WITH ESTIMATE AND CHAT ROOM INFO
-- Shows bookings with related estimate and chat room IDs
SELECT 
    b.id as booking_id,
    b.customer_name,
    b.professional_name,
    b.service_title,
    b.status,
    b.estimate_id,
    b.chat_room_id,
    b.scheduled_start_time,
    b.agreed_price,
    b.currency
FROM bookings b
WHERE b.estimate_id IS NOT NULL
    OR b.chat_room_id IS NOT NULL
ORDER BY b.created_at DESC;

