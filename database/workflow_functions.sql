-- Workflow functions for booking system

-- Function: create_job_request
CREATE OR REPLACE FUNCTION create_job_request(
  p_customer_id VARCHAR(255),
  p_service_category_id UUID,
  p_title VARCHAR(255),
  p_description TEXT,
  p_location TEXT,
  p_budget_min DECIMAL(10, 2) DEFAULT NULL,
  p_budget_max DECIMAL(10, 2) DEFAULT NULL,
  p_priority VARCHAR(20) DEFAULT 'normal'
)
RETURNS UUID AS $$
DECLARE
  v_request_id UUID;
BEGIN
  v_request_id := uuid_generate_v4();
  
  INSERT INTO job_requests (
    id, customer_id, service_category_id, title, description,
    location, budget_min, budget_max, priority, status
  ) VALUES (
    v_request_id, p_customer_id, p_service_category_id, p_title, p_description,
    p_location, p_budget_min, p_budget_max, p_priority, 'pending'
  );
  
  RETURN v_request_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: accept_request (creates booking and chat room)
CREATE OR REPLACE FUNCTION accept_request(
  p_estimate_id UUID,
  p_customer_id VARCHAR(255)
)
RETURNS VARCHAR(255) AS $$
DECLARE
  v_booking_id VARCHAR(255);
  v_estimate RECORD;
  v_job_request RECORD;
  v_customer_name VARCHAR(255);
  v_professional_name VARCHAR(255);
  v_chat_room_id UUID;
BEGIN
  SELECT * INTO v_estimate FROM estimates WHERE id = p_estimate_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Estimate not found';
  END IF;
  
  SELECT * INTO v_job_request FROM job_requests WHERE id = v_estimate.job_request_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Job request not found';
  END IF;
  
  IF v_job_request.customer_id != p_customer_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  
  SELECT full_name INTO v_customer_name FROM users WHERE firebase_uid = p_customer_id;
  SELECT full_name INTO v_professional_name FROM users WHERE firebase_uid = v_estimate.professional_id;
  
  v_booking_id := uuid_generate_v4()::TEXT;
  v_chat_room_id := uuid_generate_v4();
  
  INSERT INTO bookings (
    id, estimate_id, customer_id, professional_id,
    customer_name, professional_name, service_title, service_description,
    agreed_price, currency, scheduled_start_time, scheduled_end_time,
    service_location, deliverables, important_points, status, chat_room_id
  ) VALUES (
    v_booking_id, p_estimate_id, p_customer_id, v_estimate.professional_id,
    COALESCE(v_customer_name, 'Customer'), COALESCE(v_professional_name, 'Professional'),
    v_estimate.title, v_estimate.description, v_estimate.price, v_estimate.currency,
    CURRENT_TIMESTAMP + INTERVAL '1 day', CURRENT_TIMESTAMP + INTERVAL '1 day 2 hours',
    v_job_request.location, v_estimate.deliverables, v_estimate.important_points,
    'confirmed', v_chat_room_id
  );
  
  UPDATE estimates SET status = 'accepted', updated_at = CURRENT_TIMESTAMP WHERE id = p_estimate_id;
  UPDATE job_requests SET status = 'in_progress', updated_at = CURRENT_TIMESTAMP WHERE id = v_job_request.id;
  
  INSERT INTO chat_rooms (
    id, booking_id, customer_id, professional_id, is_active
  ) VALUES (
    v_chat_room_id, v_booking_id, p_customer_id, v_estimate.professional_id, true
  );
  
  RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: complete_job
CREATE OR REPLACE FUNCTION complete_job(
  p_booking_id VARCHAR(255),
  p_professional_id VARCHAR(255),
  p_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_booking RECORD;
BEGIN
  SELECT * INTO v_booking FROM bookings WHERE id = p_booking_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;
  
  IF v_booking.professional_id != p_professional_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  
  UPDATE bookings SET
    status = 'completed',
    job_completed_at = CURRENT_TIMESTAMP,
    status_notes = p_notes,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = p_booking_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: record_payment
CREATE OR REPLACE FUNCTION record_payment(
  p_booking_id VARCHAR(255),
  p_type VARCHAR(50),
  p_amount DECIMAL(10, 2),
  p_currency VARCHAR(10) DEFAULT 'JMD',
  p_payment_method VARCHAR(50) DEFAULT NULL,
  p_transaction_id VARCHAR(255) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_payment_id UUID;
  v_booking RECORD;
  v_balance RECORD;
BEGIN
  SELECT * INTO v_booking FROM bookings WHERE id = p_booking_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;
  
  v_payment_id := uuid_generate_v4();
  
  INSERT INTO payment_records (
    id, booking_id, type, amount, currency, status,
    payment_method, transaction_id, processed_at
  ) VALUES (
    v_payment_id, p_booking_id, p_type, p_amount, p_currency, 'completed',
    p_payment_method, p_transaction_id, CURRENT_TIMESTAMP
  );
  
  SELECT * INTO v_balance FROM professional_balances WHERE professional_id = v_booking.professional_id;
  
  IF FOUND THEN
    UPDATE professional_balances SET
      available_balance = available_balance + p_amount,
      total_earned = total_earned + p_amount,
      updated_at = CURRENT_TIMESTAMP
    WHERE professional_id = v_booking.professional_id;
  ELSE
    INSERT INTO professional_balances (
      professional_id, available_balance, total_earned, total_paid_out
    ) VALUES (
      v_booking.professional_id, p_amount, p_amount, 0
    );
  END IF;
  
  RETURN v_payment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: leave_review
CREATE OR REPLACE FUNCTION leave_review(
  p_booking_id VARCHAR(255),
  p_reviewer_id VARCHAR(255),
  p_rating INTEGER,
  p_title VARCHAR(255) DEFAULT NULL,
  p_comment TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_review_id UUID;
  v_booking RECORD;
  v_reviewee_id VARCHAR(255);
  v_avg_rating DECIMAL(3, 2);
  v_total_reviews INTEGER;
BEGIN
  SELECT * INTO v_booking FROM bookings WHERE id = p_booking_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;
  
  IF v_booking.customer_id = p_reviewer_id THEN
    v_reviewee_id := v_booking.professional_id;
  ELSE
    v_reviewee_id := v_booking.customer_id;
  END IF;
  
  v_review_id := uuid_generate_v4();
  
  INSERT INTO reviews (
    id, booking_id, reviewer_id, reviewee_id, rating, title, comment, is_public
  ) VALUES (
    v_review_id, p_booking_id, p_reviewer_id, v_reviewee_id, p_rating, p_title, p_comment, true
  );
  
  SELECT AVG(rating)::DECIMAL(3, 2), COUNT(*)::INTEGER
  INTO v_avg_rating, v_total_reviews
  FROM reviews WHERE reviewee_id = v_reviewee_id;
  
  UPDATE service_professionals SET
    average_rating = v_avg_rating,
    total_reviews = v_total_reviews,
    updated_at = CURRENT_TIMESTAMP
  WHERE user_id = v_reviewee_id;
  
  UPDATE bookings SET
    status = 'reviewed',
    updated_at = CURRENT_TIMESTAMP
  WHERE id = p_booking_id;
  
  RETURN v_review_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

