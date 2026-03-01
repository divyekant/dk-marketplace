#!/usr/bin/env node

import { capture, cleanupScreenshots } from '../src/index.js';

const args = process.argv.slice(2);

function printUsage() {
  console.error(`Usage: ui-val <command> [options]

Commands:
  check <url>    Capture screenshots for visual validation
  clean          Delete all screenshots from .ui-val/screenshots/

Options (check):
  --viewports=desktop,tablet,mobile   Viewports to check (default: all three)
  --wait=3000                         Wait ms after page load (default: 3000)
  --pages=/,/about                    Pages to check (default: /)
  --help                              Show this help

Examples:
  ui-val check http://localhost:5173
  ui-val check http://localhost:5173 --viewports=mobile
  ui-val check http://localhost:5173 --pages=/,/about
  ui-val clean`);
}

async function main() {
  const command = args[0];

  if (!command || command === '--help' || command === '-h') {
    printUsage();
    process.exit(0);
  }

  if (command === 'clean') {
    const result = await cleanupScreenshots();
    console.log(JSON.stringify(result));
    process.exit(0);
  }

  if (command !== 'check') {
    console.error(`Unknown command: ${command}`);
    printUsage();
    process.exit(2);
  }

  const url = args[1];
  if (!url) {
    console.error('Error: URL is required');
    printUsage();
    process.exit(2);
  }

  // Parse options from --key=value args
  const options = {};
  for (const arg of args.slice(2)) {
    const match = arg.match(/^--(\w[\w-]*)=(.+)$/);
    if (match) {
      options[match[1]] = match[2];
    } else if (arg === '--help' || arg === '-h') {
      printUsage();
      process.exit(0);
    } else {
      console.error(`Unknown argument: ${arg}`);
      printUsage();
      process.exit(2);
    }
  }

  // Handle multi-page validation
  const pages = options.pages ? options.pages.split(',').map((p) => p.trim()) : ['/'];
  delete options.pages;

  try {
    for (const page of pages) {
      const fullUrl = page === '/' ? url : new URL(page, url).href;

      if (pages.length > 1) {
        console.error(`\n--- Capturing: ${fullUrl} ---`);
      }

      const result = await capture(fullUrl, options);
      console.log(result);
    }
  } catch (err) {
    console.error(`Error: ${err.message}`);
    process.exit(1);
  }
}

main();
