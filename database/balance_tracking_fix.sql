-- Balance Tracking Fix Migration
-- This migration fixes the balance tracking issues after credit card payments

-- Connect to the database
\c vehicle_damage_payments;

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop the old payments table if it exists (as mentioned by user)
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS payment_status_history CASCADE;

-- Create payment_records table (if not exists)
CREATE TABLE IF NOT EXISTS payment_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID,
    booking_id VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL DEFAULT 'full',
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'JMD',
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    payment_method VARCHAR(50),
    transaction_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    metadata JSONB,
    deposit_percentage INTEGER DEFAULT 0,
    total_amount NUMERIC
);

-- Create payment status history table
CREATE TABLE IF NOT EXISTS payment_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_id UUID NOT NULL REFERENCES payment_records(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(255),
    notes TEXT
);

-- Create invoices table (if not exists)
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id VARCHAR(255) NOT NULL UNIQUE,
    customer_id VARCHAR(255) NOT NULL,
    professional_id VARCHAR(255) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'JMD',
    deposit_percentage INTEGER DEFAULT 0,
    deposit_amount DECIMAL(10,2),
    balance_amount DECIMAL(10,2),
    status VARCHAR(20) NOT NULL DEFAULT 'sent',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP WITH TIME ZONE,
    due_date TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    metadata JSONB
);

-- Create professional_balances table (if not exists)
CREATE TABLE IF NOT EXISTS professional_balances (
    professional_id VARCHAR(255) PRIMARY KEY,
    available_balance DECIMAL(10,2) NOT NULL DEFAULT 0.0 CHECK (available_balance >= 0),
    total_earned DECIMAL(10,2) NOT NULL DEFAULT 0.0,
    total_paid_out DECIMAL(10,2) NOT NULL DEFAULT 0.0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create payouts table (if not exists)
CREATE TABLE IF NOT EXISTS payouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    professional_id VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'JMD',
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'success', 'failed')),
    payment_processor_transaction_id VARCHAR(255),
    payment_processor_response JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    metadata JSONB
);

-- Create payout_status_history table (if not exists)
CREATE TABLE IF NOT EXISTS payout_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payout_id UUID NOT NULL REFERENCES payouts(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(255),
    notes TEXT
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_payment_records_booking_id ON payment_records(booking_id);
CREATE INDEX IF NOT EXISTS idx_payment_records_status ON payment_records(status);
CREATE INDEX IF NOT EXISTS idx_payment_records_type ON payment_records(type);
CREATE INDEX IF NOT EXISTS idx_payment_records_payment_method ON payment_records(payment_method);
CREATE INDEX IF NOT EXISTS idx_payment_status_history_payment_id ON payment_status_history(payment_id);
CREATE INDEX IF NOT EXISTS idx_invoices_booking_id ON invoices(booking_id);
CREATE INDEX IF NOT EXISTS idx_invoices_professional_id ON invoices(professional_id);
CREATE INDEX IF NOT EXISTS idx_professional_balances_professional_id ON professional_balances(professional_id);
CREATE INDEX IF NOT EXISTS idx_payouts_professional_id ON payouts(professional_id);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON payouts(status);
CREATE INDEX IF NOT EXISTS idx_payout_status_history_payout_id ON payout_status_history(payout_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_payment_records_updated_at 
    BEFORE UPDATE ON payment_records 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at 
    BEFORE UPDATE ON invoices 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Function to update professional balance when payment is completed
CREATE OR REPLACE FUNCTION update_professional_balance_on_payment()
RETURNS TRIGGER AS $$
DECLARE
    professional_id_var VARCHAR(255);
    payment_amount DECIMAL(10,2);
    payment_method_var VARCHAR(50);
BEGIN
    -- Only process when payment status changes to paid
    IF OLD.status != 'paid' AND NEW.status = 'paid' THEN
        -- Get professional_id from invoice
        SELECT i.professional_id INTO professional_id_var
        FROM invoices i
        WHERE i.id = NEW.invoice_id;
        
        -- If no invoice found, try to extract from booking_id (fallback)
        IF professional_id_var IS NULL THEN
            -- This is a simplified approach - adjust based on your booking_id format
            professional_id_var := split_part(NEW.booking_id, '_', 2);
        END IF;
        
        -- Get payment amount and method
        payment_amount := NEW.amount;
        payment_method_var := NEW.payment_method;
        
        -- Only update balance for non-cash payments
        IF payment_method_var IS NOT NULL AND payment_method_var != 'cash' THEN
            -- Update professional balance
            INSERT INTO professional_balances (professional_id, available_balance, total_earned, total_paid_out, last_updated, created_at)
            VALUES (professional_id_var, payment_amount, payment_amount, 0.0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            ON CONFLICT (professional_id) 
            DO UPDATE SET
                available_balance = professional_balances.available_balance + payment_amount,
                total_earned = professional_balances.total_earned + payment_amount,
                last_updated = CURRENT_TIMESTAMP;
                
            -- Log the balance update
            RAISE NOTICE 'Updated professional balance: % +% (non-cash payment)', professional_id_var, payment_amount;
        ELSE
            -- Log that no balance update was made for cash payment
            RAISE NOTICE 'No balance update for cash payment: %', professional_id_var;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to update professional balance when payment is completed
DROP TRIGGER IF EXISTS update_balance_on_payment_completion ON payment_records;
CREATE TRIGGER update_balance_on_payment_completion
    AFTER UPDATE ON payment_records
    FOR EACH ROW
    EXECUTE FUNCTION update_professional_balance_on_payment();

-- Function to update professional balance when payout is completed
CREATE OR REPLACE FUNCTION update_professional_balance_on_payout()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process when status changes to success or failed
    IF OLD.status != NEW.status AND (NEW.status = 'success' OR NEW.status = 'failed') THEN
        -- Update professional balance
        INSERT INTO professional_balances (professional_id, available_balance, total_earned, total_paid_out, last_updated, created_at)
        VALUES (NEW.professional_id, 0.0, 0.0, NEW.amount, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        ON CONFLICT (professional_id) 
        DO UPDATE SET
            available_balance = CASE 
                WHEN NEW.status = 'success' THEN GREATEST(0.0, professional_balances.available_balance - NEW.amount)
                ELSE professional_balances.available_balance  -- Keep current balance if failed
            END,
            total_paid_out = CASE
                WHEN NEW.status = 'success' THEN professional_balances.total_paid_out + NEW.amount
                ELSE professional_balances.total_paid_out  -- Don't change if failed
            END,
            last_updated = CURRENT_TIMESTAMP;
            
        -- Set completed_at timestamp
        NEW.completed_at = CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to update professional balance when payout status changes
DROP TRIGGER IF EXISTS update_balance_on_payout_status_change ON payouts;
CREATE TRIGGER update_balance_on_payout_status_change
    BEFORE UPDATE ON payouts
    FOR EACH ROW
    EXECUTE FUNCTION update_professional_balance_on_payout();

-- Function to add payout status history
CREATE OR REPLACE FUNCTION add_payout_status_history()
RETURNS TRIGGER AS $$
BEGIN
    -- Only add history when status changes
    IF OLD.status != NEW.status THEN
        INSERT INTO payout_status_history (payout_id, status, changed_at, changed_by, notes)
        VALUES (NEW.id, NEW.status, CURRENT_TIMESTAMP, 'system', 
                CASE 
                    WHEN NEW.status = 'success' THEN 'Payout completed successfully'
                    WHEN NEW.status = 'failed' THEN COALESCE(NEW.error_message, 'Payout failed')
                    ELSE 'Status updated to ' || NEW.status
                END);
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to add payout status history
DROP TRIGGER IF EXISTS add_payout_status_history_trigger ON payouts;
CREATE TRIGGER add_payout_status_history_trigger
    AFTER UPDATE ON payouts
    FOR EACH ROW
    EXECUTE FUNCTION add_payout_status_history();

-- Add comments for documentation
COMMENT ON TABLE payment_records IS 'Individual payment records for each transaction';
COMMENT ON TABLE invoices IS 'Invoice records for each booking';
COMMENT ON TABLE professional_balances IS 'Current available balance and earnings summary for each professional';
COMMENT ON TABLE payouts IS 'Service professional payout requests and their status';
COMMENT ON TABLE payout_status_history IS 'Audit trail for payout status changes';

COMMENT ON COLUMN payment_records.payment_method IS 'Payment method used (cash, credit_card, debit_card, etc.)';
COMMENT ON COLUMN payment_records.type IS 'Payment type (deposit, balance, full)';
COMMENT ON COLUMN professional_balances.available_balance IS 'Amount available for cash-out (non-cash payments only)';
COMMENT ON COLUMN professional_balances.total_earned IS 'Total amount earned from all completed jobs (cash + non-cash)';
COMMENT ON COLUMN professional_balances.total_paid_out IS 'Total amount paid out to professional';

-- Grant necessary permissions (adjust as needed for your setup)
-- GRANT SELECT, INSERT, UPDATE ON payment_records TO your_app_user;
-- GRANT SELECT, INSERT, UPDATE ON invoices TO your_app_user;
-- GRANT SELECT, INSERT, UPDATE ON professional_balances TO your_app_user;
-- GRANT SELECT, INSERT, UPDATE ON payouts TO your_app_user;
-- GRANT SELECT, INSERT ON payment_status_history TO your_app_user;
-- GRANT SELECT, INSERT ON payout_status_history TO your_app_user;
