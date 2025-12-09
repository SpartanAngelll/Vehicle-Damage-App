-- ==============================================
-- BOOKING AVAILABILITY SYSTEM
-- ==============================================

-- Professional availability schedule
CREATE TABLE IF NOT EXISTS professional_availability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    professional_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    day_of_week VARCHAR(20) NOT NULL CHECK (day_of_week IN ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday')),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    blocked_dates DATE[],
    slot_duration_minutes INTEGER DEFAULT 10,
    break_between_slots_minutes INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB,
    UNIQUE(professional_id, day_of_week)
);

-- Time slots for booking
CREATE TABLE IF NOT EXISTS time_slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    professional_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Booking conflicts tracking
CREATE TABLE IF NOT EXISTS booking_conflicts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    professional_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    conflict_type VARCHAR(50) NOT NULL CHECK (conflict_type IN ('double_booking', 'overlapping', 'insufficient_time')),
    existing_booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_professional_availability_professional_id ON professional_availability(professional_id);
CREATE INDEX IF NOT EXISTS idx_professional_availability_day_of_week ON professional_availability(day_of_week);

CREATE INDEX IF NOT EXISTS idx_time_slots_professional_id ON time_slots(professional_id);
CREATE INDEX IF NOT EXISTS idx_time_slots_start_time ON time_slots(start_time);
CREATE INDEX IF NOT EXISTS idx_time_slots_end_time ON time_slots(end_time);
CREATE INDEX IF NOT EXISTS idx_time_slots_available ON time_slots(is_available);
CREATE INDEX IF NOT EXISTS idx_time_slots_booking_id ON time_slots(booking_id);
CREATE INDEX IF NOT EXISTS idx_time_slots_professional_start ON time_slots(professional_id, start_time);

CREATE INDEX IF NOT EXISTS idx_booking_conflicts_professional_id ON booking_conflicts(professional_id);
CREATE INDEX IF NOT EXISTS idx_booking_conflicts_start_time ON booking_conflicts(start_time);
CREATE INDEX IF NOT EXISTS idx_booking_conflicts_detected_at ON booking_conflicts(detected_at);

-- Function to generate time slots for a professional
CREATE OR REPLACE FUNCTION generate_time_slots_for_professional(
    p_professional_id UUID,
    p_start_date DATE,
    p_end_date DATE
) RETURNS VOID AS $$
DECLARE
    availability_record RECORD;
    current_date DATE;
    current_time TIMESTAMP WITH TIME ZONE;
    slot_end_time TIMESTAMP WITH TIME ZONE;
    day_of_week_name TEXT;
BEGIN
    -- Clear existing time slots for the date range
    DELETE FROM time_slots 
    WHERE professional_id = p_professional_id 
    AND start_time >= p_start_date 
    AND start_time < p_end_date + INTERVAL '1 day';
    
    -- Generate slots for each day in the range
    current_date := p_start_date;
    WHILE current_date <= p_end_date LOOP
        day_of_week_name := LOWER(TO_CHAR(current_date, 'Day'));
        day_of_week_name := TRIM(day_of_week_name);
        
        -- Get availability for this day of week
        SELECT * INTO availability_record
        FROM professional_availability
        WHERE professional_id = p_professional_id
        AND day_of_week = day_of_week_name
        AND is_available = TRUE;
        
        -- If availability exists and date is not blocked
        IF FOUND AND NOT (current_date = ANY(availability_record.blocked_dates)) THEN
            -- Create start time for the day
            current_time := current_date + availability_record.start_time;
            
            -- Generate slots for this day
            WHILE current_time + INTERVAL '1 minute' * availability_record.slot_duration_minutes 
                  <= current_date + availability_record.end_time LOOP
                
                slot_end_time := current_time + INTERVAL '1 minute' * availability_record.slot_duration_minutes;
                
                -- Only create slots for future times
                IF current_time > NOW() THEN
                    INSERT INTO time_slots (
                        professional_id,
                        start_time,
                        end_time,
                        is_available,
                        created_at,
                        updated_at
                    ) VALUES (
                        p_professional_id,
                        current_time,
                        slot_end_time,
                        TRUE,
                        NOW(),
                        NOW()
                    );
                END IF;
                
                -- Move to next slot with break
                current_time := slot_end_time + INTERVAL '1 minute' * availability_record.break_between_slots_minutes;
            END LOOP;
        END IF;
        
        current_date := current_date + INTERVAL '1 day';
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to check for booking conflicts
CREATE OR REPLACE FUNCTION check_booking_conflicts(
    p_professional_id UUID,
    p_start_time TIMESTAMP WITH TIME ZONE,
    p_end_time TIMESTAMP WITH TIME ZONE,
    p_exclude_booking_id UUID DEFAULT NULL
) RETURNS TABLE(
    conflict_type TEXT,
    existing_booking_id UUID,
    message TEXT
) AS $$
BEGIN
    -- Check for overlapping bookings
    RETURN QUERY
    SELECT 
        'double_booking'::TEXT as conflict_type,
        b.id as existing_booking_id,
        'Time slot conflicts with existing booking from ' || 
        TO_CHAR(b.scheduled_start_time, 'HH12:MI AM') || ' to ' ||
        TO_CHAR(b.scheduled_end_time, 'HH12:MI AM') as message
    FROM bookings b
    WHERE b.professional_id = p_professional_id
    AND b.status IN ('pending', 'confirmed', 'in_progress')
    AND (p_exclude_booking_id IS NULL OR b.id != p_exclude_booking_id)
    AND p_start_time < b.scheduled_end_time
    AND p_end_time > b.scheduled_start_time;
    
    -- Check for insufficient time between bookings (if no overlapping conflicts)
    IF NOT FOUND THEN
        RETURN QUERY
        SELECT 
            'insufficient_time'::TEXT as conflict_type,
            b.id as existing_booking_id,
            'Insufficient time between bookings. Need at least 30 minutes between appointments.' as message
        FROM bookings b
        WHERE b.professional_id = p_professional_id
        AND b.status IN ('pending', 'confirmed', 'in_progress')
        AND (p_exclude_booking_id IS NULL OR b.id != p_exclude_booking_id)
        AND (
            (b.scheduled_end_time <= p_start_time AND p_start_time - b.scheduled_end_time < INTERVAL '30 minutes')
            OR
            (p_end_time <= b.scheduled_start_time AND b.scheduled_start_time - p_end_time < INTERVAL '30 minutes')
        )
        LIMIT 1;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to book a time slot
CREATE OR REPLACE FUNCTION book_time_slot(
    p_professional_id UUID,
    p_customer_id UUID,
    p_customer_name TEXT,
    p_professional_name TEXT,
    p_start_time TIMESTAMP WITH TIME ZONE,
    p_end_time TIMESTAMP WITH TIME ZONE,
    p_service_title TEXT,
    p_service_description TEXT,
    p_agreed_price DECIMAL(10,2),
    p_location TEXT,
    p_deliverables TEXT[] DEFAULT NULL,
    p_important_points TEXT[] DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    slot_id UUID;
    booking_id UUID;
    conflict_record RECORD;
BEGIN
    -- Check for conflicts
    FOR conflict_record IN 
        SELECT * FROM check_booking_conflicts(p_professional_id, p_start_time, p_end_time)
    LOOP
        RAISE EXCEPTION 'Booking conflict: %', conflict_record.message;
    END LOOP;
    
    -- Find available time slot
    SELECT id INTO slot_id
    FROM time_slots
    WHERE professional_id = p_professional_id
    AND start_time = p_start_time
    AND is_available = TRUE
    LIMIT 1;
    
    IF slot_id IS NULL THEN
        RAISE EXCEPTION 'No available time slot found for the requested time';
    END IF;
    
    -- Create booking
    booking_id := uuid_generate_v4();
    
    INSERT INTO bookings (
        id,
        estimate_id,
        chat_room_id,
        customer_id,
        professional_id,
        customer_name,
        professional_name,
        service_title,
        service_description,
        agreed_price,
        scheduled_start_time,
        scheduled_end_time,
        location,
        deliverables,
        important_points,
        status,
        notes,
        created_at,
        updated_at
    ) VALUES (
        booking_id,
        '', -- Will be set when estimate is created
        '', -- Will be set when chat room is created
        p_customer_id,
        p_professional_id,
        p_customer_name,
        p_professional_name,
        p_service_title,
        p_service_description,
        p_agreed_price,
        p_start_time,
        p_end_time,
        p_location,
        COALESCE(p_deliverables, ARRAY[]::TEXT[]),
        COALESCE(p_important_points, ARRAY[]::TEXT[]),
        'pending',
        p_notes,
        NOW(),
        NOW()
    );
    
    -- Update time slot to mark as booked
    UPDATE time_slots
    SET 
        is_available = FALSE,
        booking_id = booking_id,
        updated_at = NOW()
    WHERE id = slot_id;
    
    RETURN booking_id;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically generate time slots when availability is updated
CREATE OR REPLACE FUNCTION trigger_generate_time_slots()
RETURNS TRIGGER AS $$
BEGIN
    -- Generate time slots for the next 30 days
    PERFORM generate_time_slots_for_professional(
        NEW.professional_id,
        CURRENT_DATE,
        CURRENT_DATE + INTERVAL '30 days'
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_availability_updated
    AFTER INSERT OR UPDATE ON professional_availability
    FOR EACH ROW
    EXECUTE FUNCTION trigger_generate_time_slots();

-- Sample data for testing
INSERT INTO professional_availability (
    professional_id,
    day_of_week,
    start_time,
    end_time,
    is_available,
    slot_duration_minutes,
    break_between_slots_minutes
) VALUES 
-- This would be populated with actual professional IDs
-- Example for a professional with ID '123e4567-e89b-12d3-a456-426614174000'
-- ('123e4567-e89b-12d3-a456-426614174000', 'monday', '09:00', '17:00', TRUE, 60, 0),
-- ('123e4567-e89b-12d3-a456-426614174000', 'tuesday', '09:00', '17:00', TRUE, 60, 0),
-- ('123e4567-e89b-12d3-a456-426614174000', 'wednesday', '09:00', '17:00', TRUE, 60, 0),
-- ('123e4567-e89b-12d3-a456-426614174000', 'thursday', '09:00', '17:00', TRUE, 60, 0),
-- ('123e4567-e89b-12d3-a456-426614174000', 'friday', '09:00', '17:00', TRUE, 60, 0),
-- ('123e4567-e89b-12d3-a456-426614174000', 'saturday', '10:00', '15:00', TRUE, 60, 0),
-- ('123e4567-e89b-12d3-a456-426614174000', 'sunday', '10:00', '15:00', FALSE, 60, 0)
ON CONFLICT (professional_id, day_of_week) DO NOTHING;

