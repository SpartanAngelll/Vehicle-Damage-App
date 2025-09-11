-- Add entry to pg_hba.conf to allow connections from local network
-- This allows connections from any IP in the 192.168.0.0/24 network

-- First, let's see the current pg_hba.conf content
\copy (SELECT 'Current pg_hba.conf entries:') TO 'C:\temp\pg_hba_backup.txt';

-- Add the new entry (this will be added to the end of pg_hba.conf)
-- Note: This needs to be done manually by editing the file
-- The entry should be: host all all 192.168.0.0/24 md5

-- For now, let's try to add it via SQL (this might not work for pg_hba.conf)
-- We'll need to manually edit the file instead
