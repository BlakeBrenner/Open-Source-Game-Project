# Project Changes and Development Log

This document summarizes the major changes, systems implemented, and design decisions made during the development of **Tower Climb — Wizard Frog Vertical Platformer**.

The project was developed as an original game, with systems added iteratively and refined over time.

---

## Initial Project State

The project began as a simple vertical platformer prototype with:
- A controllable player character
- A small number of static platforms
- Basic gravity and jump mechanics

At this stage, there was no procedural generation, scoring, hazards, or upgrades.

---

## Major Systems Implemented

### Procedural Platform Generation
- Implemented a platform spawner capable of generating an infinite vertical tower.
- Platforms are spawned above the player as they climb.
- Horizontal and vertical placement uses a zig-zag pattern to encourage movement variety.
- Horizontal bounds ensure platforms remain within the visible background.
- Added logic to prevent platforms from spawning too close together or overlapping.

### Reachability-Based Spawning
- Platform spacing is calculated using the player’s actual jump physics.
- Vertical gaps are clamped to the maximum reachable jump height.
- Horizontal spacing is clamped to the player’s maximum horizontal reach during a jump.
- This ensures all platforms are always physically reachable without requiring frame-perfect movement.

### Platform Types
Added multiple platform variations:
- **Small Platforms** – Basic static platforms.
- **Big Platforms** – Wider, safer platforms.
- **Moving Platforms** – Platforms that move horizontally and carry the player.
- **Bonus Platforms** – Platforms that spawn multiple coins.
- **Spiked Platforms** – Hazard platforms with safe tops and deadly side spikes.
- **Shop Platforms** – Special platforms that open the upgrade shop.

Logic was added to prevent:
- Platforms spawning directly above or below spiked platforms.
- Unfair platform stacking.

---

### Player Controller Enhancements
- Implemented smooth horizontal movement and jumping using CharacterBody2D.
- Added jump buffering and variable jump height.
- Added support for double jump.
- Player movement can be disabled during shop interactions or game over states.
- Integrated support for moving platforms so the player is carried correctly.

---

### Coin System
- Coins spawn dynamically on platforms.
- Coins register themselves with the main game scene.
- Collecting coins updates the UI in real time.
- Coins are used as currency in the shop system.

---

### Upgrade Shop System
- Implemented a shop that appears at configurable height intervals or when landing on shop platforms.
- Shop navigation uses the same input mappings as gameplay.
- Player movement is disabled while the shop is open.
- Shop only opens when the player is grounded on a non-moving platform.
- Upgrade prices are configurable and reflected dynamically in UI text.

Available upgrades:
- Jump height increase
- Double jump ability

---

### Difficulty Scaling
- Difficulty increases gradually as the player climbs higher.
- Platform spacing increases slowly over time.
- Moving and spiked platform spawn rates increase gradually.
- Scaling remains bounded so gameplay never becomes impossible.

---

### Hazard and Game Over System
- Touching spiked platform sides triggers immediate game over.
- Falling below the camera view triggers game over.
- Game over freezes player movement and gameplay.
- Game over screen displays final score (height reached).
- A reset input allows restarting the game cleanly.

---

### UI and Scoring
- Implemented a live height-based score counter.
- Coin counter updates immediately on collection.
- Shop UI includes selectable buttons navigated via input mapping.
- Game over UI displays final score and reset instructions.

---

### Background and Visual Systems
- Implemented an infinite parallax background.
- Background layers repeat seamlessly both horizontally and vertically.
- Multiple parallax layers add depth to the tower environment.
- Background is clamped to the playable area to prevent empty space.

---

## Refactoring and Cleanup
- Reorganized scripts into clear functional units.
- Removed duplicate logic from platform generation.
- Explicitly typed variables to satisfy Godot’s strict type checking.
- Added safeguards for null nodes and missing references.
- Improved naming consistency and code readability.

---

## Unfinished or Contemplated Features

The following features were considered but not fully implemented:
- Enemy entities (such as flying hazards)
- Persistent meta-progression between runs
- Additional shop upgrades (speed, shield, slow-fall)
- Animated character sprite system
- Audio and music systems
- Boss or challenge floors

These features were scoped out but deprioritized in favor of core gameplay stability.

---

## Summary

The project evolved from a simple prototype into a fully playable infinite platformer with:
- Procedural level generation
- Player-centric reachability guarantees
- Multiple platform types and hazards
- A functional upgrade economy
- A complete gameplay loop with scoring and game over states

The final result is a stable, extensible game architecture suitable for future expansion.
