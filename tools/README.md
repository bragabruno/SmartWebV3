# SmartWebV3 Linear + Claude Integration Tools

Intelligent project management automation for the SmartWebV3 platform using Linear and Claude AI.

## 🚀 Quick Start

### 1. Installation

```bash
cd ~/Developer/dev.bak/BragDev/SmartWebV3/tools
npm install
```

### 2. Setup Linear Workspace

```bash
npm run setup
```

This interactive setup will:
- Connect to your Linear account
- Create or select a team for SmartWebV3
- Set up project structure (Lead Generation, AI CRM, Infrastructure)
- Create labels and initial epic issues
- Generate `.env` configuration file

### 3. Add API Keys

The setup script saves configuration to `~/.env.private`. Add your API keys:

```bash
# Edit ~/.env.private and add:
# Get from https://console.anthropic.com/
ANTHROPIC_API_KEY=your_claude_api_key

# Get from https://github.com/settings/tokens  
GITHUB_TOKEN=your_github_token
```

**Security Note**: Using `~/.env.private` keeps your API keys secure and separate from your project repository.

### 4. Test the Integration

```bash
npm run standup
```

## 📋 Available Commands

### Daily Workflows

```bash
# Generate daily standup summary
npm run standup

# Create user stories from requirements
npm run create-stories

# Plan next sprint with AI assistance
npm run plan-sprint

# Prioritize backlog using RICE framework
npm run prioritize

# Generate performance metrics
npm run metrics
```

### Direct Script Usage

```bash
# Generate standup summary
node scripts/generate-standup.js

# Create user stories interactively
node scripts/create-stories.js

# Plan sprint with capacity planning
node scripts/plan-sprint.js

# Prioritize backlog items
node scripts/prioritize-backlog.js
```

## 🤖 Claude Integration Features

### 1. User Story Generation

Convert requirements into well-structured user stories:

```javascript
const manager = new ClaudeLinearManager();
const stories = await manager.generateUserStories(
  "Build a dashboard showing real-time pipeline metrics"
);
```

**Example Output:**
```json
{
  "title": "Pipeline Analytics Dashboard",
  "story": "As a sales manager, I want to see real-time pipeline metrics so that I can track team performance and identify bottlenecks",
  "acceptance_criteria": [
    "Given I'm on the dashboard, when I view pipeline metrics, then I see current stage distribution",
    "Error handling: Dashboard shows friendly message when data is unavailable"
  ],
  "estimate": 8,
  "priority": "High",
  "component": "ai-crm",
  "business_value": "Improves sales visibility and decision-making by 40%"
}
```

### 2. Sprint Planning

AI-powered sprint planning with capacity optimization:

```bash
npm run plan-sprint
```

**Features:**
- Analyzes backlog items by business value and technical complexity
- Considers team capacity and historical velocity
- Identifies dependencies and risks
- Recommends optimal work distribution

### 3. Daily Standup Automation

Generate comprehensive standup summaries:

```bash
npm run standup
```

**Output Format:**
```
🎯 Sprint Progress: 28/40 story points completed (70%)
🚀 Completed Yesterday: Lead scoring algorithm, API integration tests
📋 Today's Focus: Voice AI setup, proposal template system, database optimization
🚨 Blockers: Waiting for Google My Business API approval
📈 Velocity: On track to meet sprint goal
🔄 Integration Status: Lead-gen → CRM data flow healthy
```

### 4. Backlog Prioritization

RICE framework analysis for optimal prioritization:

```bash
npm run prioritize
```

**RICE Scoring:**
- **Reach**: How many users affected (1-10)
- **Impact**: Business value (1-5) 
- **Confidence**: Certainty of estimates (0.5-1.0)
- **Effort**: Development complexity (1-10)
- **Score**: (Reach × Impact × Confidence) ÷ Effort

## 🏗️ Project Structure

```
tools/
├── lib/
│   └── claude-linear-manager.js    # Main integration class
├── scripts/
│   ├── setup-linear.js            # Interactive Linear setup
│   ├── generate-standup.js        # Daily standup generator
│   ├── create-stories.js          # User story creator
│   ├── plan-sprint.js             # Sprint planning assistant
│   └── prioritize-backlog.js      # Backlog prioritization
├── templates/
│   ├── epic-template.md           # Epic issue template
│   ├── user-story-template.md     # User story template
│   └── bug-report-template.md     # Bug report template
├── package.json                   # Dependencies and scripts
├── .env.example                   # Environment template
└── README.md                      # This file
```

## 🎯 SmartWebV3 Linear Structure

### Projects Created:
1. **SmartWebV3 Platform** 🚀 - Main coordination project
2. **Lead Generation System** 🎯 - n8n workflows and lead scoring
3. **AI Cold Caller CRM** 🤖 - Voice agents and pipeline management
4. **Infrastructure & DevOps** 🔧 - Shared services and deployment

### Labels System:
- **Components**: `lead-generator`, `ai-crm`, `infrastructure`, `frontend`, `backend`
- **Types**: `feature`, `bug`, `enhancement`, `technical-debt`, `documentation`
- **Priorities**: `high-priority`, `medium-priority`, `low-priority`
- **Status**: `blocked`, `needs-review`, `ready-for-qa`

### Epic Issues Created:
- 🎯 Lead Generation System - Core Infrastructure (21 pts)
- 🤖 AI Cold Caller CRM - Voice Agent Setup (34 pts)
- 📊 Seven-Stage Sales Pipeline Management (21 pts)
- 📄 Automated Proposal Generation System (18 pts)
- 🔧 Shared Infrastructure & Integration Layer (25 pts)

## 📈 Usage Examples

### Creating User Stories from Feature Requests

```bash
npm run create-stories
```

**Input Example:**
```
Feature Request: Sales reps need to see which leads are most likely to convert so they can prioritize their calling efforts.
```

**Claude generates:**
1. Lead scoring dashboard with visual indicators
2. Lead prioritization queue with filtering
3. Historical conversion data integration
4. Mobile-responsive lead list interface
5. Real-time score updates from lead generation system

### Sprint Planning Session

```bash
npm run plan-sprint
# Enter capacity: 40 story points
# Enter velocity: 35 story points
```

**Claude analyzes:**
- Current backlog items with estimates and priorities
- Team velocity trends and capacity constraints
- Technical dependencies between features
- Business value optimization
- Risk assessment and mitigation strategies

**Output:**
- Recommended sprint backlog with reasoning
- Capacity utilization analysis
- Success criteria definition
- Risk identification and recommendations

### Daily Team Coordination

```bash
npm run standup
```

**Use cases:**
- Pre-standup meeting preparation
- Async team updates for remote members
- Progress tracking for stakeholder reports
- Blocker identification and escalation

## 🔧 Advanced Configuration

### Custom Prompts

You can customize Claude prompts by modifying the `ClaudeLinearManager` class:

```javascript
// Custom user story prompt
const customPrompt = `
Generate user stories for ${requirement} with emphasis on:
- Trade business specific use cases
- ROI and conversion rate improvements
- Integration with existing n8n workflows
- Mobile-first design for field sales teams
`;
```

### Webhook Integration

Set up webhooks for automatic ticket creation:

```javascript
// GitHub webhook → Linear ticket
app.post('/webhook/github', async (req, res) => {
  const { issue } = req.body;
  const manager = new ClaudeLinearManager();
  await manager.createLinearFromGitHubIssue(issue);
});
```

### Slack Integration

Post standup summaries to Slack:

```bash
# Add to .env
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
SLACK_CHANNEL=#smartwebv3-dev

# Automated daily posting
npm run standup --slack
```

## 🚨 Troubleshooting

### Common Issues

**Linear API Connection Failed**
```bash
Error: Invalid API key or connection failed
```
- Verify your Linear API key at https://linear.app/settings/api
- Check that the API key has correct permissions

**Claude API Rate Limiting**
```bash
Error: Rate limit exceeded
```
- Claude has generous rate limits, but check your usage at https://console.anthropic.com/
- Add delays between requests if processing large batches

**GitHub Integration Issues**
```bash
Error: Bad credentials
```
- GitHub token needs `repo` and `read:org` permissions
- Generate new token at https://github.com/settings/tokens

### Debug Mode

Enable verbose logging by adding to `~/.env.private`:

```bash
# Add to ~/.env.private
LOG_LEVEL=debug

# Then run commands normally
npm run standup
```

## 📚 API Reference

### ClaudeLinearManager Methods

```javascript
// Generate user stories from requirement text
await manager.generateUserStories(requirement, context)

// Create Linear tickets from user story objects  
await manager.createLinearTickets(stories, projectId)

// Generate daily standup summary
await manager.generateStandupSummary()

// Plan sprint with AI optimization
await manager.planSprint(capacity, velocity)

// Prioritize backlog using RICE framework
await manager.prioritizeBacklog()
```

### Environment Variables

All environment variables are stored in `~/.env.private` for security:

| Variable | Required | Description |
|----------|----------|-------------|
| `LINEAR_API_KEY` | Yes | Linear API key (auto-generated by setup) |
| `LINEAR_TEAM_ID` | Yes | Linear team ID (auto-generated by setup) |
| `ANTHROPIC_API_KEY` | Yes | Claude API key (add manually) |
| `GITHUB_TOKEN` | Optional | GitHub integration (add manually) |
| `SLACK_WEBHOOK_URL` | Optional | Slack notifications |

## 🎯 Best Practices

### 1. Daily Usage Pattern
```bash
# Morning routine
npm run standup           # Generate standup summary
npm run prioritize        # Review backlog priorities

# Sprint planning (bi-weekly)
npm run plan-sprint       # Plan next sprint

# Feature development
npm run create-stories    # Convert requirements to stories
```

### 2. Team Coordination
- Share standup summaries in team chat
- Use sprint plans for capacity discussions
- Reference RICE scores in prioritization meetings
- Create tickets directly from Claude analysis

### 3. Integration Workflow
- Linear tickets → GitHub issues (automatic)
- GitHub PRs → Linear ticket updates (webhook)
- Code reviews → improvement tickets (automated)
- Sprint completion → retrospective analysis (Claude)

## 🔄 Continuous Improvement

The integration learns from your team's patterns:
- Sprint velocity trends inform capacity planning
- Ticket completion rates optimize story point estimates  
- User feedback improves story generation quality
- Performance metrics guide prioritization decisions

## 🤝 Contributing

To extend the integration:

1. Fork the repository
2. Add new scripts to `/scripts/` directory
3. Extend `ClaudeLinearManager` class for new features
4. Update this README with new functionality
5. Submit pull request with examples

## 📄 License

MIT License - see the [LICENSE](../LICENSE) file for details.

---

**Built with ❤️ for efficient agile development**
