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

## Architecture Patterns

**State Management**: The Player uses a simple enum-based state machine (IDLE, WALKING, RUNNING, JUMPING, FALLING, COMBAT) with direct state transitions in `change_state()`. Each state triggers corresponding animations and UI updates.

**CSG-Based Geometry**: The LevelBuilder uses CSG (Constructive Solid Geometry) primitives for all level geometry. Rooms use CSGBox3D for floors/walls, doors are created by strategically placed wall segments with gaps, and enemy placeholders use CSGCylinder3D. While functional, this approach is performance-heavy compared to optimized meshes.

**JSON-Driven Systems**: Both level layout and input mapping are defined externally in JSON files, allowing for data-driven configuration without code changes. The InputLoader dynamically creates Godot InputMap actions from JSON definitions.

**Node Hierarchy Dependencies**: The Player controller assumes specific child node names (Skeleton, CameraPivot, CameraArm, etc.) and uses `get_node_or_null()` to find them. Missing nodes are handled gracefully with fallback behavior.

**Camera System**: Third-person camera using SpringArm3D for collision avoidance, with mouse look controls applying to a CameraPivot node. Camera rotation is separate from player mesh rotation.

**Animation System**: Currently expects an AnimationLibrary resource (`player_animations.tres`) but falls back gracefully if animations are missing. Animation calls are made by string name.

## Code Conventions

- GDScript language
- French comments and debug messages are acceptable (used throughout codebase)
- Class names use PascalCase (LevelBuilder, Player)
- Constants use UPPER_SNAKE_CASE
- Use `@export` for inspector-editable properties
- Error handling includes fallback default content creation
- Debug print statements use emoji prefixes for categorization (📋, 🎮, ⚠️, etc.)

## Performance Considerations

**CSG Geometry Performance**: The current CSG-based level generation creates heavy geometry. Each CSGBox3D is much more expensive than an optimized MeshInstance3D. Consider replacing with pre-made room prefabs or procedural MeshInstance3D generation for better performance.

**State Machine Scaling**: The current enum-based state machine works for basic states but will become unwieldy with more complex behaviors. Consider implementing a proper state machine pattern with separate state classes for better organization and maintainability.

**Animation System**: The current string-based animation system is fragile and doesn't provide compile-time validation. Consider using AnimationTree for more complex animation blending and state management.

## Critical Dependencies

- **Node Structure**: Player functionality depends on specific child node names and hierarchy in `player.tscn`
- **JSON Data**: Level generation requires properly formatted JSON with specific field names in `data/levels/`
- **Input Actions**: InputLoader creates actions dynamically, so any hardcoded Input.is_action_pressed() calls depend on JSON configuration
- **Animation Resources**: Player expects `res://animations/player_animations.tres` AnimationLibrary resource
- **Autoload**: InputLoader must be registered as autoload singleton for input system to work

## Important File Locations

- Game logic: `scripts/`
- Level data: `data/levels/`
- Input configuration: `data/inputs.json`
- Main scene: `Main.tscn`
- Player prefab: `Scenes/Player/player.tscn`
- Animation library: `animations/player_animations.tres`
- Godot project config: `project.godot`
