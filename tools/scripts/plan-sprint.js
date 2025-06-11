#!/usr/bin/env node

import { ClaudeLinearManager } from '../lib/claude-linear-manager.js';
import inquirer from 'inquirer';
import dotenv from 'dotenv';
import chalk from 'chalk';
import { homedir } from 'os';
import { join } from 'path';

// Load environment variables from ~/.env.private
dotenv.config({ path: join(homedir(), '.env.private') });

async function planSprint() {
  console.log(chalk.blue.bold('🎯 Sprint Planning Assistant\n'));
  
  try {
    const manager = new ClaudeLinearManager();
    
    // Get sprint parameters from user
    const { sprintCapacity, teamVelocity } = await inquirer.prompt([
      {
        type: 'number',
        name: 'sprintCapacity',
        message: 'Team capacity for this sprint (story points):',
        default: 40,
        validate: (input) => input > 0 || 'Capacity must be greater than 0'
      },
      {
        type: 'number',
        name: 'teamVelocity',
        message: 'Historical team velocity (story points):',
        default: 35,
        validate: (input) => input > 0 || 'Velocity must be greater than 0'
      }
    ]);

    console.log(chalk.blue('\n🤖 Analyzing backlog and planning sprint...\n'));
    const sprintPlan = await manager.planSprint(sprintCapacity, teamVelocity);
    
    // Display sprint plan
    console.log(chalk.green.bold('✅ Sprint Plan Generated:\n'));
    
    console.log(chalk.yellow.bold(`🎯 Sprint Goal: ${sprintPlan.sprint_goal}\n`));
    
    console.log(chalk.white.bold('📋 Selected Issues:'));
    sprintPlan.selected_issues.forEach((issue, index) => {
      console.log(chalk.white(`${index + 1}. ${issue.title} (${issue.estimate} pts)`));
      console.log(chalk.gray(`   Priority: ${issue.priority} | Risk: ${issue.risk_level}`));
      console.log(chalk.gray(`   Reasoning: ${issue.reasoning}`));
      if (issue.dependencies.length > 0) {
        console.log(chalk.yellow(`   Dependencies: ${issue.dependencies.join(', ')}`));
      }
      console.log('');
    });
    
    console.log(chalk.cyan.bold(`📊 Total Story Points: ${sprintPlan.total_points}/${sprintCapacity}`));
    console.log(chalk.cyan(`📈 Capacity Utilization: ${Math.round((sprintPlan.total_points / sprintCapacity) * 100)}%\n`));
    
    console.log(chalk.white.bold('🎯 Success Criteria:'));
    sprintPlan.success_criteria.forEach(criteria => {
      console.log(chalk.white(`   ✓ ${criteria}`));
    });
    console.log('');
    
    if (sprintPlan.risks.length > 0) {
      console.log(chalk.red.bold('🚨 Identified Risks:'));
      sprintPlan.risks.forEach(risk => {
        console.log(chalk.red(`   ⚠️  ${risk}`));
      });
      console.log('');
    }
    
    console.log(chalk.blue.bold('💡 Recommendations:'));
    sprintPlan.recommendations.forEach(rec => {
      console.log(chalk.blue(`   💡 ${rec}`));
    });
    
  } catch (error) {
    console.error(chalk.red('❌ Error planning sprint:'), error.message);
    process.exit(1);
  }
}

planSprint();
