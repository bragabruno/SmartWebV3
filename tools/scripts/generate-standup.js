#!/usr/bin/env node

import { ClaudeLinearManager } from '../lib/claude-linear-manager.js';
import dotenv from 'dotenv';
import chalk from 'chalk';
import { homedir } from 'os';
import { join } from 'path';

// Load environment variables from ~/.env.private
dotenv.config({ path: join(homedir(), '.env.private') });

async function generateStandup() {
  console.log(chalk.blue.bold('🏃‍♂️ Daily Standup Generator\n'));
  
  try {
    const manager = new ClaudeLinearManager();
    const summary = await manager.generateStandupSummary();
    
    console.log(chalk.white('─'.repeat(60)));
    console.log(summary);
    console.log(chalk.white('─'.repeat(60)));
    
    // Optionally post to Slack or save to file
    const now = new Date().toISOString().split('T')[0];
    console.log(chalk.gray(`\n💡 Tip: Copy this summary to your team standup or save as standup-${now}.md`));
    
  } catch (error) {
    console.error(chalk.red('❌ Error generating standup:'), error.message);
    process.exit(1);
  }
}

generateStandup();
