-- SmartWebV3 Row Level Security (RLS) Policies
-- Secure multi-tenant data access
-- Created: 2025-01-06

-- Helper function to get current user's organization
CREATE OR REPLACE FUNCTION auth.organization_id() 
RETURNS UUID AS $$
BEGIN
    RETURN auth.jwt() ->> 'organization_id';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to get current user's ID
CREATE OR REPLACE FUNCTION auth.user_id() 
RETURNS UUID AS $$
BEGIN
    RETURN auth.jwt() ->> 'sub';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check if user has permission
CREATE OR REPLACE FUNCTION auth.has_permission(resource TEXT, action TEXT, scope TEXT DEFAULT NULL)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM user_roles ur
        JOIN role_permissions rp ON ur.role_id = rp.role_id
        JOIN permissions p ON rp.permission_id = p.id
        WHERE ur.user_id = auth.user_id()
        AND p.resource = resource
        AND p.action = action
        AND (scope IS NULL OR p.scope = scope)
        AND (ur.valid_until IS NULL OR ur.valid_until > CURRENT_TIMESTAMP)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check if user is super admin
CREATE OR REPLACE FUNCTION auth.is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM users 
        WHERE id = auth.user_id() 
        AND is_super_admin = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS on all tables
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE oauth_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE lead_enrichment ENABLE ROW LEVEL SECURITY;
ALTER TABLE lead_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipelines ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE opportunities ENABLE ROW LEVEL SECURITY;
ALTER TABLE opportunity_stage_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE proposals ENABLE ROW LEVEL SECURITY;
ALTER TABLE proposal_line_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_call_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Organizations policies
CREATE POLICY "Super admins can view all organizations" ON organizations
    FOR ALL TO authenticated
    USING (auth.is_super_admin());

CREATE POLICY "Users can view their own organization" ON organizations
    FOR SELECT TO authenticated
    USING (id = auth.organization_id());

CREATE POLICY "Organization admins can update their organization" ON organizations
    FOR UPDATE TO authenticated
    USING (
        id = auth.organization_id() 
        AND auth.has_permission('settings', 'manage', 'all')
    );

-- Users policies
CREATE POLICY "Super admins can manage all users" ON users
    FOR ALL TO authenticated
    USING (auth.is_super_admin());

CREATE POLICY "Users can view users in their organization" ON users
    FOR SELECT TO authenticated
    USING (
        organization_id = auth.organization_id()
        OR id = auth.user_id()
    );

CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE TO authenticated
    USING (id = auth.user_id())
    WITH CHECK (id = auth.user_id());

CREATE POLICY "User admins can manage organization users" ON users
    FOR ALL TO authenticated
    USING (
        organization_id = auth.organization_id()
        AND auth.has_permission('users', 'create', 'all')
    );

-- Companies policies
CREATE POLICY "Users can view companies in their organization" ON companies
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM leads l
            WHERE l.company_id = companies.id
            AND (
                auth.has_permission('companies', 'read', 'all')
                OR (
                    auth.has_permission('companies', 'read', 'own')
                    AND l.assigned_to = auth.user_id()
                )
            )
        )
    );

CREATE POLICY "Users can create companies" ON companies
    FOR INSERT TO authenticated
    WITH CHECK (auth.has_permission('companies', 'create', 'all'));

CREATE POLICY "Users can update companies" ON companies
    FOR UPDATE TO authenticated
    USING (auth.has_permission('companies', 'update', 'all'));

-- Leads policies
CREATE POLICY "Users can view all leads in organization" ON leads
    FOR SELECT TO authenticated
    USING (
        auth.has_permission('leads', 'read', 'all')
        OR (
            auth.has_permission('leads', 'read', 'own')
            AND assigned_to = auth.user_id()
        )
    );

CREATE POLICY "Users can create leads" ON leads
    FOR INSERT TO authenticated
    WITH CHECK (auth.has_permission('leads', 'create', 'all'));

CREATE POLICY "Users can update their assigned leads" ON leads
    FOR UPDATE TO authenticated
    USING (
        auth.has_permission('leads', 'update', 'all')
        OR (
            auth.has_permission('leads', 'update', 'own')
            AND assigned_to = auth.user_id()
        )
    );

CREATE POLICY "Users can delete leads" ON leads
    FOR DELETE TO authenticated
    USING (auth.has_permission('leads', 'delete', 'all'));

-- Interactions policies
CREATE POLICY "Users can view interactions" ON interactions
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM leads l
            WHERE l.id = interactions.lead_id
            AND (
                auth.has_permission('interactions', 'read', 'all')
                OR (
                    auth.has_permission('interactions', 'read', 'own')
                    AND l.assigned_to = auth.user_id()
                )
            )
        )
    );

CREATE POLICY "Users can create interactions" ON interactions
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM leads l
            WHERE l.id = lead_id
            AND (
                auth.has_permission('interactions', 'create', 'all')
                OR (
                    auth.has_permission('interactions', 'create', 'own')
                    AND l.assigned_to = auth.user_id()
                )
            )
        )
    );

-- Pipelines policies
CREATE POLICY "Users can view organization pipelines" ON pipelines
    FOR SELECT TO authenticated
    USING (organization_id = auth.organization_id());

CREATE POLICY "Admins can manage pipelines" ON pipelines
    FOR ALL TO authenticated
    USING (
        organization_id = auth.organization_id()
        AND auth.has_permission('settings', 'manage', 'all')
    );

-- Pipeline stages policies
CREATE POLICY "Users can view pipeline stages" ON pipeline_stages
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM pipelines p
            WHERE p.id = pipeline_stages.pipeline_id
            AND p.organization_id = auth.organization_id()
        )
    );

-- Opportunities policies
CREATE POLICY "Users can view opportunities" ON opportunities
    FOR SELECT TO authenticated
    USING (
        auth.has_permission('leads', 'read', 'all')
        OR (
            auth.has_permission('leads', 'read', 'own')
            AND owner_id = auth.user_id()
        )
    );

CREATE POLICY "Users can create opportunities" ON opportunities
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM leads l
            WHERE l.id = lead_id
            AND (
                auth.has_permission('leads', 'update', 'all')
                OR (
                    auth.has_permission('leads', 'update', 'own')
                    AND l.assigned_to = auth.user_id()
                )
            )
        )
    );

CREATE POLICY "Users can update opportunities" ON opportunities
    FOR UPDATE TO authenticated
    USING (
        auth.has_permission('leads', 'update', 'all')
        OR (
            auth.has_permission('leads', 'update', 'own')
            AND owner_id = auth.user_id()
        )
    );

-- Products policies
CREATE POLICY "Users can view organization products" ON products
    FOR SELECT TO authenticated
    USING (organization_id = auth.organization_id());

CREATE POLICY "Admins can manage products" ON products
    FOR ALL TO authenticated
    USING (
        organization_id = auth.organization_id()
        AND auth.has_permission('settings', 'manage', 'all')
    );

-- Proposals policies
CREATE POLICY "Users can view proposals" ON proposals
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM opportunities o
            WHERE o.id = proposals.opportunity_id
            AND (
                auth.has_permission('leads', 'read', 'all')
                OR (
                    auth.has_permission('leads', 'read', 'own')
                    AND o.owner_id = auth.user_id()
                )
            )
        )
    );

CREATE POLICY "Users can create proposals" ON proposals
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM opportunities o
            WHERE o.id = opportunity_id
            AND (
                auth.has_permission('leads', 'update', 'all')
                OR (
                    auth.has_permission('leads', 'update', 'own')
                    AND o.owner_id = auth.user_id()
                )
            )
        )
    );

-- Contracts policies
CREATE POLICY "Users can view contracts" ON contracts
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM opportunities o
            WHERE o.id = contracts.opportunity_id
            AND (
                auth.has_permission('leads', 'read', 'all')
                OR (
                    auth.has_permission('leads', 'read', 'own')
                    AND o.owner_id = auth.user_id()
                )
            )
        )
    );

-- AI Call Campaigns policies
CREATE POLICY "Users can view organization campaigns" ON ai_call_campaigns
    FOR SELECT TO authenticated
    USING (organization_id = auth.organization_id());

CREATE POLICY "Managers can create campaigns" ON ai_call_campaigns
    FOR INSERT TO authenticated
    WITH CHECK (
        organization_id = auth.organization_id()
        AND auth.has_permission('leads', 'create', 'all')
    );

-- AI Calls policies
CREATE POLICY "Users can view AI calls" ON ai_calls
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM leads l
            WHERE l.id = ai_calls.lead_id
            AND (
                auth.has_permission('interactions', 'read', 'all')
                OR (
                    auth.has_permission('interactions', 'read', 'own')
                    AND l.assigned_to = auth.user_id()
                )
            )
        )
    );

-- Tasks policies
CREATE POLICY "Users can view their tasks" ON tasks
    FOR SELECT TO authenticated
    USING (
        assigned_to = auth.user_id()
        OR auth.has_permission('leads', 'read', 'all')
    );

CREATE POLICY "Users can create tasks" ON tasks
    FOR INSERT TO authenticated
    WITH CHECK (auth.has_permission('leads', 'update', 'all'));

CREATE POLICY "Users can update their tasks" ON tasks
    FOR UPDATE TO authenticated
    USING (
        assigned_to = auth.user_id()
        OR auth.has_permission('leads', 'update', 'all')
    );

-- Audit logs policies
CREATE POLICY "Users can view organization audit logs" ON audit_logs
    FOR SELECT TO authenticated
    USING (
        organization_id = auth.organization_id()
        AND auth.has_permission('settings', 'manage', 'all')
    );

-- Sessions policies
CREATE POLICY "Users can manage their own sessions" ON sessions
    FOR ALL TO authenticated
    USING (user_id = auth.user_id());

-- OAuth accounts policies
CREATE POLICY "Users can manage their own OAuth accounts" ON oauth_accounts
    FOR ALL TO authenticated
    USING (user_id = auth.user_id());

-- Grant necessary permissions to the authenticated role
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;