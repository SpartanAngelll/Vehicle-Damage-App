-- ==============================================
-- VERIFICATION QUERIES FOR ESTIMATE TO RATING WORKFLOW
-- Booking ID: 12663430-6b99-4de6-8a53-fb1e7adb639e
-- Professional ID: VZ2bAvAX0ThZ4QArKwhDnD37u652
-- Customer ID: WhprgUxoPvU9nDTiQE3Hkj5PD1u1
-- Rating: 4
-- ==============================================

-- 1. VERIFY REVIEW RECORD
-- Check if the review was created in the reviews table
SELECT 
    id,
    booking_id,
    reviewer_id,
    reviewee_id,
    rating,
    title,
    comment,
    is_public,
    created_at,
    updated_at,
    metadata
FROM reviews
WHERE booking_id = '12663430-6b99-4de6-8a53-fb1e7adb639e'
ORDER BY created_at DESC;

-- Alternative: Find review by PostgreSQL ID (from logs)
SELECT 
    id,
    booking_id,
    reviewer_id,
    reviewee_id,
    rating,
    title,
    comment,
    is_public,
    created_at,
    updated_at
FROM reviews
WHERE id = 'add19376-df4a-42f5-b5c2-539b16093f53';

-- 2. VERIFY BOOKING RECORD AND STATUS
-- Check the booking record and its current status
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
    travel_mode,
    customer_address,
    shop_address,
    travel_fee,
    job_started_at,
    job_completed_at,
    job_accepted_at,
    created_at,
    updated_at
FROM bookings
WHERE id = '12663430-6b99-4de6-8a53-fb1e7adb639e';

-- 3. VERIFY ALL REVIEWS FOR THIS BOOKING
-- Check if there are multiple reviews (customer review + professional review)
SELECT 
    r.id,
    r.booking_id,
    r.reviewer_id,
    r.reviewee_id,
    r.rating,
    r.title,
    r.comment,
    r.created_at,
    CASE 
        WHEN r.reviewer_id = 'VZ2bAvAX0ThZ4QArKwhDnD37u652' THEN 'Professional Review'
        WHEN r.reviewer_id = 'WhprgUxoPvU9nDTiQE3Hkj5PD1u1' THEN 'Customer Review'
        ELSE 'Unknown'
    END as review_type
FROM reviews r
WHERE r.booking_id = '12663430-6b99-4de6-8a53-fb1e7adb639e'
ORDER BY r.created_at DESC;

-- 4. VERIFY PAYMENT CONFIRMATION
-- Check if payment was confirmed for this booking
SELECT 
    booking_id,
    professional_id,
    amount,
    confirmed_at,
    notes,
    created_at
FROM payment_confirmations
WHERE booking_id = '12663430-6b99-4de6-8a53-fb1e7adb639e';

-- 5. VERIFY WORKFLOW COMPLETENESS
-- Check the complete workflow status for this booking
SELECT 
    b.id as booking_id,
    b.status,
    b.agreed_price,
    b.currency,
    b.job_started_at,
    b.job_completed_at,
    b.job_accepted_at,
    CASE 
        WHEN pc.booking_id IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END as payment_confirmed,
    pc.confirmed_at as payment_confirmed_at,
    COUNT(r.id) as review_count,
    MAX(CASE WHEN r.reviewer_id = b.professional_id THEN r.rating END) as professional_rating,
    MAX(CASE WHEN r.reviewer_id = b.customer_id THEN r.rating END) as customer_rating
FROM bookings b
LEFT JOIN payment_confirmations pc ON b.id = pc.booking_id
LEFT JOIN reviews r ON b.id = r.booking_id
WHERE b.id = '12663430-6b99-4de6-8a53-fb1e7adb639e'
GROUP BY b.id, b.status, b.agreed_price, b.currency, b.job_started_at, 
         b.job_completed_at, b.job_accepted_at, pc.booking_id, pc.confirmed_at;

-- 6. VERIFY ALL REVIEWS BY PROFESSIONAL
-- Check all reviews submitted by this professional
SELECT 
    r.id,
    r.booking_id,
    r.reviewer_id,
    r.reviewee_id,
    r.rating,
    r.comment,
    r.created_at,
    b.service_title,
    b.status as booking_status
FROM reviews r
JOIN bookings b ON r.booking_id = b.id
WHERE r.reviewer_id = 'VZ2bAvAX0ThZ4QArKwhDnD37u652'
ORDER BY r.created_at DESC
LIMIT 10;

-- 7. VERIFY ALL REVIEWS FOR CUSTOMER
-- Check all reviews received by this customer
SELECT 
    r.id,
    r.booking_id,
    r.reviewer_id,
    r.reviewee_id,
    r.rating,
    r.comment,
    r.created_at,
    b.service_title,
    b.status as booking_status
FROM reviews r
JOIN bookings b ON r.booking_id = b.id
WHERE r.reviewee_id = 'WhprgUxoPvU9nDTiQE3Hkj5PD1u1'
ORDER BY r.created_at DESC
LIMIT 10;

-- 8. VERIFY RECENT REVIEWS (LAST 24 HOURS)
-- Check all reviews created in the last 24 hours
SELECT 
    r.id,
    r.booking_id,
    r.reviewer_id,
    r.reviewee_id,
    r.rating,
    r.title,
    r.comment,
    r.created_at,
    b.service_title,
    b.customer_name,
    b.professional_name
FROM reviews r
JOIN bookings b ON r.booking_id = b.id
WHERE r.created_at >= NOW() - INTERVAL '24 hours'
ORDER BY r.created_at DESC;

-- 9. VERIFY BOOKING STATUS TRANSITIONS
-- Check booking status history (if you have an audit log table)
-- This query checks the current status and timestamps
SELECT 
    id,
    status,
    created_at,
    updated_at,
    job_started_at,
    job_completed_at,
    job_accepted_at,
    CASE 
        WHEN job_started_at IS NOT NULL THEN 'Job Started'
        ELSE 'Not Started'
    END as start_status,
    CASE 
        WHEN job_completed_at IS NOT NULL THEN 'Job Completed'
        ELSE 'Not Completed'
    END as completion_status,
    CASE 
        WHEN job_accepted_at IS NOT NULL THEN 'Job Accepted'
        ELSE 'Not Accepted'
    END as acceptance_status
FROM bookings
WHERE id = '12663430-6b99-4de6-8a53-fb1e7adb639e';

-- 10. SUMMARY STATISTICS FOR THIS BOOKING
-- Get a complete summary of the booking workflow
SELECT 
    'Booking ID' as metric,
    '12663430-6b99-4de6-8a53-fb1e7adb639e' as value
UNION ALL
SELECT 
    'Current Status',
    status::text
FROM bookings
WHERE id = '12663430-6b99-4de6-8a53-fb1e7adb639e'
UNION ALL
SELECT 
    'Agreed Price',
    CONCAT(agreed_price::text, ' ', currency)
FROM bookings
WHERE id = '12663430-6b99-4de6-8a53-fb1e7adb639e'
UNION ALL
SELECT 
    'Payment Confirmed',
    CASE WHEN EXISTS (
        SELECT 1 FROM payment_confirmations 
        WHERE booking_id = '12663430-6b99-4de6-8a53-fb1e7adb639e'
    ) THEN 'Yes' ELSE 'No' END
UNION ALL
SELECT 
    'Professional Review Submitted',
    CASE WHEN EXISTS (
        SELECT 1 FROM reviews 
        WHERE booking_id = '12663430-6b99-4de6-8a53-fb1e7adb639e'
        AND reviewer_id = 'VZ2bAvAX0ThZ4QArKwhDnD37u652'
    ) THEN 'Yes' ELSE 'No' END
UNION ALL
SELECT 
    'Customer Review Submitted',
    CASE WHEN EXISTS (
        SELECT 1 FROM reviews 
        WHERE booking_id = '12663430-6b99-4de6-8a53-fb1e7adb639e'
        AND reviewer_id = 'WhprgUxoPvU9nDTiQE3Hkj5PD1u1'
    ) THEN 'Yes' ELSE 'No' END
UNION ALL
SELECT 
    'Total Reviews',
    COUNT(*)::text
FROM reviews
WHERE booking_id = '12663430-6b99-4de6-8a53-fb1e7adb639e';

