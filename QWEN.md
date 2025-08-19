# Going Nuclear - Project Context for Qwen Code

## Project Overview

This directory contains the source code for "Going Nuclear", a turn-based strategy game implemented using the Godot Engine (version 4.4). The game is centered around geopolitical strategy, resource management, and nuclear warfare, where the player controls a nation and competes against AI-controlled factions.

The core gameplay loop involves managing your nation's Treasury, Morale, and Action Points (AP) to build capabilities (via Investments), draw cards, and execute attacks (either conventional nuclear strikes or InfoWar) against rival nations. The game features a distinctive 3D console-style UI where players interact with physical buttons to make choices.

Key technologies and architecture:
- **Engine:** Godot 4.4
- **Language:** GDScript
- **Architecture:** Centralized manager pattern with event-driven communication.
- **Core Managers:**
  - `GameManager`: The central authority for game state, turn progression, player management, and core game logic.
  - `CardDatabase`: Loads and provides access to all card data.
  - `FactionDatabase`: Loads and provides access to all faction data.
  - `EventBus`: Facilitates decoupled communication, primarily for UI interactions.
  - `Logger`: Centralized logging utility.
  - `WinConditionManager`: (Autoloaded, details not provided in snippets) Likely handles game end conditions.
  - `FeedbackManager`: (Autoloaded, details not provided in snippets) Possibly handles visual/audio feedback.
- **Data-Driven Design:** Game entities like Factions and Cards are defined as custom Resources (`FactionData`, `CardData`) which can be configured in the Godot editor. Preset data for these resources is hardcoded within their respective scripts.
- **UI:** A complex 3D scene (`Console3D`) acts as the main game interface. UI elements like labels and a `DeploymentScreen` (a 2D scene within a SubViewport) are used for displaying information and making choices. Physical interactions in the 3D scene are handled by `PhysicalButton3D` nodes.

## Key Source Files

- `project.godot`: The main Godot project configuration file. Defines autoloaded managers and core settings like window size.
- `main_controller.gd`: The main scene's script. It orchestrates the UI, listens to `GameManager` and `EventBus` signals, handles 3D button interactions, and updates various UI elements.
- `scripts/managers/GameManager.gd`: The core game logic manager. Handles game state, player turns, card management, action processing (builds, attacks), and AI turn execution.
- `scripts/managers/CardDatabase.gd`: Loads and manages all `CardData` resources.
- `scripts/managers/FactionDatabase.gd`: (Referenced in `project.godot` and `GameManager`, but content not provided) Presumably loads and manages `FactionData` resources.
- `scripts/data/card_data.gd`: Defines the `CardData` resource class and a large dictionary of preset card data. Includes enums for card types and presets.
- `scripts/data/faction_data.gd`: Defines the `FactionData` resource class and a dictionary of preset faction data. Includes enums for faction presets and AI personality traits.
- `scripts/data/PlayerState.gd`: Defines the `PlayerState` class, holding the dynamic state (population, treasury, hand, etc.) for a player (human or AI) during a match.
- `scripts/ai/AIController.gd`: Contains the static logic for how AI players make decisions during their turns.
- `scripts/ui/DeploymentScreen.gd`: (Content not provided, but interaction is shown in `main_controller.gd`) Manages the 2D UI screen used for selecting investments and cards.

## Building and Running

- **Engine:** Requires Godot Engine 4.4 or compatible version.
- **Opening:** Open the project folder in Godot Editor.
- **Running:** Use the standard Godot "Play" button within the editor to run the main scene (`Main.tscn`).

## Development Conventions

- **Manager Pattern:** Centralized nodes (`GameManager`, `CardDatabase`, etc.) are autoloaded and accessed globally (e.g., `GameManager.start_new_game()`).
- **Event-Driven UI:** UI updates and reactions are often handled via signals emitted by managers (e.g., `GameManager.game_state_changed`, `GameManager.turn_started`) or the `EventBus`.
- **Resource-Based Data:** Game data for cards and factions is stored in custom `Resource` files (`.tres`), which are instances of `CardData.gd` and `FactionData.gd` scripts. These scripts contain the logic and preset data.
- **3D Interaction:** 3D object interactions are managed by specific nodes like `PhysicalButton3D`, which communicate with higher-level controllers via signals.
- **Logging:** The `Logger` autoload is used for outputting game events and debug information, typically to a label within the `Console3D` scene.

## Directory Structure

- `scripts/`: Contains all GDScript source files.
  - `scripts/managers/`: Core game managers (`GameManager.gd`, `CardDatabase.gd`, etc.).
  - `scripts/data/`: Resource definitions and preset data (`card_data.gd`, `faction_data.gd`, `PlayerState.gd`).
  - `scripts/ai/`: AI logic (`AIController.gd`).
  - `scripts/ui/`: UI component scripts (`DeploymentScreen.gd`).
  - `scripts/3d/`: Scripts related to 3D scene objects (e.g., `PhysicalButton3D`).
- `data/cards/`: (Inferred from `CardDatabase.gd`) Directory containing `.tres` files for individual cards.
- `data/factions/`: (Inferred from `FactionDatabase.gd` usage) Directory containing `.tres` files for individual factions.
- `scenes/`: Contains Godot scene files (`.tscn`).
- `addons/`: Contains Godot editor plugins.