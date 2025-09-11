-- Connect to the database
\c vehicle_damage_payments;

-- Drop the old foreign key constraint
ALTER TABLE payment_status_history DROP CONSTRAINT IF EXISTS payment_status_history_payment_id_fkey;

-- Add the new foreign key constraint to reference payment_records instead of payments
ALTER TABLE payment_status_history 
ADD CONSTRAINT payment_status_history_payment_id_fkey 
FOREIGN KEY (payment_id) REFERENCES payment_records(id) ON DELETE CASCADE;

-- Update the trigger function to work with payment_records
CREATE OR REPLACE FUNCTION create_payment_status_history()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO payment_status_history (payment_id, status, changed_by, notes)
    VALUES (NEW.id, NEW.status, 'system', 'Status changed to ' || NEW.status);
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop and recreate the trigger to ensure it's working with the new table
DROP TRIGGER IF EXISTS payment_status_history_trigger ON payment_records;
CREATE OR REPLACE TRIGGER payment_status_history_trigger
AFTER INSERT OR UPDATE OF status ON payment_records
FOR EACH ROW
EXECUTE FUNCTION create_payment_status_history();

-- Verify the changes
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name='payment_status_history';
