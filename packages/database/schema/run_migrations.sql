-- SmartWebV3 Database Migration Runner
-- Execute all schema files in order
-- Created: 2025-01-06

-- Run migrations in order
\i 001_shared_tables.sql
\i 002_auth_tables.sql
\i 003_crm_tables.sql
\i 004_rls_policies.sql

-- Verify tables were created
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Verify RLS is enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND rowsecurity = true
ORDER BY tablename;