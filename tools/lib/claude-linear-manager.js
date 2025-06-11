import { LinearClient } from '@linear/sdk';
import Anthropic from '@anthropic-ai/sdk';
import { Octokit } from '@octokit/rest';
import chalk from 'chalk';
import dotenv from 'dotenv';
import { homedir } from 'os';
import { join } from 'path';

// Load environment variables from ~/.env.private
dotenv.config({ path: join(homedir(), '.env.private') });

export class ClaudeLinearManager {
  constructor(config = {}) {
    this.linear = new LinearClient({
      apiKey: process.env.LINEAR_API_KEY
    });
    
    this.claude = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY
    });
    
    this.github = new Octokit({
      auth: process.env.GITHUB_TOKEN
    });
    
    this.config = {
      teamId: process.env.LINEAR_TEAM_ID,
      workspaceId: process.env.LINEAR_WORKSPACE_ID,
      ...config
    };
  }

  // 🎯 Generate user stories from requirements
  async generateUserStories(requirement, context = {}) {
    console.log(chalk.blue('🤖 Generating user stories with Claude...'));
    
    const prompt = `
Convert this requirement into well-structured user stories for the SmartWebV3 project:

**Requirement**: ${requirement}

**Project Context**: SmartWebV3 is a B2B SaaS platform targeting trade businesses (electricians, plumbers, roofers) with two main components:

1. **Trade Lead Generator**: 
   - n8n workflows for automated lead discovery
   - AI-powered lead scoring (0-100 points)
   - Data enrichment from Google My Business, state licensing boards
   - Real-time CRM integration via webhooks

2. **AI Cold Caller CRM**:
   - AI voice agents with 57% higher connect rates
   - Seven-stage sales pipeline management
   - Automated proposal generation (90% time reduction)
   - Contract management with e-signatures

**Target Users**:
- Sales Representatives (cold calling, pipeline management)
- Business Owners (ROI tracking, lead quality)
- System Administrators (configuration, monitoring)
- Trade Business Owners (end customers for websites)

Generate 3-5 user stories. For each story, provide:

**Format**:
\`\`\`json
{
  "stories": [
    {
      "title": "Brief, actionable title",
      "story": "As a [user type], I want [goal] so that [benefit]",
      "acceptance_criteria": [
        "Given [context], when [action], then [result]",
        "Error handling: [what happens when things go wrong]"
      ],
      "technical_notes": "Key technical considerations",
      "estimate": 3,
      "priority": "High",
      "labels": ["component", "type", "priority"],
      "component": "lead-generator|ai-crm|infrastructure",
      "business_value": "Quantified impact on revenue/efficiency"
    }
  ]
}
\`\`\`

Focus on stories that deliver immediate business value and have clear, testable acceptance criteria.
`;

    try {
      const response = await this.claude.messages.create({
        model: 'claude-3-5-sonnet-20241022',
        max_tokens: 2000,
        messages: [{ role: 'user', content: prompt }]
      });

      const content = response.content[0].text;
      const jsonMatch = content.match(/```json\n([\s\S]*?)\n```/);
      
      if (jsonMatch) {
        const stories = JSON.parse(jsonMatch[1]);
        console.log(chalk.green(`✅ Generated ${stories.stories.length} user stories`));
        return stories.stories;
      } else {
        throw new Error('Could not parse JSON from Claude response');
      }
    } catch (error) {
      console.error(chalk.red('❌ Error generating user stories:'), error);
      throw error;
    }
  }

  // 📝 Create Linear tickets from user stories
  async createLinearTickets(userStories, projectId) {
    console.log(chalk.blue('📝 Creating Linear tickets...'));
    const tickets = [];
    
    try {
      for (const story of userStories) {
        const description = this.formatStoryDescription(story);
        
        const issue = await this.linear.issueCreate({
          teamId: this.config.teamId,
          projectId: projectId,
          title: story.title,
          description: description,
          estimate: story.estimate,
          priority: this.mapPriority(story.priority),
          labelIds: await this.createOrGetLabels(story.labels)
        });
        
        tickets.push(issue.issue);
        console.log(chalk.green(`✅ Created: ${story.title}`));
      }
      
      return tickets;
    } catch (error) {
      console.error(chalk.red('❌ Error creating tickets:'), error);
      throw error;
    }
  }

  // 🏃‍♂️ Generate daily standup summary
  async generateStandupSummary() {
    console.log(chalk.blue('🏃‍♂️ Generating standup summary...'));
    
    try {
      const issues = await this.linear.issues({
        filter: {
          team: { id: { eq: this.config.teamId } },
          state: { type: { nin: ['completed', 'canceled'] } }
        }
      });

      const prompt = `
Generate a concise daily standup summary for SmartWebV3:

**Active Issues** (${issues.nodes.length} total):
${issues.nodes.map(issue => 
  `- ${issue.title} (${issue.assignee?.name || 'Unassigned'}) - ${issue.state.name} [${issue.estimate || '?'} pts]`
).join('\n')}

**Sprint Context**: 2-week sprints focusing on lead generation ROI and AI calling conversion rates.

**Format**:
🎯 **Sprint Progress**: [X/Y story points completed] ([percentage]%)
🚀 **Completed Yesterday**: [list completed items]  
📋 **Today's Focus**: [top 3 priority items for today]
🚨 **Blockers**: [any impediments or dependencies]
📈 **Velocity**: [on track/behind/ahead of sprint goal]
🔄 **Integration Status**: [lead-gen → CRM data flow health]

Keep it concise and actionable for a 5-minute standup.
`;

      const response = await this.claude.messages.create({
        model: 'claude-3-5-sonnet-20241022',
        max_tokens: 1000,
        messages: [{ role: 'user', content: prompt }]
      });

      const summary = response.content[0].text;
      console.log(chalk.green('✅ Standup summary generated'));
      return summary;
    } catch (error) {
      console.error(chalk.red('❌ Error generating standup:'), error);
      throw error;
    }
  }

  // 🎯 Smart sprint planning
  async planSprint(sprintCapacity = 40, teamVelocity = 35) {
    console.log(chalk.blue('🎯 Planning sprint with Claude...'));
    
    try {
      const backlogIssues = await this.linear.issues({
        filter: {
          team: { id: { eq: this.config.teamId } },
          state: { name: { eq: 'Backlog' } }
        }
      });

      const prompt = `
Plan an optimal 2-week sprint for SmartWebV3:

**Available Backlog** (${backlogIssues.nodes.length} items):
${backlogIssues.nodes.map(issue => 
  `- ${issue.title} [${issue.estimate || '?'} pts] - ${issue.priority} priority`
).join('\n')}

**Sprint Parameters**:
- Team Capacity: ${sprintCapacity} story points
- Historical Velocity: ${teamVelocity} points/sprint
- Sprint Duration: 2 weeks

**SmartWebV3 Priorities**:
1. **Revenue Impact**: Lead generation features (direct ROI)
2. **AI Calling**: Conversion rate improvements
3. **Integration**: Reliable data flow between systems
4. **Infrastructure**: Scalability and performance
5. **Technical Debt**: Code quality and maintainability

**Selection Criteria**:
- Critical path dependencies (database → API → frontend)
- Business value (revenue-generating features first)  
- Technical risk (complex integrations early in sprint)
- Team capacity (parallel work opportunities)
- Integration testing requirements

**Format**:
\`\`\`json
{
  "sprint_plan": {
    "selected_issues": [
      {
        "title": "Issue title",
        "estimate": 5,
        "priority": "High",
        "reasoning": "Why this was selected",
        "dependencies": ["List of dependencies"],
        "risk_level": "Low|Medium|High"
      }
    ],
    "total_points": 38,
    "sprint_goal": "Primary objective for this sprint",
    "success_criteria": ["Measurable outcome 1", "Measurable outcome 2"],
    "risks": ["Risk 1", "Risk 2"],
    "recommendations": ["Actionable recommendation"]
  }
}
\`\`\`
`;

      const response = await this.claude.messages.create({
        model: 'claude-3-5-sonnet-20241022',
        max_tokens: 2000,
        messages: [{ role: 'user', content: prompt }]
      });

      const content = response.content[0].text;
      const jsonMatch = content.match(/```json\n([\s\S]*?)\n```/);
      
      if (jsonMatch) {
        const sprintPlan = JSON.parse(jsonMatch[1]);
        console.log(chalk.green(`✅ Sprint planned: ${sprintPlan.sprint_plan.total_points} points`));
        return sprintPlan.sprint_plan;
      } else {
        throw new Error('Could not parse JSON from Claude response');
      }
    } catch (error) {
      console.error(chalk.red('❌ Error planning sprint:'), error);
      throw error;
    }
  }

  // 🔄 Prioritize backlog using RICE framework
  async prioritizeBacklog() {
    console.log(chalk.blue('🔄 Prioritizing backlog...'));
    
    try {
      const backlogIssues = await this.linear.issues({
        filter: {
          team: { id: { eq: this.config.teamId } },
          state: { name: { eq: 'Backlog' } }
        }
      });

      const prompt = `
Prioritize SmartWebV3 backlog using RICE framework:
**RICE Score = (Reach × Impact × Confidence) ÷ Effort**

**Backlog Items**:
${backlogIssues.nodes.map(issue => 
  `- ${issue.title}: ${issue.description || 'No description'} [${issue.estimate || '?'} pts]`
).join('\n')}

**SmartWebV3 Context**:
- **Reach**: How many users/customers affected
- **Impact**: Business value (revenue, conversion rates, efficiency)
- **Confidence**: How certain are we about reach/impact estimates
- **Effort**: Development complexity and time

**Scoring Guide**:
- Reach: 1-10 (1=few users, 10=all users)
- Impact: 1-5 (1=minimal, 5=massive business impact)  
- Confidence: 0.5-1.0 (0.5=low confidence, 1.0=high confidence)
- Effort: 1-10 (1=minimal effort, 10=massive effort)

**Business Impact Weights**:
- Lead generation features: High impact (direct revenue)
- AI calling improvements: Medium-high impact  
- Integration reliability: High reach, medium impact
- Infrastructure: High reach, lower immediate impact
- UI/UX improvements: Medium reach, medium impact

Return prioritized list with RICE scores and reasoning.
`;

      const response = await this.claude.messages.create({
        model: 'claude-3-5-sonnet-20241022',
        max_tokens: 2000,
        messages: [{ role: 'user', content: prompt }]
      });

      const prioritization = response.content[0].text;
      console.log(chalk.green('✅ Backlog prioritized'));
      return prioritization;
    } catch (error) {
      console.error(chalk.red('❌ Error prioritizing backlog:'), error);
      throw error;
    }
  }

  // Helper methods
  formatStoryDescription(story) {
    return `
**User Story**: ${story.story}

**Business Value**: ${story.business_value}

**Acceptance Criteria**:
${story.acceptance_criteria.map(ac => `- [ ] ${ac}`).join('\n')}

**Technical Notes**: ${story.technical_notes}

**Component**: ${story.component}

---
*Generated by Claude + Linear integration*
`.trim();
  }

  mapPriority(priority) {
    const priorityMap = {
      'Low': 4,
      'Medium': 3,
      'High': 2,
      'Urgent': 1
    };
    return priorityMap[priority] || 3;
  }

  async createOrGetLabels(labelNames) {
    const team = await this.linear.team(this.config.teamId);
    const existingLabels = await team.labels();
    const labelIds = [];
    
    for (const labelName of labelNames) {
      let label = existingLabels.nodes.find(l => l.name === labelName);
      if (!label) {
        const newLabel = await this.linear.issueLabel.create({
          teamId: this.config.teamId,
          name: labelName,
          color: this.getLabelColor(labelName)
        });
        label = newLabel.issueLabel;
      }
      labelIds.push(label.id);
    }
    
    return labelIds;
  }

  getLabelColor(labelName) {
    const colorMap = {
      'lead-generator': '#10B981',
      'ai-crm': '#3B82F6', 
      'infrastructure': '#6B7280',
      'bug': '#EF4444',
      'enhancement': '#10B981',
      'high': '#EF4444',
      'medium': '#F59E0B',
      'low': '#6B7280'
    };
    return colorMap[labelName.toLowerCase()] || '#6B7280';
  }
}

export default ClaudeLinearManager;
