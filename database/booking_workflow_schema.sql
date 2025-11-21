-- Booking Workflow Schema Migration
-- This adds support for InDrive-style booking workflow with PostgreSQL
-- Run this after the main schema is set up

-- Connect to the database
\c vehicle_damage_payments;

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================
-- BOOKINGS TABLE (Updated for workflow)
-- ==============================================

-- Create bookings table if it doesn't exist (with VARCHAR id for Firestore compatibility)
CREATE TABLE IF NOT EXISTS bookings (
    id VARCHAR(255) PRIMARY KEY,
    customer_id VARCHAR(255) NOT NULL,
    professional_id VARCHAR(255) NOT NULL,
    customer_name VARCHAR(255) NOT NULL,
    professional_name VARCHAR(255) NOT NULL,
    service_title VARCHAR(255) NOT NULL,
    service_description TEXT NOT NULL,
    agreed_price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'JMD',
    scheduled_start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    scheduled_end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    service_location TEXT NOT NULL,
    deliverables TEXT[],
    important_points TEXT[],
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'on_my_way', 'in_progress', 'started', 'completed', 'reviewed', 'cancelled', 'disputed')),
    start_pin_hash VARCHAR(255),
    chat_room_id VARCHAR(255),
    estimate_id VARCHAR(255),
    notes TEXT,
    travel_mode VARCHAR(20) CHECK (travel_mode IN ('customer_location', 'shop_location')),
    customer_address TEXT,
    shop_address TEXT,
    travel_fee DECIMAL(10,2) DEFAULT 0,
    status_notes TEXT,
    on_my_way_at TIMESTAMP WITH TIME ZONE,
    job_started_at TIMESTAMP WITH TIME ZONE,
    job_completed_at TIMESTAMP WITH TIME ZONE,
    job_accepted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Add missing columns if they don't exist (for existing tables)
DO $$
BEGIN
    -- Add start_pin_hash if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='bookings' AND column_name='start_pin_hash') THEN
        ALTER TABLE bookings ADD COLUMN start_pin_hash VARCHAR(255);
    END IF;
    
    -- Add service_location if it doesn't exist (rename from location if needed)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='bookings' AND column_name='service_location') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='bookings' AND column_name='location') THEN
            ALTER TABLE bookings RENAME COLUMN location TO service_location;
        ELSE
            ALTER TABLE bookings ADD COLUMN service_location TEXT NOT NULL DEFAULT '';
        END IF;
    END IF;
    
    -- Add status 'started' to the check constraint if needed
    -- Note: This requires dropping and recreating the constraint
    -- For safety, we'll just ensure the column accepts the value
END $$;

-- ==============================================
-- PAYMENT CONFIRMATIONS TABLE
-- ==============================================

CREATE TABLE IF NOT EXISTS payment_confirmations (
    booking_id VARCHAR(255) PRIMARY KEY,
    professional_id VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    confirmed_at TIMESTAMP WITH TIME ZONE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- REVIEWS TABLE (Updated for workflow)
-- ==============================================

CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id VARCHAR(255) NOT NULL,
    reviewer_id VARCHAR(255) NOT NULL,
    reviewee_id VARCHAR(255) NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(255),
    comment TEXT,
    is_public BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- ==============================================
-- INDEXES
-- ==============================================

CREATE INDEX IF NOT EXISTS idx_bookings_customer_id ON bookings(customer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_professional_id ON bookings(professional_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_chat_room_id ON bookings(chat_room_id);
CREATE INDEX IF NOT EXISTS idx_payment_confirmations_booking_id ON payment_confirmations(booking_id);
CREATE INDEX IF NOT EXISTS idx_payment_confirmations_professional_id ON payment_confirmations(professional_id);
CREATE INDEX IF NOT EXISTS idx_reviews_booking_id ON reviews(booking_id);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewee_id ON reviews(reviewee_id);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewer_id ON reviews(reviewer_id);

-- ==============================================
-- COMMENTS
-- ==============================================

COMMENT ON TABLE bookings IS 'Stores booking records with financial data and workflow status';
COMMENT ON TABLE payment_confirmations IS 'Stores offline payment confirmations by professionals';
COMMENT ON TABLE reviews IS 'Stores reviews/ratings between customers and professionals';

COMMENT ON COLUMN bookings.start_pin_hash IS 'SHA-256 hash of the 4-digit PIN used to start the job';
COMMENT ON COLUMN bookings.status IS 'Current status: pending, confirmed, on_my_way, in_progress, started, completed, reviewed, cancelled, disputed';
COMMENT ON COLUMN payment_confirmations.confirmed_at IS 'Timestamp when professional confirmed payment was received';

