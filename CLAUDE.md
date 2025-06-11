# Claude AI Development Assistant

## Project Overview
SmartWebV3 is an integrated lead generation and sales automation platform specifically designed for trade businesses (electricians, plumbers, roofers, etc.) to generate leads and convert them into website/landing page sales. 

**Critical Note**: The platform uses its own lead generation and AI sales system internally to acquire customers for SmartWebV3 itself. This "eat your own dog food" approach serves as both a proof of concept and the primary customer acquisition channel.

## System Architecture
- **Main Module**: SmartWebV3 - Orchestration and shared infrastructure
- **Submodule 1**: trade-lead-generator - n8n-powered lead scraping and qualification
- **Submodule 2**: ai-cold-caller-crm - AI-assisted sales conversion system

## Development Context

### Lead Generation System (trade-lead-generator)
- **Tech Stack**: n8n, Next.js, Supabase, React
- **Purpose**: Automated scraping of trade business data from Google My Business, state licensing boards, and social media
- **Output**: Qualified leads with 80+ scoring system
- **Data Volume**: 400-667 qualified leads monthly for 10 website sales target

### AI Cold Caller CRM (ai-cold-caller-crm)
- **Tech Stack**: Next.js, Supabase, AI voice agents, automated workflows
- **Purpose**: Convert qualified leads into closed sales through AI-assisted calling and pipeline management
- **Features**: AI voice agents, proposal automation, contract management
- **Target ROI**: 3-5x ROI within 12 months

## Integration Points
- Real-time webhook integration between systems
- Shared Supabase database with row-level security
- Bidirectional API connections for status updates
- Unified reporting and analytics dashboards

## Development Guidelines

### Code Patterns
- Use TypeScript for type safety
- Implement proper error handling and logging
- Follow responsive design principles
- Ensure GDPR/CCPA compliance for data handling

### Database Schema
- Shared entities: companies, leads, interactions
- System-specific schemas with foreign key relationships
- Optimized indexing for sub-100ms query performance

### API Design
- RESTful endpoints with proper status codes
- Webhook handlers for real-time integration
- Rate limiting and authentication (OAuth 2.0 + JWT)
- Comprehensive API documentation

## Deployment Strategy
- Development: Local development with Docker containers
- Staging: Vercel deployment with Supabase staging
- Production: Multi-region deployment with load balancing
- Monitoring: Real-time performance and error tracking

## Key Performance Targets

### Internal Customer Acquisition (SmartWebV3 Sales)
- **Lead Generation**: Generate 1,000-2,500 trade business leads daily for our own sales team
- **Outreach**: 50-125 AI-powered calls daily to sell SmartWebV3 platform
- **Target**: 10 new SmartWebV3 customers monthly
- **Conversion**: 1.5-3% lead-to-customer conversion rate

### Platform Performance
- **Response Times**: Sub-100ms for user interactions
- **Uptime**: 99.9% availability with failover systems
- **Scalability**: Support both internal usage and customer deployments

## Security & Compliance
- SOC 2 Type II compliance
- End-to-end encryption for sensitive data
- Role-based access controls
- Comprehensive audit trails
- TCPA compliance for cold calling activities

## Development Commands
```bash
# Clone main repository with submodules
git clone --recursive https://github.com/your-org/SmartWebV3.git

# Initialize submodules (if not using --recursive)
git submodule init
git submodule update

# Install dependencies for all modules
npm run install:all

# Start development environment
npm run dev

# Run tests across all modules
npm run test:all

# Build for production
npm run build:all
```

## Environment Variables
```bash
# Shared Configuration
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
NEXTAUTH_SECRET=your_auth_secret
NEXTAUTH_URL=your_app_url

# Lead Generation Specific
N8N_WEBHOOK_URL=your_n8n_webhook
GOOGLE_MAPS_API_KEY=your_google_maps_key
STATE_LICENSE_API_KEYS=your_license_apis

# AI CRM Specific
OPENAI_API_KEY=your_openai_key
VOICE_API_PROVIDER=your_voice_provider
DOCUSIGN_API_KEY=your_docusign_key
```

## Current Development Status
- [x] System architecture design completed
- [x] Database schema planned
- [x] Integration patterns defined
- [ ] Core infrastructure setup
- [ ] Lead generation module development
- [ ] AI CRM module development
- [ ] Integration testing
- [ ] Production deployment

## Next Steps
1. Set up shared infrastructure (Supabase, authentication)
2. Implement lead generation n8n workflows
3. Build AI Cold Caller CRM interface
4. Integrate systems with real-time data flow
5. Deploy staging environment for testing
6. Launch pilot program with select trade businesses

## Notes for Claude
This is a complex B2B SaaS system targeting a specific vertical (trade businesses) with proven market demand. The focus is on automating lead generation and sales processes that traditionally require significant manual effort. The integration between lead generation and CRM is critical for system success.
