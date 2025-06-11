# SmartWebV3 Database Architecture

## Overview

The SmartWebV3 database is designed as a unified, multi-tenant PostgreSQL database using Supabase. It supports both the lead generation system and the AI-powered CRM, with a focus on security, scalability, and performance.

## Architecture Principles

### 1. **Unified Data Model**
- Single source of truth for all business data
- Shared entities between lead generator and CRM
- Consistent data structure across modules

### 2. **Multi-Tenant Security**
- Row Level Security (RLS) on all tables
- Organization-based data isolation
- Role-based access control (RBAC)

### 3. **Performance First**
- Strategic indexing for sub-100ms queries
- JSONB for flexible data without schema changes
- Partial indexes for common query patterns

### 4. **Audit & Compliance Ready**
- Comprehensive audit logging
- GDPR/CCPA compliant data handling
- Soft deletes for data recovery

## Database Structure

### Core Modules

1. **Shared Tables** (`001_shared_tables.sql`)
   - Companies: Trade business profiles
   - Leads: Potential customers for SmartWebV3
   - Interactions: All touchpoints and communications
   - Lead enrichment and tagging

2. **Authentication** (`002_auth_tables.sql`)
   - Organizations: Multi-tenant support
   - Users: Individual user accounts
   - Roles & Permissions: Flexible RBAC system
   - Sessions & OAuth: Secure authentication

3. **CRM Features** (`003_crm_tables.sql`)
   - Sales pipelines and stages
   - Opportunities (deals)
   - Proposals and contracts
   - AI call campaigns and records
   - Task management

4. **Security Policies** (`004_rls_policies.sql`)
   - Row Level Security implementation
   - Helper functions for authorization
   - Granular access control

## Key Tables Reference

### Companies
- **Purpose**: Store trade business information
- **Key Fields**: name, business_type, contact info, online presence
- **Relationships**: One-to-one with leads

### Leads
- **Purpose**: Track potential SmartWebV3 customers
- **Key Fields**: status, source, lead_score, assigned_to
- **Relationships**: Belongs to company, has many interactions

### Interactions
- **Purpose**: Record all communications
- **Key Fields**: type, content, AI analysis, outcomes
- **Relationships**: Belongs to lead, created by users

### Opportunities
- **Purpose**: Track sales deals through pipeline
- **Key Fields**: value, probability, stage, owner
- **Relationships**: Belongs to lead, moves through pipeline stages

## Data Flow

```
1. Lead Generation
   Companies → Leads → Lead Scoring → Qualification

2. Sales Process
   Qualified Leads → Opportunities → Pipeline Stages

3. Conversion
   Opportunities → Proposals → Contracts → Customer

4. AI Automation
   Campaigns → AI Calls → Interactions → Tasks
```

## Security Model

### Row Level Security (RLS)
- All tables have RLS enabled
- Policies based on organization membership
- Special handling for cross-organization data

### Permission System
- **Resources**: leads, companies, users, etc.
- **Actions**: create, read, update, delete
- **Scopes**: own, team, all

### Default Roles
1. **Super Admin**: Full system access
2. **Organization Admin**: Full org access
3. **Sales Manager**: Team management
4. **Sales Rep**: Own leads only
5. **Read Only**: View access only

## Performance Optimizations

### Indexes
- Primary keys: UUID with B-tree indexes
- Foreign keys: All have indexes
- Search fields: GIN indexes for full-text search
- Time-based: BRIN indexes for timestamp columns

### Query Patterns
```sql
-- Fast lead lookup by score
CREATE INDEX idx_leads_status_score ON leads(status, lead_score DESC);

-- Efficient interaction history
CREATE INDEX idx_interactions_lead_type_created ON interactions(lead_id, type, created_at DESC);

-- Quick opportunity pipeline view
CREATE INDEX idx_opportunities_weighted_value ON opportunities(weighted_value DESC);
```

## Migration Guide

### Initial Setup
```bash
# Connect to Supabase
psql -h your-project.supabase.co -U postgres -d postgres

# Run migrations in order
\i packages/database/schema/run_migrations.sql
```

### Adding New Tables
1. Create migration file: `005_your_feature.sql`
2. Define table with proper indexes
3. Add RLS policies
4. Update documentation

### Modifying Existing Tables
1. Create migration with ALTER statements
2. Update affected RLS policies
3. Reindex if necessary
4. Test query performance

## Best Practices

### 1. **Always Use UUIDs**
```sql
id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
```

### 2. **Add Timestamps**
```sql
created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
```

### 3. **Create Appropriate Indexes**
```sql
-- For foreign keys
CREATE INDEX idx_table_fk_column ON table(fk_column);

-- For queries
CREATE INDEX idx_table_query_pattern ON table(col1, col2) WHERE condition;
```

### 4. **Use JSONB for Flexibility**
```sql
-- For variable data
settings JSONB DEFAULT '{}',
metadata JSONB DEFAULT '{}'
```

### 5. **Implement Soft Deletes**
```sql
deleted_at TIMESTAMP WITH TIME ZONE,
-- Index for active records
CREATE INDEX idx_table_active ON table(id) WHERE deleted_at IS NULL;
```

## Monitoring & Maintenance

### Query Performance
```sql
-- Find slow queries
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC;
```

### Table Statistics
```sql
-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Index Usage
```sql
-- Find unused indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY schemaname, tablename;
```

## Backup & Recovery

### Automated Backups
- Supabase provides automatic daily backups
- Point-in-time recovery available
- Download backups via dashboard

### Manual Backup
```bash
# Full database backup
pg_dump -h your-project.supabase.co -U postgres -d postgres > backup.sql

# Schema only
pg_dump -h your-project.supabase.co -U postgres -d postgres --schema-only > schema.sql

# Data only
pg_dump -h your-project.supabase.co -U postgres -d postgres --data-only > data.sql
```

## Troubleshooting

### Common Issues

1. **RLS Policy Blocking Access**
   - Check user permissions
   - Verify organization membership
   - Review policy conditions

2. **Slow Queries**
   - Check query execution plan
   - Add appropriate indexes
   - Consider query restructuring

3. **Migration Failures**
   - Check for dependency issues
   - Verify syntax errors
   - Review constraint violations

## Future Considerations

### Planned Enhancements
1. Partitioning for large tables (interactions, audit_logs)
2. Read replicas for reporting
3. Materialized views for dashboards
4. Time-series optimization for metrics

### Scalability Path
1. **Phase 1**: Single database (current)
2. **Phase 2**: Read replicas for analytics
3. **Phase 3**: Sharding by organization
4. **Phase 4**: Microservices with separate databases

## Support

For database-related questions:
- Review this documentation
- Check Supabase documentation
- Contact the backend team
- Open a ticket with specific error messages