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
const LOVE_JS_VERSION = '11.5'; // Match LOVE2D version in conf.lua
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
const loveJsCli = path.join(loveJsPath, 'love.js');

if (!fs.existsSync(loveJsPath)) {
    console.log('love.js not found. Downloading...');
    console.log('This may take a few minutes...\n');
    
    try {
        // Clone love.js repository
        console.log(`Cloning love.js (LOVE ${LOVE_JS_VERSION})...`);
        execSync(`git clone --depth 1 --branch ${LOVE_JS_VERSION} ${LOVE_JS_REPO} ${loveJsPath}`, {
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
    // Run love.js compiler
    // Note: love.js expects to be run from its directory
    const command = `node ${loveJsCli} "${LOVE_FILE}" "${OUTPUT_DIR}" --title "Montessori Color Theory"`;
    
    execSync(command, {
        stdio: 'inherit',
        cwd: __dirname,
        env: { ...process.env, NODE_PATH: loveJsPath }
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

