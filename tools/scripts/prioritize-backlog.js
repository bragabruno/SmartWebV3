#!/usr/bin/env node

import { ClaudeLinearManager } from '../lib/claude-linear-manager.js';
import dotenv from 'dotenv';
import chalk from 'chalk';
import { homedir } from 'os';
import { join } from 'path';

// Load environment variables from ~/.env.private
dotenv.config({ path: join(homedir(), '.env.private') });

async function prioritizeBacklog() {
  console.log(chalk.blue.bold('🔄 Backlog Prioritization (RICE Framework)\n'));
  
  try {
    const manager = new ClaudeLinearManager();
    
    console.log(chalk.blue('🤖 Analyzing backlog with RICE framework...\n'));
    const prioritization = await manager.prioritizeBacklog();
    
    console.log(chalk.white('─'.repeat(80)));
    console.log(prioritization);
    console.log(chalk.white('─'.repeat(80)));
    
    console.log(chalk.gray('\n💡 RICE Framework:'));
    console.log(chalk.gray('   Reach: How many users/customers affected (1-10)'));
    console.log(chalk.gray('   Impact: Business value impact (1-5)'));
    console.log(chalk.gray('   Confidence: Certainty of estimates (0.5-1.0)'));
    console.log(chalk.gray('   Effort: Development complexity (1-10)'));
    console.log(chalk.gray('   Score = (Reach × Impact × Confidence) ÷ Effort'));
    
  } catch (error) {
    console.error(chalk.red('❌ Error prioritizing backlog:'), error.message);
    process.exit(1);
  }
}

prioritizeBacklog();
