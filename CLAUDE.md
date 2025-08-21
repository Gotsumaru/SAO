# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.4 3D game project called "SAO" that features JSON-driven level generation. The game implements a dungeon crawler with dynamic room-based level loading, player movement, and enemy placeholders.

## Key Architecture Components

### Core Systems

**LevelBuilder System** (`scripts/LevelBuilder.gd`): The heart of the procedural level generation
- Loads level definitions from JSON files in `data/levels/`
- Creates 3D rooms with walls, doors, floors using CSG geometry
- Manages bidirectional room connections and door placement
- Supports different room types: empty, combat, treasure, boss
- Each room is 10x10 units with 3-unit high walls
- Enemy placeholders are generated from JSON data

**Input System** (`scripts/InputLoader.gd`): JSON-driven input mapping
- Loads control schemes from `data/inputs.json`
- Supports keyboard, mouse, and gamepad inputs
- Dynamically creates Godot InputMap actions from JSON configuration
- Registered as autoload singleton

**Player Controller** (`scripts/Player.gd`): Third-person character controller
- State machine: IDLE, WALKING, RUNNING, JUMPING, FALLING, COMBAT
- Stamina-based sprint system
- Camera-relative movement with mesh rotation
- Health and stamina management

### Data Structure

**Level JSON Format** (`data/levels/test_level.json`):
```json
{
  "name": "Level Name",
  "rooms": [
	{"id": 1, "x": 0, "y": 0, "type": "empty", "enemies": [...]}
  ],
  "connections": [
	{"from": 1, "to": 2, "direction": "east"}
  ]
}
```

**Input JSON Format** (`data/inputs.json`):
- Actions defined with multiple input types (key, mouse_button, joy_button, joy_axis)
- Supports deadzone configuration for analog inputs

### Scene Structure

- `Main.tscn`: Root scene with basic environment
- `Scenes/Player/player.tscn`: Player character with camera rig
- Level geometry is generated procedurally by LevelBuilder, not stored in scenes

## Development Commands

This is a Godot project - use the Godot Editor for building, testing, and exporting. There are no external build commands like npm or cargo.

**Running the game:**
- Open project in Godot Editor (4.4+)
- Press F5 or click Play button
- Main scene is set to `Main.tscn`

**Key Development Notes:**

- The InputLoader autoload runs on game start to configure input mapping
- Level generation happens in LevelBuilder's `_ready()` function
- Default level is `res://data/levels/test_level.json`
- If JSON files are missing, fallback systems create default content
- Player spawns at world origin (0,1,0)

## Code Conventions

- GDScript language
- French comments and debug messages are acceptable (used throughout codebase)
- Class names use PascalCase (LevelBuilder, Player)
- Constants use UPPER_SNAKE_CASE
- Use `@export` for inspector-editable properties
- Error handling includes fallback default content creation
- Debug print statements use emoji prefixes for categorization (📋, 🎮, ⚠️, etc.)

## Important File Locations

- Game logic: `scripts/`
- Level data: `data/levels/`
- Input configuration: `data/inputs.json`
- Main scene: `Main.tscn`
- Player prefab: `Scenes/Player/player.tscn`
- Godot project config: `project.godot`
