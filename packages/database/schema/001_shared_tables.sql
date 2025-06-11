-- SmartWebV3 Unified Database Schema
-- Shared Tables (used by both lead generator and CRM)
-- Created: 2025-01-06

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For fuzzy text search

-- Create custom types
CREATE TYPE business_type AS ENUM (
    'electrician',
    'plumber',
    'roofer',
    'hvac',
    'contractor',
    'landscaper',
    'painter',
    'carpenter',
    'other'
);

CREATE TYPE lead_status AS ENUM (
    'new',
    'qualified',
    'contacted',
    'interested',
    'not_interested',
    'converted',
    'lost'
);

CREATE TYPE lead_source AS ENUM (
    'google_my_business',
    'state_license_board',
    'social_media',
    'referral',
    'website',
    'manual',
    'other'
);

CREATE TYPE interaction_type AS ENUM (
    'call',
    'email',
    'sms',
    'meeting',
    'proposal',
    'note',
    'ai_call',
    'website_visit'
);

-- Companies table (core entity for trade businesses)
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id VARCHAR(255) UNIQUE, -- For tracking from external sources
    
    -- Basic Information
    name VARCHAR(255) NOT NULL,
    dba_name VARCHAR(255), -- Doing Business As name
    business_type business_type NOT NULL,
    
    -- Contact Information
    phone VARCHAR(20),
    email VARCHAR(255),
    website VARCHAR(255),
    
    -- Address
    street_address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    country VARCHAR(2) DEFAULT 'US',
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    
    -- Business Details
    license_number VARCHAR(100),
    license_state VARCHAR(50),
    license_expiry DATE,
    years_in_business INTEGER,
    employee_count INTEGER,
    annual_revenue DECIMAL(12, 2),
    
    -- Online Presence
    google_business_id VARCHAR(255),
    google_rating DECIMAL(2, 1),
    google_reviews_count INTEGER,
    facebook_url VARCHAR(255),
    linkedin_url VARCHAR(255),
    instagram_url VARCHAR(255),
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_scraped_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    
    -- Indexes for performance
    CONSTRAINT companies_email_unique UNIQUE (email),
    CONSTRAINT companies_phone_unique UNIQUE (phone),
    CONSTRAINT companies_google_business_id_unique UNIQUE (google_business_id)
);

-- Create indexes for companies
CREATE INDEX idx_companies_business_type ON companies(business_type);
CREATE INDEX idx_companies_state ON companies(state);
CREATE INDEX idx_companies_city_state ON companies(city, state);
CREATE INDEX idx_companies_name_trgm ON companies USING gin(name gin_trgm_ops);
CREATE INDEX idx_companies_created_at ON companies(created_at DESC);
CREATE INDEX idx_companies_is_active ON companies(is_active) WHERE is_active = true;

-- Leads table (potential customers for SmartWebV3)
CREATE TABLE leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    
    -- Lead Information
    status lead_status DEFAULT 'new' NOT NULL,
    source lead_source NOT NULL,
    source_details JSONB, -- Additional source-specific data
    
    -- Scoring and Qualification
    lead_score INTEGER DEFAULT 0 CHECK (lead_score >= 0 AND lead_score <= 100),
    score_breakdown JSONB, -- Detailed scoring factors
    qualified_at TIMESTAMP WITH TIME ZONE,
    qualified_by VARCHAR(255), -- System or user that qualified
    
    -- Assignment
    assigned_to UUID, -- References users table (to be created)
    assigned_at TIMESTAMP WITH TIME ZONE,
    
    -- Conversion Tracking
    converted_at TIMESTAMP WITH TIME ZONE,
    conversion_value DECIMAL(10, 2),
    lost_reason VARCHAR(255),
    
    -- Contact Preferences
    preferred_contact_method VARCHAR(50),
    best_call_time VARCHAR(50),
    timezone VARCHAR(50),
    
    -- Engagement Metrics
    first_contact_at TIMESTAMP WITH TIME ZONE,
    last_contact_at TIMESTAMP WITH TIME ZONE,
    contact_attempts INTEGER DEFAULT 0,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT leads_company_unique UNIQUE (company_id)
);

-- Create indexes for leads
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_source ON leads(source);
CREATE INDEX idx_leads_lead_score ON leads(lead_score DESC);
CREATE INDEX idx_leads_assigned_to ON leads(assigned_to);
CREATE INDEX idx_leads_created_at ON leads(created_at DESC);
CREATE INDEX idx_leads_qualified_at ON leads(qualified_at DESC) WHERE qualified_at IS NOT NULL;
CREATE INDEX idx_leads_status_score ON leads(status, lead_score DESC);

-- Interactions table (all touchpoints with leads/customers)
CREATE TABLE interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    
    -- Interaction Details
    type interaction_type NOT NULL,
    direction VARCHAR(10) CHECK (direction IN ('inbound', 'outbound')),
    
    -- Content
    subject VARCHAR(255),
    content TEXT,
    summary TEXT, -- AI-generated summary for long interactions
    
    -- Participants
    initiated_by UUID, -- References users table
    participated_users UUID[], -- Array of user IDs
    
    -- Call-specific fields
    call_duration INTEGER, -- in seconds
    call_recording_url VARCHAR(500),
    call_transcript TEXT,
    call_sentiment VARCHAR(20), -- positive, neutral, negative
    
    -- Email-specific fields
    email_message_id VARCHAR(255),
    email_thread_id VARCHAR(255),
    email_opened BOOLEAN,
    email_clicked BOOLEAN,
    
    -- Meeting-specific fields
    meeting_date TIMESTAMP WITH TIME ZONE,
    meeting_duration INTEGER, -- in minutes
    meeting_location VARCHAR(255),
    meeting_attendees JSONB,
    
    -- AI Analysis
    ai_insights JSONB, -- Key points, action items, etc.
    ai_score DECIMAL(3, 2), -- 0.00 to 1.00 quality/success score
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    scheduled_for TIMESTAMP WITH TIME ZONE, -- For future interactions
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for interactions
CREATE INDEX idx_interactions_lead_id ON interactions(lead_id);
CREATE INDEX idx_interactions_type ON interactions(type);
CREATE INDEX idx_interactions_created_at ON interactions(created_at DESC);
CREATE INDEX idx_interactions_scheduled_for ON interactions(scheduled_for) WHERE scheduled_for IS NOT NULL;
CREATE INDEX idx_interactions_initiated_by ON interactions(initiated_by);
CREATE INDEX idx_interactions_lead_type_created ON interactions(lead_id, type, created_at DESC);

-- Lead enrichment data table (additional data from various sources)
CREATE TABLE lead_enrichment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    
    -- Enrichment Source
    source VARCHAR(100) NOT NULL,
    source_id VARCHAR(255),
    
    -- Enriched Data
    data JSONB NOT NULL,
    confidence_score DECIMAL(3, 2), -- 0.00 to 1.00
    
    -- Metadata
    enriched_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_verified BOOLEAN DEFAULT false,
    
    CONSTRAINT lead_enrichment_unique UNIQUE (lead_id, source)
);

-- Create indexes for lead enrichment
CREATE INDEX idx_lead_enrichment_lead_id ON lead_enrichment(lead_id);
CREATE INDEX idx_lead_enrichment_source ON lead_enrichment(source);
CREATE INDEX idx_lead_enrichment_expires_at ON lead_enrichment(expires_at) WHERE expires_at IS NOT NULL;

-- Lead tags for flexible categorization
CREATE TABLE lead_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    tag VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    
    CONSTRAINT lead_tags_unique UNIQUE (lead_id, tag)
);

-- Create indexes for lead tags
CREATE INDEX idx_lead_tags_lead_id ON lead_tags(lead_id);
CREATE INDEX idx_lead_tags_tag ON lead_tags(tag);

-- Create updated_at triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON leads
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_interactions_updated_at BEFORE UPDATE ON interactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) policies will be added after auth tables are created
-- These are placeholder comments for now
-- ENABLE RLS on all tables
-- Create policies based on user roles and organization membership