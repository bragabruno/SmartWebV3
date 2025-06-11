-- SmartWebV3 Authentication and Authorization Schema
-- User management, roles, and permissions
-- Created: 2025-01-06

-- Create custom types for auth
CREATE TYPE user_status AS ENUM (
    'active',
    'inactive',
    'suspended',
    'pending_verification'
);

CREATE TYPE role_type AS ENUM (
    'super_admin',
    'organization_admin',
    'sales_manager',
    'sales_rep',
    'read_only'
);

-- Organizations table (for multi-tenant support)
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Organization Details
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    
    -- Billing Information
    billing_email VARCHAR(255),
    billing_address JSONB,
    stripe_customer_id VARCHAR(255) UNIQUE,
    
    -- Subscription
    subscription_tier VARCHAR(50) DEFAULT 'free',
    subscription_status VARCHAR(50) DEFAULT 'active',
    subscription_expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Limits (based on subscription)
    max_users INTEGER DEFAULT 5,
    max_leads_per_month INTEGER DEFAULT 1000,
    max_ai_calls_per_month INTEGER DEFAULT 500,
    
    -- Settings
    settings JSONB DEFAULT '{}',
    features JSONB DEFAULT '{}', -- Enabled features
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Create indexes for organizations
CREATE INDEX idx_organizations_slug ON organizations(slug);
CREATE INDEX idx_organizations_is_active ON organizations(is_active) WHERE is_active = true;
CREATE INDEX idx_organizations_stripe_customer_id ON organizations(stripe_customer_id) WHERE stripe_customer_id IS NOT NULL;

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Authentication (for NextAuth.js compatibility)
    email VARCHAR(255) UNIQUE NOT NULL,
    email_verified TIMESTAMP WITH TIME ZONE,
    password_hash VARCHAR(255), -- For email/password auth
    
    -- Profile Information
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    full_name VARCHAR(255) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    avatar_url VARCHAR(500),
    phone VARCHAR(20),
    
    -- Organization Membership
    organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
    department VARCHAR(100),
    job_title VARCHAR(100),
    
    -- Status and Permissions
    status user_status DEFAULT 'pending_verification' NOT NULL,
    is_super_admin BOOLEAN DEFAULT false,
    
    -- Settings
    preferences JSONB DEFAULT '{}',
    notification_settings JSONB DEFAULT '{"email": true, "sms": false, "in_app": true}',
    
    -- Security
    two_factor_enabled BOOLEAN DEFAULT false,
    two_factor_secret VARCHAR(255),
    last_login_at TIMESTAMP WITH TIME ZONE,
    last_login_ip INET,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE -- Soft delete
);

-- Create indexes for users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_organization_id ON users(organization_id);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_deleted_at ON users(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_full_name_trgm ON users USING gin(full_name gin_trgm_ops);

-- Roles table
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Role Information
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    description TEXT,
    type role_type NOT NULL,
    
    -- Scope
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    is_system_role BOOLEAN DEFAULT false, -- System roles can't be modified
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT roles_unique_slug_per_org UNIQUE (organization_id, slug)
);

-- Create indexes for roles
CREATE INDEX idx_roles_organization_id ON roles(organization_id);
CREATE INDEX idx_roles_type ON roles(type);
CREATE INDEX idx_roles_is_system_role ON roles(is_system_role);

-- Permissions table
CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Permission Details
    resource VARCHAR(100) NOT NULL, -- e.g., 'leads', 'companies', 'users'
    action VARCHAR(100) NOT NULL, -- e.g., 'create', 'read', 'update', 'delete'
    scope VARCHAR(50), -- e.g., 'own', 'team', 'all'
    
    -- Description
    name VARCHAR(200) NOT NULL,
    description TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT permissions_unique UNIQUE (resource, action, scope)
);

-- Create indexes for permissions
CREATE INDEX idx_permissions_resource ON permissions(resource);
CREATE INDEX idx_permissions_action ON permissions(action);

-- Role permissions mapping
CREATE TABLE role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    
    -- Additional constraints (JSON for flexibility)
    constraints JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (role_id, permission_id)
);

-- Create indexes for role permissions
CREATE INDEX idx_role_permissions_role_id ON role_permissions(role_id);
CREATE INDEX idx_role_permissions_permission_id ON role_permissions(permission_id);

-- User roles mapping
CREATE TABLE user_roles (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    
    -- Temporal access
    valid_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP WITH TIME ZONE,
    
    -- Assignment tracking
    assigned_by UUID REFERENCES users(id),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (user_id, role_id)
);

-- Create indexes for user roles
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role_id ON user_roles(role_id);
CREATE INDEX idx_user_roles_valid_until ON user_roles(valid_until) WHERE valid_until IS NOT NULL;

-- Sessions table (for NextAuth.js)
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_token VARCHAR(255) UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expires TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Additional session data
    ip_address INET,
    user_agent TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for sessions
CREATE INDEX idx_sessions_session_token ON sessions(session_token);
CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_expires ON sessions(expires);

-- Verification tokens (for email verification, password reset, etc.)
CREATE TABLE verification_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    identifier VARCHAR(255) NOT NULL, -- Usually email
    token VARCHAR(255) UNIQUE NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'email_verification', 'password_reset', etc.
    expires TIMESTAMP WITH TIME ZONE NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT verification_tokens_unique UNIQUE (identifier, token)
);

-- Create indexes for verification tokens
CREATE INDEX idx_verification_tokens_token ON verification_tokens(token);
CREATE INDEX idx_verification_tokens_identifier_type ON verification_tokens(identifier, type);
CREATE INDEX idx_verification_tokens_expires ON verification_tokens(expires);

-- OAuth accounts (for social login)
CREATE TABLE oauth_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- OAuth provider details
    provider VARCHAR(50) NOT NULL, -- 'google', 'github', etc.
    provider_account_id VARCHAR(255) NOT NULL,
    
    -- Token storage
    access_token TEXT,
    refresh_token TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    token_type VARCHAR(50),
    scope TEXT,
    id_token TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT oauth_accounts_unique UNIQUE (provider, provider_account_id)
);

-- Create indexes for oauth accounts
CREATE INDEX idx_oauth_accounts_user_id ON oauth_accounts(user_id);
CREATE INDEX idx_oauth_accounts_provider ON oauth_accounts(provider);

-- Audit log for security tracking
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Actor
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
    
    -- Action details
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id UUID,
    
    -- Change tracking
    old_values JSONB,
    new_values JSONB,
    
    -- Context
    ip_address INET,
    user_agent TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for audit logs
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_organization_id ON audit_logs(organization_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_resource_type_id ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- Create updated_at triggers for auth tables
CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_roles_updated_at BEFORE UPDATE ON roles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sessions_updated_at BEFORE UPDATE ON sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_oauth_accounts_updated_at BEFORE UPDATE ON oauth_accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default system roles
INSERT INTO roles (name, slug, description, type, is_system_role) VALUES
    ('Super Admin', 'super_admin', 'Full system access', 'super_admin', true),
    ('Organization Admin', 'org_admin', 'Full organization access', 'organization_admin', true),
    ('Sales Manager', 'sales_manager', 'Manage sales team and view all data', 'sales_manager', true),
    ('Sales Rep', 'sales_rep', 'Manage own leads and interactions', 'sales_rep', true),
    ('Read Only', 'read_only', 'View only access', 'read_only', true);

-- Insert default permissions
INSERT INTO permissions (resource, action, scope, name, description) VALUES
    -- Lead permissions
    ('leads', 'create', 'all', 'Create any lead', 'Can create leads for the organization'),
    ('leads', 'read', 'all', 'Read all leads', 'Can view all leads in the organization'),
    ('leads', 'read', 'own', 'Read own leads', 'Can view leads assigned to them'),
    ('leads', 'update', 'all', 'Update all leads', 'Can update any lead in the organization'),
    ('leads', 'update', 'own', 'Update own leads', 'Can update leads assigned to them'),
    ('leads', 'delete', 'all', 'Delete any lead', 'Can delete any lead in the organization'),
    
    -- Company permissions
    ('companies', 'create', 'all', 'Create companies', 'Can create new companies'),
    ('companies', 'read', 'all', 'Read all companies', 'Can view all companies'),
    ('companies', 'update', 'all', 'Update companies', 'Can update company information'),
    ('companies', 'delete', 'all', 'Delete companies', 'Can delete companies'),
    
    -- User permissions
    ('users', 'create', 'all', 'Create users', 'Can create new users'),
    ('users', 'read', 'all', 'Read all users', 'Can view all users'),
    ('users', 'update', 'all', 'Update users', 'Can update user information'),
    ('users', 'delete', 'all', 'Delete users', 'Can delete users'),
    
    -- Interaction permissions
    ('interactions', 'create', 'all', 'Create interactions', 'Can create interactions for any lead'),
    ('interactions', 'create', 'own', 'Create own interactions', 'Can create interactions for own leads'),
    ('interactions', 'read', 'all', 'Read all interactions', 'Can view all interactions'),
    ('interactions', 'read', 'own', 'Read own interactions', 'Can view interactions for own leads'),
    
    -- Reports permissions
    ('reports', 'view', 'all', 'View all reports', 'Can view all reports and analytics'),
    ('reports', 'view', 'own', 'View own reports', 'Can view reports for own performance'),
    
    -- Settings permissions
    ('settings', 'manage', 'all', 'Manage settings', 'Can manage organization settings');