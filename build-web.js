#!/usr/bin/env node

/**
 * Build script for compiling LOVE2D game to web using love.js
 * Outputs to web-build/ directory
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const LOVE_FILE = path.join(__dirname, 'dist', 'MontessoriColorTheory.love');
const OUTPUT_DIR = path.join(__dirname, 'web-build');
// love.js uses main branch - version compatibility is handled by the love.js runtime
const LOVE_JS_REPO = 'https://github.com/Davidobot/love.js.git';

console.log('Building Montessori Color Theory for web...\n');

// Check if .love file exists
if (!fs.existsSync(LOVE_FILE)) {
    console.error(`Error: ${LOVE_FILE} not found!`);
    console.error('Please ensure the .love file exists in dist/ directory.');
    process.exit(1);
}

// Check for love.js
const loveJsPath = path.join(__dirname, 'love.js');
// love.js CLI might be in different locations - check common paths
let loveJsCli = path.join(loveJsPath, 'love.js');
if (!fs.existsSync(loveJsCli)) {
    // Try alternative locations
    const alternatives = [
        path.join(loveJsPath, 'compile.js'),
        path.join(loveJsPath, 'tools', 'compile.js'),
        path.join(loveJsPath, 'bin', 'love.js'),
        path.join(loveJsPath, 'compile')
    ];
    for (const alt of alternatives) {
        if (fs.existsSync(alt)) {
            loveJsCli = alt;
            break;
        }
    }
}

if (!fs.existsSync(loveJsPath)) {
    console.log('love.js not found. Downloading...');
    console.log('This may take a few minutes...\n');
    
    try {
        // Clone love.js repository (main branch contains latest version)
        console.log('Cloning love.js from GitHub...');
        execSync(`git clone --depth 1 ${LOVE_JS_REPO} ${loveJsPath}`, {
            stdio: 'inherit',
            cwd: __dirname
        });
        console.log('love.js downloaded successfully!\n');
    } catch (error) {
        console.error('Error downloading love.js:', error.message);
        console.error('\nPlease ensure git is installed and try again.');
        console.error('Alternatively, manually download love.js from:');
        console.error(`  ${LOVE_JS_REPO}`);
        process.exit(1);
    }
}

// Create output directory if it doesn't exist
if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

// Build the web version
console.log('Compiling .love file to web format...');
console.log(`Input: ${LOVE_FILE}`);
console.log(`Output: ${OUTPUT_DIR}\n`);

try {
    // Check if love.js CLI exists
    if (!fs.existsSync(loveJsCli)) {
        // List directory to help debug
        console.error(`Error: love.js CLI not found at ${loveJsCli}`);
        console.error(`love.js directory contents:`);
        try {
            const files = fs.readdirSync(loveJsPath);
            console.error(files.slice(0, 20).join(', '));
        } catch (e) {
            console.error('Could not read love.js directory');
        }
        process.exit(1);
    }
    
    // Run love.js compiler
    // love.js typically needs to be run from its own directory
    const command = `node "${loveJsCli}" "${LOVE_FILE}" "${OUTPUT_DIR}" --title "Montessori Color Theory"`;
    
    execSync(command, {
        stdio: 'inherit',
        cwd: loveJsPath, // Run from love.js directory
        env: process.env
    });
    
    // Run post-build optimization
    console.log('\nOptimizing web build...');
    try {
        require('./optimize-web-build.js');
    } catch (error) {
        console.warn('Warning: Could not run optimization script:', error.message);
    }
    
    console.log('\n✓ Build completed successfully!');
    console.log(`\nWeb build is available in: ${OUTPUT_DIR}`);
    console.log('\nTo test locally, run:');
    console.log('  npm run serve');
    console.log('\nTo deploy to Vercel:');
    console.log('  vercel --prod');
    
} catch (error) {
    console.error('\n✗ Build failed:', error.message);
    process.exit(1);
}

