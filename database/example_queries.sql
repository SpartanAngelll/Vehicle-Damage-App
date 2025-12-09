-- Example queries with Firebase JWT authentication
-- These queries assume Firebase token is passed in Authorization header

-- Example 1: Get current user profile
SELECT * FROM users 
WHERE firebase_uid = auth.firebase_uid();

-- Example 2: Create user profile after Firebase signup
INSERT INTO users (firebase_uid, email, full_name, role, created_at)
VALUES (
  auth.firebase_uid(),
  'user@example.com',
  'John Doe',
  'owner',
  CURRENT_TIMESTAMP
)
ON CONFLICT (firebase_uid) DO UPDATE SET
  email = EXCLUDED.email,
  full_name = EXCLUDED.full_name,
  updated_at = CURRENT_TIMESTAMP;

-- Example 3: Get user's bookings
SELECT * FROM bookings 
WHERE customer_id = auth.firebase_uid() 
   OR professional_id = auth.firebase_uid()
ORDER BY created_at DESC;

-- Example 4: Create job request
INSERT INTO job_requests (
  customer_id,
  service_category_id,
  title,
  description,
  location,
  budget_min,
  budget_max,
  status
)
VALUES (
  auth.firebase_uid(),
  'category-uuid-here',
  'Fix car door',
  'Door dent needs repair',
  '123 Main St',
  100.00,
  500.00,
  'pending'
)
RETURNING *;

-- Example 5: Professional creates estimate
INSERT INTO estimates (
  job_request_id,
  professional_id,
  title,
  description,
  price,
  currency,
  status
)
VALUES (
  'job-request-uuid',
  auth.firebase_uid(),
  'Door Repair Estimate',
  'Professional door repair service',
  350.00,
  'JMD',
  'pending'
)
RETURNING *;

-- Example 6: Accept estimate and create booking
WITH accepted_estimate AS (
  UPDATE estimates
  SET status = 'accepted',
      updated_at = CURRENT_TIMESTAMP
  WHERE id = 'estimate-uuid'
    AND EXISTS (
      SELECT 1 FROM job_requests 
      WHERE job_requests.id = estimates.job_request_id 
      AND job_requests.customer_id = auth.firebase_uid()
    )
  RETURNING *
)
INSERT INTO bookings (
  id,
  estimate_id,
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
  status
)
SELECT 
  gen_random_uuid()::TEXT,
  ae.id,
  jr.customer_id,
  ae.professional_id,
  u1.full_name,
  u2.full_name,
  ae.title,
  ae.description,
  ae.price,
  ae.currency,
  CURRENT_TIMESTAMP + INTERVAL '1 day',
  CURRENT_TIMESTAMP + INTERVAL '1 day' + INTERVAL '2 hours',
  jr.location,
  'confirmed'
FROM accepted_estimate ae
JOIN job_requests jr ON jr.id = ae.job_request_id
JOIN users u1 ON u1.firebase_uid = jr.customer_id
JOIN users u2 ON u2.firebase_uid = ae.professional_id
RETURNING *;

-- Example 7: Update booking status
UPDATE bookings
SET status = 'in_progress',
    job_started_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP
WHERE id = 'booking-id'
  AND (
    customer_id = auth.firebase_uid() 
    OR professional_id = auth.firebase_uid()
  )
RETURNING *;

-- Example 8: Get professional balance
SELECT * FROM professional_balances
WHERE professional_id = auth.firebase_uid();

-- Example 9: Create payment record
INSERT INTO payment_records (
  booking_id,
  type,
  amount,
  currency,
  status,
  payment_method
)
SELECT 
  'booking-id',
  'full',
  b.agreed_price,
  b.currency,
  'completed',
  'cash'
FROM bookings b
WHERE b.id = 'booking-id'
  AND (
    b.customer_id = auth.firebase_uid() 
    OR b.professional_id = auth.firebase_uid()
  )
RETURNING *;

-- Example 10: Create review
INSERT INTO reviews (
  booking_id,
  reviewer_id,
  reviewee_id,
  rating,
  title,
  comment
)
SELECT 
  'booking-id',
  auth.firebase_uid(),
  CASE 
    WHEN b.customer_id = auth.firebase_uid() THEN b.professional_id
    ELSE b.customer_id
  END,
  5,
  'Great service!',
  'Very professional and timely.'
FROM bookings b
WHERE b.id = 'booking-id'
  AND (
    b.customer_id = auth.firebase_uid() 
    OR b.professional_id = auth.firebase_uid()
  )
  AND b.status = 'completed'
RETURNING *;

-- Example 11: Get notifications
SELECT * FROM notifications
WHERE user_id = auth.firebase_uid()
ORDER BY created_at DESC
LIMIT 50;

-- Example 12: Mark notification as read
UPDATE notifications
SET status = 'read',
    read_at = CURRENT_TIMESTAMP
WHERE id = 'notification-id'
  AND user_id = auth.firebase_uid()
RETURNING *;

-- Example 13: Get service packages for professional
SELECT * FROM service_packages
WHERE professional_id = auth.firebase_uid()
  AND is_active = true
ORDER BY sort_order, created_at;

-- Example 14: Create payout request
INSERT INTO payouts (
  professional_id,
  amount,
  currency,
  status
)
SELECT 
  auth.firebase_uid(),
  pb.available_balance,
  'JMD',
  'pending'
FROM professional_balances pb
WHERE pb.professional_id = auth.firebase_uid()
  AND pb.available_balance > 0
RETURNING *;

-- Example 15: Get chat room metadata
SELECT * FROM chat_rooms
WHERE customer_id = auth.firebase_uid() 
   OR professional_id = auth.firebase_uid()
ORDER BY last_message_at DESC NULLS LAST;

