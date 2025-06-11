-- SmartWebV3 CRM-specific Tables
-- Pipeline management, proposals, contracts, and sales automation
-- Created: 2025-01-06

-- Create custom types for CRM
CREATE TYPE pipeline_stage_type AS ENUM (
    'new',
    'qualified',
    'proposal',
    'negotiation',
    'closed_won',
    'closed_lost'
);

CREATE TYPE proposal_status AS ENUM (
    'draft',
    'sent',
    'viewed',
    'accepted',
    'rejected',
    'expired'
);

CREATE TYPE contract_status AS ENUM (
    'draft',
    'sent',
    'signed',
    'countersigned',
    'active',
    'completed',
    'cancelled'
);

CREATE TYPE product_type AS ENUM (
    'website_design',
    'website_maintenance',
    'lead_generation',
    'seo_package',
    'landing_page',
    'custom_development',
    'bundle'
);

CREATE TYPE ai_call_status AS ENUM (
    'scheduled',
    'in_progress',
    'completed',
    'failed',
    'no_answer',
    'voicemail',
    'callback_requested'
);

-- Pipelines table (sales process definition)
CREATE TABLE pipelines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Pipeline Information
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_default BOOLEAN DEFAULT false,
    
    -- Settings
    auto_archive_days INTEGER DEFAULT 90, -- Auto-archive after X days of inactivity
    probability_settings JSONB DEFAULT '{}', -- Stage-wise probability
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    
    CONSTRAINT pipelines_one_default_per_org UNIQUE (organization_id, is_default) WHERE is_default = true
);

-- Create indexes for pipelines
CREATE INDEX idx_pipelines_organization_id ON pipelines(organization_id);
CREATE INDEX idx_pipelines_is_active ON pipelines(is_active) WHERE is_active = true;

-- Pipeline stages (customizable stages per pipeline)
CREATE TABLE pipeline_stages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pipeline_id UUID NOT NULL REFERENCES pipelines(id) ON DELETE CASCADE,
    
    -- Stage Information
    name VARCHAR(100) NOT NULL,
    type pipeline_stage_type NOT NULL,
    order_index INTEGER NOT NULL,
    
    -- Stage Settings
    probability DECIMAL(3, 2) DEFAULT 0.50 CHECK (probability >= 0 AND probability <= 1),
    days_to_close INTEGER DEFAULT 30,
    required_fields JSONB DEFAULT '[]', -- Fields that must be filled to enter this stage
    automation_rules JSONB DEFAULT '{}', -- Automated actions on stage entry
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT pipeline_stages_unique_order UNIQUE (pipeline_id, order_index)
);

-- Create indexes for pipeline stages
CREATE INDEX idx_pipeline_stages_pipeline_id ON pipeline_stages(pipeline_id);
CREATE INDEX idx_pipeline_stages_order_index ON pipeline_stages(order_index);

-- Opportunities (deals in the pipeline)
CREATE TABLE opportunities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    pipeline_id UUID NOT NULL REFERENCES pipelines(id),
    current_stage_id UUID NOT NULL REFERENCES pipeline_stages(id),
    
    -- Opportunity Details
    name VARCHAR(255) NOT NULL,
    value DECIMAL(10, 2) NOT NULL DEFAULT 0,
    probability DECIMAL(3, 2) DEFAULT 0.50 CHECK (probability >= 0 AND probability <= 1),
    weighted_value DECIMAL(10, 2) GENERATED ALWAYS AS (value * probability) STORED,
    
    -- Timeline
    expected_close_date DATE,
    actual_close_date DATE,
    
    -- Assignment
    owner_id UUID NOT NULL REFERENCES users(id),
    team_members UUID[], -- Additional team members
    
    -- Stage History
    stage_entered_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    time_in_stage INTEGER DEFAULT 0, -- Days in current stage
    
    -- Closure Information
    closed_reason VARCHAR(255),
    competitor_won VARCHAR(255), -- If lost to competitor
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_archived BOOLEAN DEFAULT false
);

-- Create indexes for opportunities
CREATE INDEX idx_opportunities_lead_id ON opportunities(lead_id);
CREATE INDEX idx_opportunities_pipeline_id ON opportunities(pipeline_id);
CREATE INDEX idx_opportunities_current_stage_id ON opportunities(current_stage_id);
CREATE INDEX idx_opportunities_owner_id ON opportunities(owner_id);
CREATE INDEX idx_opportunities_expected_close_date ON opportunities(expected_close_date);
CREATE INDEX idx_opportunities_is_archived ON opportunities(is_archived);
CREATE INDEX idx_opportunities_weighted_value ON opportunities(weighted_value DESC);

-- Opportunity stage history (track movement through pipeline)
CREATE TABLE opportunity_stage_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    opportunity_id UUID NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    
    -- Stage Movement
    from_stage_id UUID REFERENCES pipeline_stages(id),
    to_stage_id UUID NOT NULL REFERENCES pipeline_stages(id),
    
    -- Context
    changed_by UUID NOT NULL REFERENCES users(id),
    reason TEXT,
    
    -- Time Tracking
    entered_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    exited_at TIMESTAMP WITH TIME ZONE,
    duration_days INTEGER
);

-- Create indexes for opportunity stage history
CREATE INDEX idx_opportunity_stage_history_opportunity_id ON opportunity_stage_history(opportunity_id);
CREATE INDEX idx_opportunity_stage_history_entered_at ON opportunity_stage_history(entered_at DESC);

-- Products/Services catalog
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Product Information
    name VARCHAR(255) NOT NULL,
    sku VARCHAR(100) UNIQUE,
    type product_type NOT NULL,
    description TEXT,
    
    -- Pricing
    base_price DECIMAL(10, 2) NOT NULL,
    setup_fee DECIMAL(10, 2) DEFAULT 0,
    recurring_price DECIMAL(10, 2), -- For subscription products
    billing_cycle VARCHAR(20), -- 'monthly', 'yearly', etc.
    
    -- Availability
    is_active BOOLEAN DEFAULT true,
    available_from DATE,
    available_until DATE,
    
    -- Features and Benefits
    features JSONB DEFAULT '[]',
    included_services JSONB DEFAULT '[]',
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for products
CREATE INDEX idx_products_organization_id ON products(organization_id);
CREATE INDEX idx_products_type ON products(type);
CREATE INDEX idx_products_is_active ON products(is_active) WHERE is_active = true;
CREATE INDEX idx_products_sku ON products(sku) WHERE sku IS NOT NULL;

-- Proposals table
CREATE TABLE proposals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    opportunity_id UUID NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    
    -- Proposal Details
    proposal_number VARCHAR(50) UNIQUE NOT NULL,
    version INTEGER DEFAULT 1,
    title VARCHAR(255) NOT NULL,
    
    -- Status and Timeline
    status proposal_status DEFAULT 'draft' NOT NULL,
    valid_until DATE NOT NULL,
    
    -- Content
    executive_summary TEXT,
    scope_of_work TEXT,
    terms_and_conditions TEXT,
    custom_sections JSONB DEFAULT '[]',
    
    -- Totals
    subtotal DECIMAL(10, 2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    discount_percentage DECIMAL(5, 2) DEFAULT 0,
    tax_amount DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    
    -- Tracking
    sent_at TIMESTAMP WITH TIME ZONE,
    sent_to_email VARCHAR(255),
    viewed_at TIMESTAMP WITH TIME ZONE,
    view_count INTEGER DEFAULT 0,
    accepted_at TIMESTAMP WITH TIME ZONE,
    rejected_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    
    -- Document Management
    pdf_url VARCHAR(500),
    template_id UUID, -- Reference to proposal template
    
    -- Metadata
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for proposals
CREATE INDEX idx_proposals_opportunity_id ON proposals(opportunity_id);
CREATE INDEX idx_proposals_status ON proposals(status);
CREATE INDEX idx_proposals_proposal_number ON proposals(proposal_number);
CREATE INDEX idx_proposals_created_by ON proposals(created_by);
CREATE INDEX idx_proposals_sent_at ON proposals(sent_at DESC) WHERE sent_at IS NOT NULL;

-- Proposal line items
CREATE TABLE proposal_line_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    proposal_id UUID NOT NULL REFERENCES proposals(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    
    -- Item Details
    name VARCHAR(255) NOT NULL,
    description TEXT,
    quantity DECIMAL(10, 2) NOT NULL DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,
    
    -- Calculations
    subtotal DECIMAL(10, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    tax_amount DECIMAL(10, 2) DEFAULT 0,
    total DECIMAL(10, 2) NOT NULL,
    
    -- Ordering
    sort_order INTEGER NOT NULL DEFAULT 0,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for proposal line items
CREATE INDEX idx_proposal_line_items_proposal_id ON proposal_line_items(proposal_id);
CREATE INDEX idx_proposal_line_items_product_id ON proposal_line_items(product_id);
CREATE INDEX idx_proposal_line_items_sort_order ON proposal_line_items(sort_order);

-- Contracts table
CREATE TABLE contracts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    proposal_id UUID REFERENCES proposals(id),
    opportunity_id UUID NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    
    -- Contract Details
    contract_number VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'one-time', 'recurring', 'retainer'
    
    -- Status and Timeline
    status contract_status DEFAULT 'draft' NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    auto_renew BOOLEAN DEFAULT false,
    renewal_terms TEXT,
    
    -- Financial
    total_value DECIMAL(10, 2) NOT NULL,
    payment_terms VARCHAR(100), -- 'net-30', 'upon-signing', etc.
    payment_schedule JSONB DEFAULT '[]', -- For installment payments
    
    -- Signatures
    client_signature_required BOOLEAN DEFAULT true,
    client_signed_at TIMESTAMP WITH TIME ZONE,
    client_signed_by VARCHAR(255),
    client_signature_ip INET,
    
    internal_signed_at TIMESTAMP WITH TIME ZONE,
    internal_signed_by UUID REFERENCES users(id),
    
    -- Document Management
    document_url VARCHAR(500),
    docusign_envelope_id VARCHAR(255),
    
    -- Metadata
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for contracts
CREATE INDEX idx_contracts_opportunity_id ON contracts(opportunity_id);
CREATE INDEX idx_contracts_proposal_id ON contracts(proposal_id);
CREATE INDEX idx_contracts_status ON contracts(status);
CREATE INDEX idx_contracts_contract_number ON contracts(contract_number);
CREATE INDEX idx_contracts_start_date ON contracts(start_date);
CREATE INDEX idx_contracts_end_date ON contracts(end_date) WHERE end_date IS NOT NULL;

-- AI Call Campaigns
CREATE TABLE ai_call_campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Campaign Details
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Targeting
    lead_criteria JSONB NOT NULL, -- Criteria for selecting leads
    max_attempts_per_lead INTEGER DEFAULT 3,
    
    -- Scheduling
    start_date DATE NOT NULL,
    end_date DATE,
    calling_hours JSONB NOT NULL, -- Time windows for calling
    timezone VARCHAR(50) DEFAULT 'America/Chicago',
    
    -- Script and Voice
    script_template TEXT NOT NULL,
    voice_settings JSONB DEFAULT '{}',
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    is_paused BOOLEAN DEFAULT false,
    
    -- Metadata
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for AI call campaigns
CREATE INDEX idx_ai_call_campaigns_organization_id ON ai_call_campaigns(organization_id);
CREATE INDEX idx_ai_call_campaigns_is_active ON ai_call_campaigns(is_active) WHERE is_active = true;
CREATE INDEX idx_ai_call_campaigns_start_date ON ai_call_campaigns(start_date);

-- AI Calls table
CREATE TABLE ai_calls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID REFERENCES ai_call_campaigns(id),
    lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    interaction_id UUID REFERENCES interactions(id),
    
    -- Call Details
    phone_number VARCHAR(20) NOT NULL,
    status ai_call_status NOT NULL,
    
    -- Timing
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    
    -- AI Analysis
    transcript TEXT,
    sentiment_score DECIMAL(3, 2), -- -1.00 to 1.00
    interest_level INTEGER CHECK (interest_level >= 1 AND interest_level <= 10),
    key_points JSONB DEFAULT '[]',
    follow_up_required BOOLEAN DEFAULT false,
    follow_up_notes TEXT,
    
    -- Outcomes
    outcome VARCHAR(100), -- 'interested', 'not_interested', 'callback', etc.
    next_action VARCHAR(255),
    callback_requested_for TIMESTAMP WITH TIME ZONE,
    
    -- Technical Details
    call_sid VARCHAR(255), -- Provider's call ID
    recording_url VARCHAR(500),
    cost DECIMAL(6, 4), -- Call cost in dollars
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for AI calls
CREATE INDEX idx_ai_calls_campaign_id ON ai_calls(campaign_id);
CREATE INDEX idx_ai_calls_lead_id ON ai_calls(lead_id);
CREATE INDEX idx_ai_calls_interaction_id ON ai_calls(interaction_id);
CREATE INDEX idx_ai_calls_status ON ai_calls(status);
CREATE INDEX idx_ai_calls_scheduled_for ON ai_calls(scheduled_for);
CREATE INDEX idx_ai_calls_outcome ON ai_calls(outcome);

-- Tasks table (for follow-ups and activities)
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Task Assignment
    assigned_to UUID NOT NULL REFERENCES users(id),
    assigned_by UUID REFERENCES users(id),
    
    -- Related Entities
    lead_id UUID REFERENCES leads(id) ON DELETE CASCADE,
    opportunity_id UUID REFERENCES opportunities(id) ON DELETE CASCADE,
    
    -- Task Details
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL, -- 'call', 'email', 'meeting', 'follow_up', etc.
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    
    -- Timeline
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    reminder_date TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Status
    is_completed BOOLEAN DEFAULT false,
    completion_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for tasks
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX idx_tasks_lead_id ON tasks(lead_id);
CREATE INDEX idx_tasks_opportunity_id ON tasks(opportunity_id);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_tasks_is_completed ON tasks(is_completed);
CREATE INDEX idx_tasks_assigned_to_due_date ON tasks(assigned_to, due_date) WHERE is_completed = false;

-- Create updated_at triggers for CRM tables
CREATE TRIGGER update_pipelines_updated_at BEFORE UPDATE ON pipelines
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pipeline_stages_updated_at BEFORE UPDATE ON pipeline_stages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_opportunities_updated_at BEFORE UPDATE ON opportunities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_proposals_updated_at BEFORE UPDATE ON proposals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contracts_updated_at BEFORE UPDATE ON contracts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ai_call_campaigns_updated_at BEFORE UPDATE ON ai_call_campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ai_calls_updated_at BEFORE UPDATE ON ai_calls
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();