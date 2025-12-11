# Web Build Guide

This guide explains how to build and deploy the Montessori Color Theory game for the web.

## Quick Start

1. **Build the web version:**
   ```bash
   npm install
   npm run build
   ```

2. **Test locally:**
   ```bash
   npm run serve
   ```
   Open `http://localhost:3000` in your browser

3. **Deploy to Vercel:**
   ```bash
   vercel --prod
   ```

## Build Process

The build process:

1. Downloads love.js (if not already present) - clones from GitHub
2. Compiles `dist/MontessoriColorTheory.love` to web format
3. Outputs files to `web-build/` directory
4. Optimizes `web-build/index.html` with loading screen and meta tags

## Directory Structure

```
Montessori_Color_Theory/
├── build-web.js          # Main build script
├── optimize-web-build.js # Post-build optimization
├── package.json          # Node.js dependencies
├── vercel.json          # Vercel configuration
├── web-build/           # Generated web files (gitignored)
│   ├── index.html
│   ├── game.js
│   ├── game.wasm
│   ├── game.data
│   └── love.js
└── dist/                # Original .love file (preserved)
    └── MontessoriColorTheory.love
```

## Requirements

- **Node.js** v14 or later
- **Git** (for downloading love.js)
- **Internet connection** (for downloading love.js on first build)

## Troubleshooting

### Build fails with "git clone" error
- Ensure Git is installed: `git --version`
- Check internet connection
- Try manually cloning love.js: `git clone https://github.com/Davidobot/love.js.git`

### Build fails with "love.js not found"
- The build script should download love.js automatically
- If it fails, manually clone: `git clone --branch 11.5 https://github.com/Davidobot/love.js.git`

### Web build doesn't work in browser
- Ensure browser supports WebAssembly (Chrome, Firefox, Safari, Edge)
- Check browser console for errors
- Verify all files are present in `web-build/` directory

### Vercel deployment fails
- Check that `vercel.json` is in the root directory
- Verify build command: `npm run build`
- Verify output directory: `web-build`
- Check Vercel build logs for specific errors

## Notes

- Original game files (`main.lua`, `conf.lua`, etc.) remain untouched
- Web build is completely separate in `web-build/` directory
- The `.love` file in `dist/` is used as input for the build
- First build may take several minutes (downloading love.js)
- Subsequent builds are faster (love.js is cached)

