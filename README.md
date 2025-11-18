# Montessori Color Theory - LOVE2D App

A LOVE2D (LÖVE) game framework project.

## Prerequisites

Install LOVE2D from [love2d.org](https://love2d.org/):
- **macOS**: Download from the website or use Homebrew: `brew install love`
- **Windows**: Download the installer from the website
- **Linux**: Use your package manager or download from the website

## Running the Game

### Method 1: Drag and Drop
1. Navigate to the project folder
2. Drag the entire folder onto the LOVE2D application icon

### Method 2: Command Line
```bash
love .
```

Or if LOVE2D is in your PATH:
```bash
cd /Users/drewswanberg/Desktop/Montessori_Color_Theory
love .
```

## Project Structure

- `main.lua` - Main entry point for the game
- `conf.lua` - Configuration file for window settings and module options
- `README.md` - This file

## Development

The game loop consists of three main functions:
- `love.load()` - Called once when the game starts
- `love.update(dt)` - Called every frame to update game logic
- `love.draw()` - Called every frame to render graphics

## Resources

- [LOVE2D Wiki](https://love2d.org/wiki/Main_Page)
- [LOVE2D Forums](https://love2d.org/forums/)
- [Lua Documentation](https://www.lua.org/manual/5.1/)

