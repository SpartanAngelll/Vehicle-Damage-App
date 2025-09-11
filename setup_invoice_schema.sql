-- Connect to the database
\c vehicle_damage_payments;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create invoices table
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id VARCHAR(255) NOT NULL UNIQUE,
    customer_id VARCHAR(255) NOT NULL,
    professional_id VARCHAR(255) NOT NULL,
    total_amount NUMERIC(10, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'JMD',
    deposit_percentage INT DEFAULT 0,
    deposit_amount NUMERIC(10, 2) NOT NULL DEFAULT 0,
    balance_amount NUMERIC(10, 2) NOT NULL DEFAULT 0,
    status VARCHAR(50) DEFAULT 'draft',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP WITH TIME ZONE,
    due_date TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    metadata JSONB
);

-- Create payment_records table (replaces the old payments table)
CREATE TABLE IF NOT EXISTS payment_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    booking_id VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- deposit, balance, full, refund
    amount NUMERIC(10, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'JMD',
    status VARCHAR(50) DEFAULT 'pending',
    payment_method VARCHAR(50),
    transaction_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    metadata JSONB
);

-- Create payment_status_history table
CREATE TABLE IF NOT EXISTS payment_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_id UUID NOT NULL REFERENCES payment_records(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(255) DEFAULT 'system',
    notes TEXT
);

-- Create invoice_status_history table
CREATE TABLE IF NOT EXISTS invoice_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(255) DEFAULT 'system',
    notes TEXT
);

-- Indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_invoices_booking_id ON invoices(booking_id);
CREATE INDEX IF NOT EXISTS idx_invoices_customer_id ON invoices(customer_id);
CREATE INDEX IF NOT EXISTS idx_invoices_professional_id ON invoices(professional_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_payment_records_invoice_id ON payment_records(invoice_id);
CREATE INDEX IF NOT EXISTS idx_payment_records_booking_id ON payment_records(booking_id);
CREATE INDEX IF NOT EXISTS idx_payment_records_status ON payment_records(status);
CREATE INDEX IF NOT EXISTS idx_payment_records_type ON payment_records(type);
CREATE INDEX IF NOT EXISTS idx_payment_status_history_payment_id ON payment_status_history(payment_id);
CREATE INDEX IF NOT EXISTS idx_invoice_status_history_invoice_id ON invoice_status_history(invoice_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers to call the function on update
CREATE OR REPLACE TRIGGER update_invoices_updated_at
BEFORE UPDATE ON invoices
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER update_payment_records_updated_at
BEFORE UPDATE ON payment_records
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Function to automatically create invoice status history
CREATE OR REPLACE FUNCTION create_invoice_status_history()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO invoice_status_history (invoice_id, status, changed_by, notes)
    VALUES (NEW.id, NEW.status, 'system', 'Status changed to ' || NEW.status);
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Function to automatically create payment status history
CREATE OR REPLACE FUNCTION create_payment_status_history()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO payment_status_history (payment_id, status, changed_by, notes)
    VALUES (NEW.id, NEW.status, 'system', 'Status changed to ' || NEW.status);
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for status history
CREATE OR REPLACE TRIGGER invoice_status_history_trigger
AFTER INSERT OR UPDATE OF status ON invoices
FOR EACH ROW
EXECUTE FUNCTION create_invoice_status_history();

CREATE OR REPLACE TRIGGER payment_status_history_trigger
AFTER INSERT OR UPDATE OF status ON payment_records
FOR EACH ROW
EXECUTE FUNCTION create_payment_status_history();

-- Migrate existing payments data to new structure (if any exists)
DO $$
BEGIN
    -- Check if old payments table exists and has data
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payments') THEN
        -- Create invoices from existing payments
        INSERT INTO invoices (booking_id, customer_id, professional_id, total_amount, currency, deposit_percentage, deposit_amount, balance_amount, status, created_at, updated_at)
        SELECT 
            booking_id,
            customer_id,
            professional_id,
            amount,
            currency,
            deposit_percentage,
            COALESCE(deposit_amount, amount * deposit_percentage / 100),
            amount - COALESCE(deposit_amount, amount * deposit_percentage / 100),
            CASE 
                WHEN status = 'paid' THEN 'paid'
                WHEN status = 'refunded' THEN 'refunded'
                ELSE 'sent'
            END,
            created_at,
            updated_at
        FROM payments
        WHERE NOT EXISTS (SELECT 1 FROM invoices WHERE invoices.booking_id = payments.booking_id);
        
        -- Create payment records from existing payments (disable triggers temporarily)
        ALTER TABLE payment_records DISABLE TRIGGER payment_status_history_trigger;
        
        INSERT INTO payment_records (invoice_id, booking_id, type, amount, currency, status, payment_method, transaction_id, created_at, updated_at, processed_at, notes)
        SELECT 
            i.id,
            p.booking_id,
            CASE 
                WHEN p.deposit_percentage > 0 AND p.status = 'paid' THEN 'deposit'
                WHEN p.deposit_percentage > 0 AND p.status = 'pending' THEN 'deposit'
                ELSE 'full'
            END,
            CASE 
                WHEN p.deposit_percentage > 0 AND p.status = 'paid' THEN COALESCE(p.deposit_amount, p.amount * p.deposit_percentage / 100)
                ELSE p.amount
            END,
            p.currency,
            p.status,
            p.payment_method,
            p.transaction_id,
            p.created_at,
            p.updated_at,
            p.paid_at,
            p.notes
        FROM payments p
        JOIN invoices i ON i.booking_id = p.booking_id
        WHERE NOT EXISTS (SELECT 1 FROM payment_records WHERE payment_records.booking_id = p.booking_id);
        
        -- Re-enable triggers
        ALTER TABLE payment_records ENABLE TRIGGER payment_status_history_trigger;
        
        RAISE NOTICE 'Migrated existing payments data to new invoice structure';
    END IF;
END $$;
