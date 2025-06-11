#!/usr/bin/env node

import { LinearClient } from '@linear/sdk';
import inquirer from 'inquirer';
import chalk from 'chalk';
import ora from 'ora';
import dotenv from 'dotenv';
import { writeFileSync, readFileSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { homedir } from 'os';

// Load environment variables from ~/.env.private
const privateEnvPath = join(homedir(), '.env.private');
dotenv.config({ path: privateEnvPath });

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

class LinearSetup {
  constructor() {
    this.linear = null;
    this.config = {};
  }

  async run() {
    console.log(chalk.blue.bold('\n🚀 SmartWebV3 Linear + Claude Setup\n'));
    
    try {
      await this.getLinearCredentials();
      await this.selectOrCreateTeam();
      await this.createProjectStructure();
      await this.setupLabels();
      await this.createInitialIssues();
      await this.saveConfiguration();
      
      console.log(chalk.green.bold('\n✅ Setup complete! Your SmartWebV3 Linear workspace is ready.\n'));
      this.printNextSteps();
    } catch (error) {
      console.error(chalk.red('❌ Setup failed:'), error.message);
      process.exit(1);
    }
  }

  async getLinearCredentials() {
    let apiKey = process.env.LINEAR_API_KEY;
    
    if (!apiKey) {
      console.log(chalk.yellow('📝 Linear API Key not found in environment variables.'));
      console.log('Get your API key from: https://linear.app/settings/api\n');
      
      const { inputApiKey } = await inquirer.prompt([
        {
          type: 'password',
          name: 'inputApiKey',
          message: 'Enter your Linear API key:',
          validate: (input) => input.length > 0 || 'API key is required'
        }
      ]);
      
      apiKey = inputApiKey;
    }

    this.linear = new LinearClient({ apiKey });
    this.config.apiKey = apiKey;

    // Test the connection
    const spinner = ora('Testing Linear connection...').start();
    try {
      const viewer = await this.linear.viewer;
      spinner.succeed(`Connected as ${viewer.name} (${viewer.email})`);
      this.config.userId = viewer.id;
    } catch (error) {
      spinner.fail('Failed to connect to Linear');
      throw new Error('Invalid API key or connection failed');
    }
  }

  async selectOrCreateTeam() {
    const spinner = ora('Fetching teams...').start();
    const teams = await this.linear.teams();
    spinner.stop();

    const teamChoices = teams.nodes.map(team => ({
      name: `${team.name} (${team.key})`,
      value: team
    }));

    teamChoices.push({
      name: '➕ Create new team for SmartWebV3',
      value: 'create'
    });

    const { selectedTeam } = await inquirer.prompt([
      {
        type: 'list',
        name: 'selectedTeam',
        message: 'Select or create a team for SmartWebV3:',
        choices: teamChoices
      }
    ]);

    if (selectedTeam === 'create') {
      const { teamName, teamKey } = await inquirer.prompt([
        {
          type: 'input',
          name: 'teamName',
          message: 'Team name:',
          default: 'SmartWebV3'
        },
        {
          type: 'input',
          name: 'teamKey',
          message: 'Team key (2-5 characters):',
          default: 'SW3',
          validate: (input) => {
            if (input.length < 2 || input.length > 5) {
              return 'Team key must be 2-5 characters';
            }
            return true;
          }
        }
      ]);

      const createSpinner = ora('Creating team...').start();
      const newTeam = await this.linear.teamCreate({
        name: teamName,
        key: teamKey.toUpperCase()
      });
      createSpinner.succeed(`Team "${teamName}" created`);
      
      this.config.team = newTeam.team;
    } else {
      this.config.team = selectedTeam;
    }

    console.log(chalk.green(`✅ Using team: ${this.config.team.name} (${this.config.team.key})`));
  }

  async createProjectStructure() {
    console.log(chalk.blue('\n📊 Creating SmartWebV3 project structure...\n'));

    const projects = [
      {
        name: 'SmartWebV3 Platform',
        description: 'Main project for the SmartWebV3 B2B SaaS platform',
        color: '#3B82F6',
        icon: '🚀'
      },
      {
        name: 'Lead Generation System',
        description: 'Automated trade business discovery and lead qualification',
        color: '#10B981',
        icon: '🎯'
      },
      {
        name: 'AI Cold Caller CRM',
        description: 'AI-powered sales automation and pipeline management',
        color: '#8B5CF6',
        icon: '🤖'
      },
      {
        name: 'Infrastructure & DevOps',
        description: 'Shared infrastructure, deployment, and monitoring',
        color: '#6B7280',
        icon: '🔧'
      }
    ];

    this.config.projects = {};

    for (const projectData of projects) {
      const spinner = ora(`Creating project: ${projectData.name}`).start();
      
      try {
        const project = await this.linear.projectCreate({
          teamIds: [this.config.team.id],
          name: projectData.name,
          description: projectData.description,
          color: projectData.color,
          icon: projectData.icon
        });
        
        this.config.projects[projectData.name] = project.project;
        spinner.succeed(`Created: ${projectData.name}`);
      } catch (error) {
        spinner.fail(`Failed to create: ${projectData.name}`);
        throw error;
      }
    }
  }

  async setupLabels() {
    console.log(chalk.blue('\n🏷️  Setting up labels...\n'));

    const labels = [
      // Component labels
      { name: 'lead-generator', color: '#10B981', description: 'Lead generation system components' },
      { name: 'ai-crm', color: '#3B82F6', description: 'AI CRM system components' },
      { name: 'infrastructure', color: '#6B7280', description: 'Shared infrastructure and DevOps' },
      { name: 'frontend', color: '#F59E0B', description: 'Frontend and UI components' },
      { name: 'backend', color: '#8B5CF6', description: 'Backend API and services' },
      { name: 'database', color: '#EF4444', description: 'Database and data layer' },
      
      // Type labels
      { name: 'feature', color: '#10B981', description: 'New feature development' },
      { name: 'bug', color: '#EF4444', description: 'Bug fixes and issues' },
      { name: 'enhancement', color: '#3B82F6', description: 'Improvements to existing features' },
      { name: 'technical-debt', color: '#F59E0B', description: 'Technical debt and refactoring' },
      { name: 'documentation', color: '#6B7280', description: 'Documentation updates' },
      
      // Priority labels
      { name: 'high-priority', color: '#EF4444', description: 'High priority items' },
      { name: 'medium-priority', color: '#F59E0B', description: 'Medium priority items' },
      { name: 'low-priority', color: '#6B7280', description: 'Low priority items' },
      
      // Special labels
      { name: 'blocked', color: '#EF4444', description: 'Blocked by dependencies' },
      { name: 'needs-review', color: '#8B5CF6', description: 'Needs code or design review' },
      { name: 'ready-for-qa', color: '#10B981', description: 'Ready for quality assurance' }
    ];

    for (const labelData of labels) {
      const spinner = ora(`Creating label: ${labelData.name}`).start();
      
      try {
        await this.linear.issueLabelCreate({
          teamId: this.config.team.id,
          name: labelData.name,
          color: labelData.color,
          description: labelData.description
        });
        
        spinner.succeed(`Created: ${labelData.name}`);
      } catch (error) {
        if (error.message.includes('already exists')) {
          spinner.warn(`Exists: ${labelData.name}`);
        } else {
          spinner.fail(`Failed: ${labelData.name}`);
          throw error;
        }
      }
    }
  }

  async createInitialIssues() {
    console.log(chalk.blue('\n📝 Creating initial epic issues...\n'));

    const epics = [
      {
        title: '🎯 Lead Generation System - Core Infrastructure',
        description: `**Epic Goal**: Build the foundation for automated trade business lead discovery and qualification.

**Business Value**: 
- Generate 400-667 qualified leads monthly for website services
- Achieve 1,000-2,500 total leads processed daily
- Target 37% of trade businesses lacking professional websites

**Success Metrics**:
- [ ] 95%+ data accuracy in lead contact information
- [ ] 80+ point lead scoring system operational
- [ ] Real-time CRM integration with <200ms response time
- [ ] 90%+ email deliverability rate

**Components**:
- n8n workflow engine setup
- Database schema for lead management  
- Google My Business API integration
- State licensing board data sources
- Lead scoring algorithm implementation
- Webhook integration with CRM system

**Acceptance Criteria**:
- [ ] System processes 1,000+ leads daily without performance degradation
- [ ] Lead qualification accuracy verified through manual sampling
- [ ] Integration testing with AI CRM system completed
- [ ] Performance benchmarks met (sub-100ms query response)`,
        estimate: 21,
        priority: 1,
        projectName: 'Lead Generation System',
        labels: ['lead-generator', 'feature', 'high-priority']
      },
      {
        title: '🤖 AI Cold Caller CRM - Voice Agent Setup',
        description: `**Epic Goal**: Implement AI-powered voice agents for automated cold calling with 57% higher connect rates.

**Business Value**:
- Achieve 25-35% improvement in lead-to-sale conversion rates
- Reduce sales cycle time by 30-50%
- Enable 60 calls per day per rep with 6-10 meaningful conversations

**Success Metrics**:
- [ ] 57% higher phone receptivity vs traditional methods
- [ ] 70% improvement in appointment booking rates
- [ ] 80% appointment show rate for AI-scheduled meetings
- [ ] 4.2/5.0 average customer satisfaction with AI interactions

**Components**:
- OpenAI GPT-4o integration for conversation intelligence
- Voice recognition and synthesis setup
- Real-time coaching system for human agents
- Call recording and transcription pipeline
- Sentiment analysis and outcome tracking
- Integration with Linear pipeline management

**Acceptance Criteria**:
- [ ] AI agents complete 85% of attempted calls successfully
- [ ] Real-time coaching improves rep performance by 30-50%
- [ ] Call quality scores exceed 4.0/5.0 consistently
- [ ] System scales to handle 100+ concurrent calls`,
        estimate: 34,
        priority: 1,
        projectName: 'AI Cold Caller CRM',
        labels: ['ai-crm', 'feature', 'high-priority']
      },
      {
        title: '📊 Seven-Stage Sales Pipeline Management',
        description: `**Epic Goal**: Build intelligent pipeline management system optimized for trade business website sales.

**Business Value**:
- Standardize sales process for consistent results
- Enable accurate sales forecasting and capacity planning
- Automate 70% of routine pipeline management tasks

**Success Metrics**:
- [ ] 80%+ sprint goal achievement rate
- [ ] <5 day lead time from qualification to proposal
- [ ] 90%+ estimate accuracy within 1 story point
- [ ] Automated progression for 85% of stage transitions

**Pipeline Stages**:
1. Lead Qualification (auto-entry from lead gen)
2. Initial Contact (60% progression rate target)
3. Needs Assessment (45% progression rate target)
4. Proposal Presentation (35% progression rate target)
5. Contract Negotiation (65% close rate target)
6. Project Kickoff (95% success rate target)
7. Customer Success (40% upsell rate target)

**Components**:
- Pipeline visualization dashboard
- Automated stage progression triggers
- Deal prioritization and scoring
- Activity tracking and reminders
- Performance analytics and reporting
- Integration with proposal generation system

**Acceptance Criteria**:
- [ ] Pipeline handles 100+ concurrent opportunities
- [ ] Real-time updates across all team members
- [ ] Mobile-responsive interface for field sales
- [ ] Comprehensive audit trail for all activities`,
        estimate: 21,
        priority: 2,
        projectName: 'AI Cold Caller CRM',
        labels: ['ai-crm', 'feature', 'medium-priority']
      },
      {
        title: '📄 Automated Proposal Generation System',
        description: `**Epic Goal**: Reduce proposal creation time by 90% while maintaining high quality and personalization.

**Business Value**:
- Generate proposals in <5 minutes vs 90 minutes manually
- Improve proposal consistency and professional appearance
- Enable real-time proposal tracking and engagement analytics

**Success Metrics**:
- [ ] 90% reduction in proposal creation time
- [ ] 35% increase in proposal-to-close conversion rate
- [ ] 100% mobile-responsive proposal experience
- [ ] Real-time engagement tracking for all proposals

**Components**:
- Dynamic template engine with business-specific customization
- CRM data integration for automatic population
- Interactive pricing tables and package options
- E-signature integration (DocuSign/PandaDoc)
- Proposal analytics and engagement tracking
- Mobile-optimized proposal viewing experience

**Features**:
- Template library for different trade business types
- Automated competitive analysis inclusion
- Interactive ROI calculators for prospects
- Embedded video messages from sales reps
- Live chat integration during proposal review
- Automated follow-up sequences based on engagement

**Acceptance Criteria**:
- [ ] Proposals generated within 5 minutes of initiation
- [ ] 95%+ template accuracy with CRM data population
- [ ] Mobile viewing experience rated 4.5/5.0 by prospects
- [ ] E-signature completion rate >80% within 48 hours`,
        estimate: 18,
        priority: 2,
        projectName: 'AI Cold Caller CRM',
        labels: ['ai-crm', 'feature', 'medium-priority']
      },
      {
        title: '🔧 Shared Infrastructure & Integration Layer',
        description: `**Epic Goal**: Build robust, scalable infrastructure supporting both lead generation and AI CRM systems.

**Business Value**:
- Enable seamless data flow between lead generation and CRM
- Ensure system reliability with 99.9% uptime
- Support horizontal scaling from 10 to 10,000+ users

**Success Metrics**:
- [ ] 99.9% system uptime with automated failover
- [ ] <100ms response time for all user interactions
- [ ] Real-time data synchronization with <15ms latency
- [ ] Support for 10,000+ concurrent users

**Components**:
- Supabase database optimization and scaling
- Real-time subscription management
- API gateway with rate limiting and authentication
- Webhook infrastructure for system integration
- Monitoring and alerting system
- Automated backup and disaster recovery

**Integration Points**:
- Lead Generation → CRM webhook integration
- Bidirectional status synchronization
- Unified authentication and authorization
- Shared component library for frontend
- Common logging and monitoring infrastructure
- Centralized configuration management

**Acceptance Criteria**:
- [ ] Zero-downtime deployments implemented
- [ ] Comprehensive monitoring with 5-minute alert SLA
- [ ] Automated scaling based on load patterns
- [ ] Full disaster recovery tested and documented`,
        estimate: 25,
        priority: 2,
        projectName: 'Infrastructure & DevOps',
        labels: ['infrastructure', 'feature', 'medium-priority']
      }
    ];

    for (const epic of epics) {
      const spinner = ora(`Creating epic: ${epic.title}`).start();
      
      try {
        const project = this.config.projects[epic.projectName];
        
        await this.linear.issueCreate({
          teamId: this.config.team.id,
          projectId: project.id,
          title: epic.title,
          description: epic.description,
          estimate: epic.estimate,
          priority: epic.priority,
          // Note: Label assignment will be handled after labels are fully created
        });
        
        spinner.succeed(`Created: ${epic.title}`);
      } catch (error) {
        spinner.fail(`Failed: ${epic.title}`);
        console.error(error);
      }
    }
  }

  async saveConfiguration() {
    const newConfig = {
      // SmartWebV3 Linear Configuration
      LINEAR_API_KEY: this.config.apiKey,
      LINEAR_TEAM_ID: this.config.team.id,
      LINEAR_WORKSPACE_ID: this.config.team.organization.id,
      SMARTWEBV3_TEAM_NAME: this.config.team.name,
      SMARTWEBV3_TEAM_KEY: this.config.team.key
    };

    // Read existing ~/.env.private if it exists
    let existingContent = '';
    if (existsSync(privateEnvPath)) {
      existingContent = readFileSync(privateEnvPath, 'utf-8');
    }

    // Parse existing environment variables
    const existingVars = {};
    existingContent.split('\n').forEach(line => {
      const [key, ...values] = line.split('=');
      if (key && values.length > 0) {
        existingVars[key.trim()] = values.join('=').trim();
      }
    });

    // Merge configurations (new config takes precedence)
    const mergedConfig = { ...existingVars, ...newConfig };

    // Generate new content
    const configEntries = Object.entries(mergedConfig)
      .filter(([key, value]) => key && value)
      .map(([key, value]) => `${key}=${value}`);

    let newContent = '# SmartWebV3 + Claude Linear Integration\n';
    newContent += '# This file contains your private API keys and configuration\n\n';
    
    // Add SmartWebV3 section
    newContent += '# === SmartWebV3 Linear Configuration ===\n';
    const smartwebEntries = configEntries
      .filter(entry => entry.split('=')[0].startsWith('LINEAR_') || entry.split('=')[0].startsWith('SMARTWEBV3_'));
    newContent += smartwebEntries.join('\n') + '\n\n';
    
    // Add Claude section
    if (!mergedConfig.ANTHROPIC_API_KEY) {
      newContent += '# === Claude AI Configuration ===\n';
      newContent += '# Get your API key from: https://console.anthropic.com/\n';
      newContent += '# ANTHROPIC_API_KEY=your_claude_api_key_here\n\n';
    } else {
      newContent += '# === Claude AI Configuration ===\n';
      newContent += `ANTHROPIC_API_KEY=${mergedConfig.ANTHROPIC_API_KEY}\n\n`;
    }
    
    // Add GitHub section
    if (!mergedConfig.GITHUB_TOKEN) {
      newContent += '# === GitHub Integration ===\n';
      newContent += '# Get your token from: https://github.com/settings/tokens\n';
      newContent += '# GITHUB_TOKEN=your_github_token_here\n\n';
    } else {
      newContent += '# === GitHub Integration ===\n';
      newContent += `GITHUB_TOKEN=${mergedConfig.GITHUB_TOKEN}\n\n`;
    }
    
    // Add other existing variables
    const otherVars = configEntries
      .filter(([key]) => !key.startsWith('LINEAR_') && !key.startsWith('SMARTWEBV3_') && 
                         key !== 'ANTHROPIC_API_KEY' && key !== 'GITHUB_TOKEN')
      .join('\n');
    
    if (otherVars) {
      newContent += '# === Other Configuration ===\n';
      newContent += otherVars + '\n';
    }

    writeFileSync(privateEnvPath, newContent);
    console.log(chalk.green(`✅ Configuration saved to ${privateEnvPath}`));
  }

  printNextSteps() {
    console.log(chalk.blue.bold('🎯 Next Steps:\n'));
    
    console.log(chalk.white('1. Add your API keys to ~/.env.private:'));
    console.log(chalk.gray('   - ANTHROPIC_API_KEY (get from https://console.anthropic.com/)'));
    console.log(chalk.gray('   - GITHUB_TOKEN (get from https://github.com/settings/tokens)'));
    console.log(chalk.gray(`   - Edit: ${privateEnvPath}\n`));
    
    console.log(chalk.white('2. Install dependencies:'));
    console.log(chalk.gray('   cd tools && npm install\n'));
    
    console.log(chalk.white('3. Test the integration:'));
    console.log(chalk.gray('   npm run standup\n'));
    
    console.log(chalk.white('4. Visit your Linear workspace:'));
    console.log(chalk.gray(`   https://linear.app/team/${this.config.team.key}\n`));
    
    console.log(chalk.green.bold('🚀 Your SmartWebV3 workspace is ready for agile development!'));
    console.log(chalk.yellow('\n💡 Pro tip: ~/.env.private keeps your API keys secure and separate from your project.'));
  }
}

// Run the setup
const setup = new LinearSetup();
setup.run().catch(console.error);
