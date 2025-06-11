#!/usr/bin/env node

import { ClaudeLinearManager } from '../lib/claude-linear-manager.js';
import inquirer from 'inquirer';
import dotenv from 'dotenv';
import chalk from 'chalk';
import { homedir } from 'os';
import { join } from 'path';

// Load environment variables from ~/.env.private
dotenv.config({ path: join(homedir(), '.env.private') });

async function createUserStories() {
  console.log(chalk.blue.bold('🎯 User Story Generator\n'));
  
  try {
    const manager = new ClaudeLinearManager();
    
    // Get requirement from user
    const { requirement } = await inquirer.prompt([
      {
        type: 'editor',
        name: 'requirement',
        message: 'Enter your requirement or feature description:',
        default: 'Example: As a sales rep, I need to see a dashboard showing my pipeline progress...'
      }
    ]);

    console.log(chalk.blue('\n🤖 Generating user stories with Claude...\n'));
    const stories = await manager.generateUserStories(requirement);
    
    // Display generated stories
    console.log(chalk.green.bold(`✅ Generated ${stories.length} user stories:\n`));
    
    stories.forEach((story, index) => {
      console.log(chalk.yellow(`${index + 1}. ${story.title}`));
      console.log(chalk.white(`   ${story.story}`));
      console.log(chalk.gray(`   Component: ${story.component} | Estimate: ${story.estimate} pts | Priority: ${story.priority}`));
      console.log('');
    });

    // Ask if user wants to create tickets in Linear
    const { createTickets } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'createTickets',
        message: 'Create these tickets in Linear?',
        default: true
      }
    ]);

    if (createTickets) {
      // Get available projects
      const projects = await manager.linear.projects();
      const projectChoices = projects.nodes.map(project => ({
        name: project.name,
        value: project.id
      }));

      const { selectedProject } = await inquirer.prompt([
        {
          type: 'list',
          name: 'selectedProject',
          message: 'Select a project:',
          choices: projectChoices
        }
      ]);

      console.log(chalk.blue('\n📝 Creating tickets in Linear...\n'));
      const tickets = await manager.createLinearTickets(stories, selectedProject);
      
      console.log(chalk.green.bold(`✅ Created ${tickets.length} tickets in Linear!`));
      tickets.forEach(ticket => {
        console.log(chalk.gray(`   - ${ticket.title} (${ticket.identifier})`));
      });
    }
    
  } catch (error) {
    console.error(chalk.red('❌ Error creating user stories:'), error.message);
    process.exit(1);
  }
}

createUserStories();
