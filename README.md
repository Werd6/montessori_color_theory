# Montessori Color Theory

An interactive educational application for exploring color theory through hands-on color mixing. Learn about additive (RGB), subtractive (CYM), and traditional paint (RYB) color mixing by dragging and dropping colored circles to create new colors.

![Montessori Color Theory](https://img.shields.io/badge/LOVE2D-11.5-blue)

## Features

- **Three Color Mixing Modes:**
  - **RGB Mode**: Additive color mixing (light) - Red, Green, Blue primaries
  - **CYM Mode**: Subtractiv color mixing (pigments) - Cyan, Yellow, Magenta primaries
  - **Paint Mode**: Traditional RYB color mixing - Red, Yellow, Blue primaries

- **Interactive Color Discovery:**
  - Drag circles from the sidebar onto the canvas
  - Watch colors blend where circles overlap
  - Automatically detect and unlock new color combinations
  - Get notified when you discover a new color with its name
  - Unlocked colors are automatically added to your palette

- **Smart Canvas System:**
  - Separate background layer (doesn't affect color blending)
  - Accurate color blending calculations
  - Circles automatically clear after unlocking colors

## Download

### Standalone Executables (No Installation Required) ⭐

**These work immediately - no LOVE2D or any other software needed!**

- **macOS**: [MontessoriColorTheory-macOS.zip](dist/MontessoriColorTheory-macOS.zip) (27 MB)
  - Extract and double-click `MontessoriColorTheory.app` to run
  - No LOVE2D installation needed
  
- **Windows**: [MontessoriColorTheory-Windows.zip](dist/MontessoriColorTheory-Windows.zip) (4.3 MB)
  - Extract and double-click `MontessoriColorTheory.exe` to run
  - No LOVE2D installation needed
  - All required files included in the ZIP

### LOVE2D Package (Requires LOVE2D Installation)

**Only use this if you already have LOVE2D installed:**

- **Game Package**: [MontessoriColorTheory.love](dist/MontessoriColorTheory.love) (21 KB)
  - Requires [LOVE2D 11.5+](https://love2d.org/) to be installed first
  - Double-click the `.love` file to run (if LOVE2D is installed)

## Quick Start (Standalone Executables)

### macOS

1. Download `MontessoriColorTheory-macOS.zip`
2. Extract the ZIP file (double-click it)
3. Double-click `MontessoriColorTheory.app` to launch
4. **No LOVE2D installation needed!** Everything is included.

**First-time security warning?**
- Go to **System Settings** → **Privacy & Security**
- Click **Open Anyway** next to the warning message
- Or right-click the app → **Open** → confirm

### Windows

1. Download `MontessoriColorTheory-Windows.zip`
2. Extract the ZIP file (right-click → Extract All)
3. Double-click `MontessoriColorTheory.exe` to launch
4. **No LOVE2D installation needed!** Everything is included.

**Windows Defender warning?**
- Click **More info**
- Click **Run anyway**
- The executable is safe - it's just the game bundled with the engine

**Note:** Keep all files in the extracted folder together (the `.exe` needs the `.dll` files in the same folder).

## Using LOVE2D Package (Alternative Method)

**Only if you already have LOVE2D installed:**

1. Install [LOVE2D](https://love2d.org/) (version 11.5 or later) if you haven't already
2. Download `MontessoriColorTheory.love`
3. Double-click the `.love` file, or
4. Drag and drop it onto the LOVE2D application, or
5. Run from terminal: `love /path/to/MontessoriColorTheory.love`

## Web Version (Play in Browser)

**Play directly in your web browser - no download required!**

The game is available as a web application that runs entirely in your browser using WebAssembly. No installation needed!

### Play Online

- **Live Demo**: [Play on Vercel](https://your-vercel-url.vercel.app) *(Update with your actual Vercel URL after deployment)*

### Build Web Version Locally

If you want to build the web version yourself:

**Prerequisites:**
- Node.js (v14 or later)
- Git (for downloading love.js)

**Build Steps:**

1. Install dependencies:
   ```bash
   npm install
   ```

2. Build the web version:
   ```bash
   npm run build
   ```

3. Test locally:
   ```bash
   npm run serve
   ```
   Then open `http://localhost:3000` in your browser

**Build Output:**
- The web build is created in the `web-build/` directory
- Original files remain untouched in the root directory
- The build includes all necessary files (HTML, JS, WASM, data files)

### Deploy to Vercel

**Option 1: Using Vercel CLI**
```bash
npm install -g vercel
vercel --prod
```

**Option 2: Using GitHub Integration**
1. Push your code to GitHub
2. Connect your repository to Vercel
3. Vercel will automatically build and deploy on every push

**Note:** The `vercel.json` configuration file is already set up with proper headers for WASM files and routing.

### Web Version Requirements

- Modern web browser with WebAssembly support (Chrome, Firefox, Safari, Edge)
- Internet connection (for initial load)
- No additional software needed!

## How to Use

### Basic Controls

1. **Select a Mode**: Use the dropdown menu in the top-right corner to switch between RGB, CYM, and Paint modes

2. **Drag Circles**: Click and drag colored circles from the left sidebar onto the canvas

3. **Create New Colors**: Overlap circles to blend colors and create new combinations

4. **Unlock Colors**: When you create a new color, a popup will appear showing:
   - The color name
   - A preview of the color
   - Click the X button to close the notification

5. **Multiple Colors**: If you create multiple new colors at once, notifications will queue up - close each one to see the next

6. **Auto-Clear**: After closing all color unlock notifications, the circles used to create those colors will automatically clear from the canvas

7. **Clear Canvas**: Click the "Clear" button in the top-right to manually clear all circles from the canvas

8. **Scroll Sidebar**: If you have many unlocked colors, scroll the sidebar to see them all

### Color Mixing Modes

#### RGB Mode (Additive)
- Start with Red, Green, Blue, and Black circles
- Colors add together (like light)
- Red + Green = Yellow
- Red + Blue = Magenta
- Green + Blue = Cyan
- All three = White
- Black circle darkens colors

#### CYM Mode (Subtractive)
- Start with Cyan, Yellow, Magenta, and White circles
- Colors subtract from each other (like pigments)
- Cyan + Yellow = Green
- Cyan + Magenta = Blue
- Yellow + Magenta = Red
- All three = Black
- White circle lightens colors

#### Paint Mode (RYB)
- Start with Red, Yellow, Blue, and White circles
- Traditional paint mixing
- Red + Yellow = Orange
- Yellow + Blue = Green
- Red + Blue = Purple
- All three = Brown/Gray
- White circle lightens colors

## Requirements

### Standalone Executables (Recommended)
- **macOS**: macOS 10.11 or later
- **Windows**: Windows 7 or later
- **No additional software needed!** The game engine is included.

### LOVE2D Package
- LOVE2D 11.5 or later must be installed separately
- Available for Windows, macOS, and Linux

### Web Version
- Modern web browser with WebAssembly support
- No installation required
- Works on Windows, macOS, Linux, iOS, and Android

## Technical Details

- Built with LOVE2D 11.5
- Uses advanced color blending algorithms for accurate color mixing
- Includes a database of 950+ color names for automatic color identification
- Web version compiled with [love.js](https://github.com/Davidobot/love.js) (Emscripten)
- Deployed on Vercel for fast global CDN delivery

## License

This project is provided as-is for educational purposes.

## Credits

Built with [LOVE2D](https://love2d.org/) - an awesome framework for making 2D games.

---

**Enjoy exploring color theory!** 🎨
