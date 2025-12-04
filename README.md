# Open-Source-Game-Project
Tower Climb — Wizard Frog Vertical Platformer

A procedural infinite tower-climbing game built in Godot 4.5.

Overview

Tower Climb is a vertical platformer featuring a small wizard frog attempting to ascend an endless tower. The level is fully procedurally generated, ensuring each run is unique. As the player climbs higher, platform patterns become more challenging, hazards increase, and upgrades become more valuable.

Your objective is to climb as high as possible, collect coins, and purchase upgrades to extend each run.

Core Features
Procedural Platform Generation

Platforms are always reachable based on the player’s current jump height and movement capabilities.

Horizontal movement limits ensure platforms remain within background boundaries.

Difficulty increases gradually as height increases.

Includes multiple platform types:

Small platforms

Big platforms

Bonus platforms

Moving platforms

Spiked hazard platforms

Shop platforms

Coin System

Coins spawn on platforms or in bonus clusters.

Coin collection updates the UI immediately.

Coins can be used in the shop to purchase upgrades.

Upgrade Shop

The shop appears at fixed height intervals (e.g., every 1000 units) or by landing on a shop platform.

Available upgrades:

Upgrade	Cost	Effect
Jump Upgrade	Configurable	Increases jump height
Double Jump	Configurable	Grants a second jump

Shop features:

Navigation uses left/right input.

Jump is used to select/purchase.

Jump is also used to close the shop.

Player movement is disabled while the shop is open.

The shop only opens when the player is standing on a stationary platform.

Hazards

Spiked Platforms:
Touching the spike sides causes immediate game over, freezing the player and displaying the game-over screen.

Game Over System

Game over is triggered by:

Falling below the camera view

Contact with spikes

The game-over screen:

Displays the final score (height reached)

Provides a reset option bound to an input action

Stops all gameplay until the player resets

Parallax Background

Infinite vertical scrolling background

Multiple parallax layers (brick texture, silhouettes, decorative elements)

Automatically aligns with camera movement and tower width

Controls
Action	Input Map
Move Left	move_left
Move Right	move_right
Jump	jump
Drop Down	move_down
Open/Close Shop	close_shop
Reset Run	reset_player
Technical Highlights

Developed in Godot Engine 4.5 using GDScript.

Uses CharacterBody2D, StaticBody2D, and Area2D for platforming logic.

Platform spawner includes:

Zig-zag generation with direction flipping probability

Collision and spacing checks

Reachability based on real-time player stats

Shop platform integration

Hazard avoidance for spiked platforms

Moving platforms properly carry the player using motion calculations.

Clean code structure:

PlayerController.gd

Main.gd

PlatformSpawner.gd

MovingPlatform.gd

SpikedPlatform.gd

ShopPlatform.gd

Coin.gd

Project Structure
assets/
 ├── sprites/
 │    ├── Platform.png
 │    ├── MovingPlatform.png
 │    ├── SpikedPlatform.png
 │    ├── ShopPlatform.png
 │    ├── WizardFrog.png
 │    └── coin.png
 ├── scenes/
 │    ├── Player.tscn
 │    ├── SmallPlatform.tscn
 │    ├── BigPlatform.tscn
 │    ├── MovingPlatform.tscn
 │    ├── SpikedPlatform.tscn
 │    ├── ShopPlatform.tscn
 │    └── Main.tscn
 └── scripts/
      ├── player_controller.gd
      ├── platform_spawner.gd
      ├── moving_platform.gd
      ├── spiked_platform.gd
      ├── shop_platform.gd
      ├── coin.gd
      └── main.gd

How to Run

Install Godot 4.5 or later

Clone or download the repository

Open the project folder in Godot

Run Main.tscn as the main scene