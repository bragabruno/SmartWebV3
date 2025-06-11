# Database Setup Guide

## Prerequisites
- Supabase account
- PostgreSQL client (psql) or Supabase dashboard
- Environment variables configured

## Quick Start

### 1. Create Supabase Project
1. Go to [app.supabase.com](https://app.supabase.com)
2. Create new project
3. Save your project URL and anon key

### 2. Run Migrations

#### Option A: Using Supabase Dashboard
1. Go to SQL Editor in Supabase dashboard
2. Copy contents of each file in order:
   - `schema/001_shared_tables.sql`
   - `schema/002_auth_tables.sql`
   - `schema/003_crm_tables.sql`
   - `schema/004_rls_policies.sql`
3. Execute each file

#### Option B: Using psql
```bash
# Connect to your database
psql postgresql://postgres:[YOUR-PASSWORD]@[YOUR-PROJECT].supabase.co:5432/postgres

# Run all migrations
\i packages/database/schema/run_migrations.sql
```

### 3. Verify Installation
```sql
-- Check all tables created
SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;

-- Verify RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND rowsecurity = true;

-- Check default roles
SELECT * FROM roles WHERE is_system_role = true;
```

### 4. Create First Organization and User
```sql
-- Create organization
INSERT INTO organizations (name, slug, subscription_tier) 
VALUES ('Your Company', 'your-company', 'trial')
RETURNING id;

-- Create admin user (use the org ID from above)
INSERT INTO users (email, organization_id, status, is_super_admin)
VALUES ('admin@yourcompany.com', '[ORG-ID]', 'active', true)
RETURNING id;

-- Assign organization admin role
INSERT INTO user_roles (user_id, role_id)
SELECT '[USER-ID]', id FROM roles WHERE slug = 'org_admin';
```

### 5. Configure Environment Variables
```bash
# .env.local
NEXT_PUBLIC_SUPABASE_URL=https://[YOUR-PROJECT].supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=[YOUR-ANON-KEY]
SUPABASE_SERVICE_ROLE_KEY=[YOUR-SERVICE-KEY]
DATABASE_URL=postgresql://postgres:[PASSWORD]@[YOUR-PROJECT].supabase.co:5432/postgres
```

## Development Seed Data

For development, you can run the seed script:

```sql
-- Create test companies
INSERT INTO companies (name, business_type, phone, email, city, state) VALUES
('ABC Plumbing', 'plumber', '555-0101', 'contact@abcplumbing.com', 'Austin', 'TX'),
('Elite Electric', 'electrician', '555-0102', 'info@eliteelectric.com', 'Dallas', 'TX'),
('Top Tier Roofing', 'roofer', '555-0103', 'sales@toptierroofing.com', 'Houston', 'TX');

-- Create test leads
INSERT INTO leads (company_id, status, source, lead_score) 
SELECT id, 'qualified', 'google_my_business', 85 
FROM companies 
LIMIT 3;
```

## Troubleshooting

### Permission Denied Errors
- Ensure RLS policies are properly created
- Check user has correct role assignments
- Verify JWT token contains required claims

### Migration Failures
- Check for existing tables: `DROP SCHEMA public CASCADE; CREATE SCHEMA public;`
- Enable required extensions first
- Run migrations in correct order

### Connection Issues
- Verify database URL is correct
- Check firewall/network settings
- Ensure SSL is enabled: `?sslmode=require`

## Next Steps
1. Set up application authentication with Supabase Auth
2. Configure real-time subscriptions for lead updates
3. Implement database backup strategy
4. Set up monitoring and alerts