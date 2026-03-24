# GEMINI.md - Godot Project: Wrisst_test

## Project Overview

This project, "Wrisst_test," is a 2D narrative-heavy RPG developed with the Godot Engine (v4.4). The game features overworld exploration, random and static encounters, a turn-based combat system, and a complex, custom-built dialog system with visual novel-style presentation.

The game's content is aimed at an adult audience, with in-code references to mature themes such as "feral/beast erotic content," "violence," and relationship mechanics that track "horny" levels for NPCs. The codebase includes content filters that players can enable.

## Running the Project

1.  **Install Godot:** Download and install Godot Engine version 4.4 or compatible.
2.  **Import Project:**
    *   Open the Godot Project Manager.
    *   Click "Import" and browse to the root directory of this project.
    *   Select the `project.godot` file.
3.  **Run:**
    *   Once the project is imported, open it in the Godot editor.
    *   Press the "Play" button (or F5) to run the main scene (`overworldNav.tscn`).

## Architecture and Conventions

The project follows a singleton-heavy architecture, with many core systems implemented as autoloaded nodes. This makes them globally accessible and persistent across scenes.

*   **Game State:** The `GameState` singleton (`Scripts/autoload/gamestate.gd`) is the central hub for all game data. It manages player stats, inventory, currency, quest/event flags, and NPC relationship data.
*   **Scene Management:** The `SceneManager` (`Scripts/autoload/scene_manager.gd`) and `EncounterManager` (`Code/encounter_manager.gd`) work together to handle transitions between the overworld, combat, and dialog scenes. Combat is typically initiated as an overlay on the current scene.
*   **Dialog System:** The game uses a sophisticated, custom-built dialog engine managed by `DialogManager` (`global/dialog_manager.gd`). It parses JSON files for dialog content and uses a modular structure (`DialogFlowManager`, `DialogCommandExecutor`, etc.) to control the flow, display character portraits, and execute commands from dialog.
*   **Events:** A global `Events` singleton (`Scripts/autoload/events.gd`) is used for signal-based communication between different parts of the game, decoupling the major systems.
*   **Resources:** The project makes extensive use of Godot's custom `Resource` system for defining data, such as character stats (`character_stats.gd`), items, and encounter tables (`encounter_table.gd`).

## Key Files and Directories

*   `project.godot`: The main project configuration file. Defines autoloads, display settings, and input maps.
*   `overworldNav.tscn`: The main scene and starting point of the game.
*   `Scripts/autoload/`: Contains the globally accessible singleton scripts.
    *   `gamestate.gd`: The single source of truth for the game's state.
    *   `scene_manager.gd`: Manages scene transitions, especially for combat.
    *   `events.gd`: Global event bus for decoupled communication.
*   `Code/`: Contains core game logic.
    *   `encounter_manager.gd`: Manages logic for random and static encounters based on biome, time, and game flags.
*   `global/dialog_manager.gd`: The core of the custom visual novel-style dialog system.
*   `Data/dialog/`: Contains the JSON files that define the game's dialog.
*   `Resources/`: Contains custom `Resource` files for items, enemies, encounters, etc.
*   `Characters/`: Character-specific resources and scripts.
*   `Scenes/`: Contains the main game scenes, including `combat.tscn`.
*   `addons/dialogic/`: Contains the Dialogic plugin, though its direct usage seems to be for its underlying data structures rather than the UI.

This `GEMINI.md` should provide a solid foundation for understanding the project's structure, conventions, and core mechanics for any future development tasks.

## Narrative & Content Generation

This project has extensive documentation for its narrative, world-building, and writing style. Adherence to these guidelines is critical when generating any content (dialogue, quests, lore).

### Core Principles

*   **Tone:** The narrative is direct, explicit, and physical. It is written in the **second person, present tense**. The focus is on action and sensation over internal monologue.
*   **Themes:** The game is an adult RPG with a focus on teratophilia. Encounters with 'Feral Creatures' are often erotic in nature and form a core gameplay loop. Sex with creatures is a social taboo among the sapient 'Monsterfolk'.
*   **World:** The setting is a low-fantasy frontier world called Wrisst. The player is the only human.

### Key Reference Documents

Before generating content, consult the following documents. They are the canonical source of truth.

*   **Primary Bible:** `X ReadMe for LLMs/(ReadMe for LLMs) Wrisst Knowledge Database & Design plan 05-03-2026.txt`
    *   Contains the detailed design plan, writing style guides, world lore, currency system, and character/creature meta notes.
*   **Story & Quest Structure:** `X ReadMe for LLMs/Wrisst_Story_Planning_Document_Klyftet_Arc - Gemini Rework.txt`
    *   Provides the main questline, side quest architecture, and overall narrative arc for the Klyftet region.
*   **AI Context Guide:** `CLAUDE.md`
    *   Acts as a master index, pointing to specific character sheets, species guides, and bestiary entries located in `X ReadMe for LLMs/CharacterSheets/`.

### Writing Rules & Conventions

*   The `.clinerules` directory contains specific, machine-loadable rules for writing style.
    *   `.clinerules/lore-style.md`: Covers voice, tone, explicitness, and the feral encounter structure.
    *   `.clinerules/scene-writing-monsterfolk.md`: Defines rules for node cadence, choice design, and JSON structure for dialogue scenes.
*   When writing for a specific character, creature, or location, always find and read its corresponding `.md` sheet in the `X ReadMe for LLMs/` subdirectories first.
