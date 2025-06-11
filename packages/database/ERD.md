# SmartWebV3 Database Entity Relationship Diagram

## Overview
This document visualizes the database schema for SmartWebV3, showing relationships between tables across the shared infrastructure, authentication system, and CRM-specific features.

## Entity Relationship Diagram

```mermaid
erDiagram
    %% Organizations and Users
    organizations ||--o{ users : "has"
    organizations ||--o{ roles : "has custom"
    organizations ||--o{ pipelines : "has"
    organizations ||--o{ products : "offers"
    organizations ||--o{ ai_call_campaigns : "runs"
    
    %% Authentication
    users ||--o{ user_roles : "has"
    users ||--o{ sessions : "has"
    users ||--o{ oauth_accounts : "has"
    users ||--o{ verification_tokens : "receives"
    users ||--o{ audit_logs : "creates"
    
    roles ||--o{ user_roles : "assigned to"
    roles ||--o{ role_permissions : "has"
    permissions ||--o{ role_permissions : "granted to"
    
    %% Core Business Entities
    companies ||--|| leads : "generates"
    
    %% Lead Management
    leads ||--o{ interactions : "has"
    leads ||--o{ lead_enrichment : "enriched with"
    leads ||--o{ lead_tags : "tagged with"
    leads ||--o{ opportunities : "converts to"
    leads ||--o{ ai_calls : "receives"
    leads ||--o{ tasks : "has"
    
    %% Sales Pipeline
    pipelines ||--o{ pipeline_stages : "contains"
    pipeline_stages ||--o{ opportunities : "holds"
    opportunities ||--o{ opportunity_stage_history : "tracks"
    opportunities ||--o{ proposals : "generates"
    opportunities ||--o{ contracts : "results in"
    opportunities ||--o{ tasks : "has"
    
    %% Proposals and Contracts
    proposals ||--o{ proposal_line_items : "contains"
    products ||--o{ proposal_line_items : "included in"
    proposals ||--o| contracts : "converts to"
    
    %% AI Calling
    ai_call_campaigns ||--o{ ai_calls : "executes"
    ai_calls ||--|| interactions : "creates"
    
    %% Task Management
    users ||--o{ tasks : "assigned"
    users ||--o{ tasks : "created by"
    
    %% Audit and Tracking
    users ||--o{ interactions : "initiates"
    users ||--o{ proposals : "creates"
    users ||--o{ contracts : "creates"
    users ||--o{ ai_call_campaigns : "creates"

    %% Entity Definitions
    organizations {
        uuid id PK
        varchar name
        varchar slug UK
        varchar billing_email
        jsonb billing_address
        varchar stripe_customer_id UK
        varchar subscription_tier
        varchar subscription_status
        timestamp subscription_expires_at
        integer max_users
        integer max_leads_per_month
        integer max_ai_calls_per_month
        jsonb settings
        jsonb features
        timestamp created_at
        timestamp updated_at
        boolean is_active
    }
    
    users {
        uuid id PK
        varchar email UK
        timestamp email_verified
        varchar password_hash
        varchar first_name
        varchar last_name
        varchar full_name
        varchar avatar_url
        varchar phone
        uuid organization_id FK
        varchar department
        varchar job_title
        enum status
        boolean is_super_admin
        jsonb preferences
        jsonb notification_settings
        boolean two_factor_enabled
        varchar two_factor_secret
        timestamp last_login_at
        inet last_login_ip
        integer failed_login_attempts
        timestamp locked_until
        timestamp created_at
        timestamp updated_at
        timestamp deleted_at
    }
    
    companies {
        uuid id PK
        varchar external_id UK
        varchar name
        varchar dba_name
        enum business_type
        varchar phone UK
        varchar email UK
        varchar website
        varchar street_address
        varchar city
        varchar state
        varchar zip_code
        varchar country
        decimal latitude
        decimal longitude
        varchar license_number
        varchar license_state
        date license_expiry
        integer years_in_business
        integer employee_count
        decimal annual_revenue
        varchar google_business_id UK
        decimal google_rating
        integer google_reviews_count
        varchar facebook_url
        varchar linkedin_url
        varchar instagram_url
        timestamp created_at
        timestamp updated_at
        timestamp last_scraped_at
        boolean is_active
    }
    
    leads {
        uuid id PK
        uuid company_id FK UK
        enum status
        enum source
        jsonb source_details
        integer lead_score
        jsonb score_breakdown
        timestamp qualified_at
        varchar qualified_by
        uuid assigned_to FK
        timestamp assigned_at
        timestamp converted_at
        decimal conversion_value
        varchar lost_reason
        varchar preferred_contact_method
        varchar best_call_time
        varchar timezone
        timestamp first_contact_at
        timestamp last_contact_at
        integer contact_attempts
        timestamp created_at
        timestamp updated_at
    }
    
    interactions {
        uuid id PK
        uuid lead_id FK
        enum type
        varchar direction
        varchar subject
        text content
        text summary
        uuid initiated_by FK
        uuid[] participated_users
        integer call_duration
        varchar call_recording_url
        text call_transcript
        varchar call_sentiment
        varchar email_message_id
        varchar email_thread_id
        boolean email_opened
        boolean email_clicked
        timestamp meeting_date
        integer meeting_duration
        varchar meeting_location
        jsonb meeting_attendees
        jsonb ai_insights
        decimal ai_score
        timestamp created_at
        timestamp updated_at
        timestamp scheduled_for
        timestamp completed_at
    }
    
    opportunities {
        uuid id PK
        uuid lead_id FK
        uuid pipeline_id FK
        uuid current_stage_id FK
        varchar name
        decimal value
        decimal probability
        decimal weighted_value
        date expected_close_date
        date actual_close_date
        uuid owner_id FK
        uuid[] team_members
        timestamp stage_entered_at
        integer time_in_stage
        varchar closed_reason
        varchar competitor_won
        timestamp created_at
        timestamp updated_at
        boolean is_archived
    }
    
    proposals {
        uuid id PK
        uuid opportunity_id FK
        varchar proposal_number UK
        integer version
        varchar title
        enum status
        date valid_until
        text executive_summary
        text scope_of_work
        text terms_and_conditions
        jsonb custom_sections
        decimal subtotal
        decimal discount_amount
        decimal discount_percentage
        decimal tax_amount
        decimal total_amount
        timestamp sent_at
        varchar sent_to_email
        timestamp viewed_at
        integer view_count
        timestamp accepted_at
        timestamp rejected_at
        text rejection_reason
        varchar pdf_url
        uuid template_id
        uuid created_by FK
        timestamp created_at
        timestamp updated_at
    }
    
    contracts {
        uuid id PK
        uuid proposal_id FK
        uuid opportunity_id FK
        varchar contract_number UK
        varchar title
        varchar type
        enum status
        date start_date
        date end_date
        boolean auto_renew
        text renewal_terms
        decimal total_value
        varchar payment_terms
        jsonb payment_schedule
        boolean client_signature_required
        timestamp client_signed_at
        varchar client_signed_by
        inet client_signature_ip
        timestamp internal_signed_at
        uuid internal_signed_by FK
        varchar document_url
        varchar docusign_envelope_id
        uuid created_by FK
        timestamp created_at
        timestamp updated_at
    }
```

## Table Categories

### 1. **Authentication & Authorization**
- `organizations` - Multi-tenant organizations
- `users` - User accounts
- `roles` - Role definitions
- `permissions` - Permission definitions
- `role_permissions` - Role-permission mappings
- `user_roles` - User-role assignments
- `sessions` - Active user sessions
- `verification_tokens` - Email verification and password reset
- `oauth_accounts` - Social login providers
- `audit_logs` - Security audit trail

### 2. **Core Business Entities**
- `companies` - Trade business profiles
- `leads` - Potential customers
- `interactions` - All touchpoints with leads
- `lead_enrichment` - Additional lead data
- `lead_tags` - Flexible categorization

### 3. **Sales Pipeline**
- `pipelines` - Sales process definitions
- `pipeline_stages` - Customizable pipeline stages
- `opportunities` - Active deals
- `opportunity_stage_history` - Stage movement tracking

### 4. **Sales Documents**
- `products` - Service catalog
- `proposals` - Sales proposals
- `proposal_line_items` - Proposal details
- `contracts` - Signed agreements

### 5. **AI & Automation**
- `ai_call_campaigns` - Automated calling campaigns
- `ai_calls` - Individual AI call records
- `tasks` - Follow-up activities

## Key Design Decisions

### 1. **Multi-tenancy**
- Organization-based isolation
- Row Level Security (RLS) for data protection
- Flexible role-based permissions

### 2. **Audit & Compliance**
- Comprehensive audit logging
- Soft deletes for users
- Timestamp tracking on all records

### 3. **Performance Optimization**
- Strategic indexes on foreign keys and search fields
- Partial indexes for common queries
- JSONB for flexible data storage

### 4. **Scalability**
- UUID primary keys for distributed systems
- Enum types for consistent values
- Prepared for horizontal scaling

### 5. **Integration Ready**
- External ID fields for third-party systems
- Webhook-friendly event tracking
- API-first design principles