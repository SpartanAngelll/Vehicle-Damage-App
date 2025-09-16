-- Cash-out feature database migration
-- This migration adds support for service professional payouts

-- Connect to the database
\c vehicle_damage_payments;

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create payouts table
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

-- Create professional_balances table to track available balance
CREATE TABLE IF NOT EXISTS professional_balances (
    professional_id VARCHAR(255) PRIMARY KEY,
    available_balance DECIMAL(10,2) NOT NULL DEFAULT 0.0 CHECK (available_balance >= 0),
    total_earned DECIMAL(10,2) NOT NULL DEFAULT 0.0,
    total_paid_out DECIMAL(10,2) NOT NULL DEFAULT 0.0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create payout_status_history table for audit trail
CREATE TABLE IF NOT EXISTS payout_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payout_id UUID NOT NULL REFERENCES payouts(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(255),
    notes TEXT
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_payouts_professional_id ON payouts(professional_id);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON payouts(status);
CREATE INDEX IF NOT EXISTS idx_payouts_created_at ON payouts(created_at);
CREATE INDEX IF NOT EXISTS idx_payout_status_history_payout_id ON payout_status_history(payout_id);
CREATE INDEX IF NOT EXISTS idx_professional_balances_professional_id ON professional_balances(professional_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at for payouts
CREATE TRIGGER update_payouts_updated_at 
    BEFORE UPDATE ON payouts 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Function to update professional balance when payout is completed
CREATE OR REPLACE FUNCTION update_professional_balance_on_payout()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process when status changes to success or failed
    IF OLD.status != NEW.status AND (NEW.status = 'success' OR NEW.status = 'failed') THEN
        -- Update professional balance
        INSERT INTO professional_balances (professional_id, available_balance, total_paid_out, last_updated)
        VALUES (NEW.professional_id, 0.0, NEW.amount, CURRENT_TIMESTAMP)
        ON CONFLICT (professional_id) 
        DO UPDATE SET
            available_balance = CASE 
                WHEN NEW.status = 'success' THEN 0.0  -- Reset available balance to 0
                ELSE professional_balances.available_balance  -- Keep current balance if failed
            END,
            total_paid_out = professional_balances.total_paid_out + NEW.amount,
            last_updated = CURRENT_TIMESTAMP;
            
        -- Set completed_at timestamp
        NEW.completed_at = CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to update professional balance when payout status changes
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
CREATE TRIGGER add_payout_status_history_trigger
    AFTER UPDATE ON payouts
    FOR EACH ROW
    EXECUTE FUNCTION add_payout_status_history();

-- Function to update professional balance when payment is completed
-- This will be called when a payment is marked as paid
CREATE OR REPLACE FUNCTION update_professional_balance_on_payment()
RETURNS TRIGGER AS $$
DECLARE
    professional_id_var VARCHAR(255);
    payment_amount DECIMAL(10,2);
BEGIN
    -- Only process when payment status changes to paid
    IF OLD.status != 'paid' AND NEW.status = 'paid' THEN
        -- Extract professional_id from booking_id (assuming format: booking_professionalId_timestamp)
        -- This is a simplified approach - you may need to adjust based on your booking_id format
        professional_id_var := split_part(NEW.booking_id, '_', 2);
        
        -- Get payment amount
        payment_amount := NEW.amount;
        
        -- Update professional balance
        INSERT INTO professional_balances (professional_id, available_balance, total_earned, last_updated)
        VALUES (professional_id_var, payment_amount, payment_amount, CURRENT_TIMESTAMP)
        ON CONFLICT (professional_id) 
        DO UPDATE SET
            available_balance = professional_balances.available_balance + payment_amount,
            total_earned = professional_balances.total_earned + payment_amount,
            last_updated = CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to update professional balance when payment is completed
CREATE TRIGGER update_balance_on_payment_completion
    AFTER UPDATE ON payment_records
    FOR EACH ROW
    EXECUTE FUNCTION update_professional_balance_on_payment();

-- Insert initial status history for existing payouts (if any)
INSERT INTO payout_status_history (payout_id, status, changed_at, changed_by, notes)
SELECT id, status, created_at, 'system', 'Initial status'
FROM payouts
WHERE id NOT IN (SELECT payout_id FROM payout_status_history);

-- Add comments for documentation
COMMENT ON TABLE payouts IS 'Service professional payout requests and their status';
COMMENT ON TABLE professional_balances IS 'Current available balance and earnings summary for each professional';
COMMENT ON TABLE payout_status_history IS 'Audit trail for payout status changes';

COMMENT ON COLUMN payouts.professional_id IS 'ID of the service professional requesting payout';
COMMENT ON COLUMN payouts.amount IS 'Amount to be paid out (must be > 0)';
COMMENT ON COLUMN payouts.status IS 'Current status: pending, success, failed';
COMMENT ON COLUMN payouts.payment_processor_transaction_id IS 'Transaction ID from payment processor';
COMMENT ON COLUMN payouts.payment_processor_response IS 'Full response from payment processor';
COMMENT ON COLUMN payouts.completed_at IS 'Timestamp when payout was completed (success or failed)';
COMMENT ON COLUMN payouts.error_message IS 'Error message if payout failed';

COMMENT ON COLUMN professional_balances.available_balance IS 'Amount available for cash-out';
COMMENT ON COLUMN professional_balances.total_earned IS 'Total amount earned from all completed jobs';
COMMENT ON COLUMN professional_balances.total_paid_out IS 'Total amount paid out to professional';

-- Grant necessary permissions (adjust as needed for your setup)
-- GRANT SELECT, INSERT, UPDATE ON payouts TO your_app_user;
-- GRANT SELECT, INSERT, UPDATE ON professional_balances TO your_app_user;
-- GRANT SELECT, INSERT ON payout_status_history TO your_app_user;
