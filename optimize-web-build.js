#!/usr/bin/env node

/**
 * Post-build optimization script for web-build/index.html
 * Adds loading screen, meta tags, and other optimizations
 */

const fs = require('fs');
const path = require('path');

const INDEX_HTML = path.join(__dirname, 'web-build', 'index.html');

if (!fs.existsSync(INDEX_HTML)) {
    console.log('index.html not found, skipping optimization...');
    process.exit(0);
}

console.log('Optimizing web-build/index.html...');

let html = fs.readFileSync(INDEX_HTML, 'utf8');

// Add loading screen CSS and HTML before the canvas
const loadingScreenCSS = `
<style>
  #love-loading {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    z-index: 9999;
    color: white;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  }
  #love-loading.hidden {
    display: none;
  }
  .loading-spinner {
    width: 50px;
    height: 50px;
    border: 4px solid rgba(255, 255, 255, 0.3);
    border-top-color: white;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-bottom: 20px;
  }
  @keyframes spin {
    to { transform: rotate(360deg); }
  }
  .loading-text {
    font-size: 18px;
    font-weight: 500;
    margin-top: 10px;
  }
  .loading-subtext {
    font-size: 14px;
    opacity: 0.8;
    margin-top: 5px;
  }
</style>
`;

const loadingScreenHTML = `
<div id="love-loading">
  <div class="loading-spinner"></div>
  <div class="loading-text">Loading Montessori Color Theory</div>
  <div class="loading-subtext">Please wait...</div>
</div>
`;

// Add loading screen removal script
const loadingScreenScript = `
<script>
  // Hide loading screen when game is ready
  window.addEventListener('load', function() {
    setTimeout(function() {
      var loading = document.getElementById('love-loading');
      if (loading) {
        loading.classList.add('hidden');
        setTimeout(function() {
          loading.style.display = 'none';
        }, 300);
      }
    }, 500);
  });
</script>
`;

// Insert CSS in head
if (html.includes('</head>')) {
    html = html.replace('</head>', loadingScreenCSS + '</head>');
} else if (html.includes('<head>')) {
    html = html.replace('<head>', '<head>' + loadingScreenCSS);
} else {
    html = loadingScreenCSS + html;
}

// Insert loading screen HTML before canvas
if (html.includes('<canvas')) {
    const canvasIndex = html.indexOf('<canvas');
    html = html.slice(0, canvasIndex) + loadingScreenHTML + html.slice(canvasIndex);
} else if (html.includes('<body>')) {
    html = html.replace('<body>', '<body>' + loadingScreenHTML);
}

// Insert loading screen removal script before closing body tag
if (html.includes('</body>')) {
    html = html.replace('</body>', loadingScreenScript + '</body>');
} else {
    html = html + loadingScreenScript;
}

// Add meta tags for better mobile support and SEO
const metaTags = `
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<meta name="description" content="Interactive educational application for exploring color theory through hands-on color mixing. Learn about additive (RGB), subtractive (CYM), and traditional paint (RYB) color mixing.">
<meta name="theme-color" content="#667eea">
`;

if (html.includes('</head>')) {
    html = html.replace('</head>', metaTags + '</head>');
} else if (html.includes('<head>')) {
    html = html.replace('<head>', '<head>' + metaTags);
}

// Write optimized HTML
fs.writeFileSync(INDEX_HTML, html, 'utf8');

console.log('✓ Optimization complete!');

