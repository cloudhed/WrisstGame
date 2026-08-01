# Implementation Plan

[Overview]
Reorganize the Godot project into a feature-first, predictable structure that keeps behavior stable while making files faster to find and safer to maintain.

This implementation introduces a staged “spring cleaning” migration that prioritizes **discoverability**, **reference safety**, and **future growth**. The current project mixes feature domains (`Code/`, `global/`, `Scenes/`, `Narrative/`, `Resources/`, `enemies/`, `Characters/`) and includes legacy/temporary artifacts (`*.tmp`, `*_OLD`, `* - Copy*`, `*chatgptversion*`, misplaced root scripts). The target architecture will group content by gameplay feature while preserving Godot references through compatibility wrappers and batched path updates.

The migration will follow a balanced strategy (per user preference): move files into a cleaner structure, keep compatibility where needed, and avoid hard deletion during early phases. The plan includes a formal audit of suspicious and likely-unused files, migration manifests, naming conventions, and incremental validation so that scene loading, autoloads, and resource links are not broken.

[Types]
Add planning and migration metadata types to support deterministic, auditable restructuring with rollback safety.

Define the following metadata structures as JSON/TXT docs under `Tools/migration/`:

1. `FolderConventionRule`
   - `domain: String` (e.g., `combat`, `dialog`, `world`, `ui`, `entities`)
   - `allowed_roots: Array[String]` (e.g., `Scenes/`, `Scripts/`, `Data/`, `Assets/`)
   - `file_patterns: Array[String]` (extensions or naming regexes)
   - `naming_rule: String` (`snake_case`, `PascalCase` for classes/resources where required)
   - `notes: String`

2. `MoveMapEntry`
   - `source_path: String` (full `res://` path)
   - `target_path: String` (full `res://` path)
   - `asset_type: String` (`script`, `scene`, `resource`, `json`, `texture`, `audio`, `tooling`)
   - `requires_reference_rewrite: bool`
   - `status: String` (`planned`, `moved`, `validated`, `rolled_back`)

3. `OrphanAuditEntry`
   - `path: String`
   - `reason: String` (`tmp_file`, `duplicate_copy`, `legacy_old`, `unreferenced_candidate`, `experimental`)
   - `detected_by: String` (`pattern_scan`, `reference_scan`, `manual_review`)
   - `decision: String` (`keep`, `archive`, `delete_later`)
   - `decision_notes: String`

4. `ReferenceValidationReport`
   - `timestamp: String`
   - `checked_files: int`
   - `broken_res_paths: Array[String]`
   - `broken_uid_paths: Array[String]`
   - `autoload_validation: Dictionary`
   - `scene_load_validation: Dictionary`

Validation rules:
- All `target_path` values must be unique.
- `source_path` must exist before migration.
- `decision` for orphan files must be explicit before deletion.
- No direct delete operation is allowed in phase 1 without being listed in orphan audit.
- Every moved file with `requires_reference_rewrite = true` must have all old-path references rewritten in the same batch.

[Files]
Reorganize scripts, scenes, data, and assets into feature-focused roots with staged migration maps and compatibility safeguards.

Naming conventions to enforce during migration:
- Folders: `snake_case` (exception: existing enemy-pack IDs like `teqqellon`, `murisk_n`, `meehp_f` are already acceptable and should be preserved).
- GDScript files: `snake_case.gd` matching responsibility (`dialog_scene_loader.gd`, `encounter_manager.gd`).
- Scene files: `PascalCase.tscn` for reusable scene assets OR strict `snake_case.tscn` if project chooses one style; do not mix both in same feature folder.
- Resource files: domain-driven, lowercase snake_case (`default_overworld_encounter_table.tres`, `teqqellon_enemy.tres`).
- JSON dialogue files: `<context>_<phase>.json` (e.g., `teqqellon_dialog_precombat.json`, `oldtree_day.json`).
- Temporary/backup suffixes such as ` - Copy`, `_OLD`, `_old`, `chatgptversion`, and numeric `.tmp` are forbidden in production paths.

New files to create:
- `implementation_plan.md` (this document)
- `Tools/migration/folder_conventions.md` (final structure standards)
- `Tools/migration/move_map_phase1.json` (source→target moves)
- `Tools/migration/orphan_audit_phase1.json` (suspicious/unused candidates)
- `Tools/migration/reference_validation_report_template.json` (validation schema)
- `Tools/migration/naming_conventions.md` (project naming guide)

New top-level folders to introduce (phase 1):
- `Scripts/` (runtime GDScript by domain)
  - `Scripts/autoload/` (from `global/` and root singleton scripts)
  - `Scripts/combat/` (from `Code/CombatCode/`, `Effects/` scripts that are combat logic)
  - `Scripts/dialog/` (from `Code/DialogCode/`, `Code/Scripts/hotspot.gd`, `Code/Scripts/zone_scene.gd`)
  - `Scripts/world/` (from `Code/` world systems: time, biome, audio, player map movement)
  - `Scripts/ui/` (from `Scenes/UI/*.gd`, `Code/CombatCode/combat_ui.gd` split by ownership)
  - `Scripts/entities/`
    - `Scripts/entities/enemies/<enemy_id>/` (enemy actions and AI scripts)
    - `Scripts/entities/player/`
    - `Scripts/entities/npc/`
- `Data/` (non-binary authored content)
  - `Data/dialog/` (from `Dialog/`, narrative JSONs currently split across folders)
  - `Data/encounters/` (from `Resources/Encounters/` tables/entries where treated as authored data)
  - `Data/characters/` (character metadata and dialogue entry resources)

Existing folders to normalize (not all moved in phase 1):
- Keep `Scenes/`, but enforce feature subfolders and remove loose/legacy scene clutter.
- Keep `Resources/`, but split by domain instead of mixed content naming.
- Keep `Assets/` for pure media only (textures/audio/fonts/shaders) and remove script leakage.

Existing files to modify:
- `project.godot`
  - Update `[autoload]` paths if autoload scripts/scenes move.
  - Keep autoload names stable (`GameState`, `SceneManager`, etc.) to avoid callsite changes.
- `global/scene_manager.gd`
  - Update hardcoded scene paths (`COMBAT_SCENE_PATH` fallback comments and constants) to new canonical locations if changed.
- `Code/encounter_manager.gd`
  - Update constants `OVERWORLD_SCENE_PATH`, `COMBAT_SCENE_PATH`, `DEFAULT_ENEMY_PATH`, `DEFAULT_ENCOUNTER_TABLE_PATH` after migration.
- `global/dialog_scene_selector.gd`
  - Update all location `.tres` constants once narrative data paths are normalized.
- `global/gamestate.gd`
  - Update fallback equipment paths and debug item resource paths if these move.
- `Code/DialogCode/dialog_scene_loader.gd` and related dialog files
  - Update any `res://` resource path assumptions.
- Any `.tscn` and `.tres` containing `[ext_resource path="res://..."]` to rewritten canonical paths.

Files/folders to archive (not delete in phase 1):
- Create `Archive/phase1_candidates/` and move reviewed legacy artifacts:
  - `Scenes/UI/narration_box_OLD.tscn`
  - `Scenes/UI/speech_bubble_OLD.tscn`
  - Files matching `* - Copy*`, `*_old*`, `*chatgptversion*`, `*.tmp`, `desktop.ini`
  - Duplicated/experimental dialog variants (after manual content check)

Explicit suspicious file candidates found during investigation (phase-1 audit seed):
- `Scenes/UI/narration_box_OLD.tscn`
- `Scenes/UI/speech_bubble_OLD.tscn`
- `Characters/Bitalgut/dialogue/bitalgut_intro_old.json`
- `Dialog/Klyftet/klyftet_ext_day_copy.json`
- `enemies/meehp_f/meehp_f_dialog_postcombat - chatgptversion.json`
- `enemies/murisk_n/murisk_dialog_postcombat - chatgptversion.json`
- `enemies/teqqellon/teqqellon_dialog_postcombat - Copy.json`
- `Characters/Bitalgut/bitalgut_intro.tscn1580430902.tmp`
- `Narrative/DialogScene.tscn20716500190.tmp`
- `Scenes/combat.tscn*.tmp` (multiple temp snapshots)
- `Scenes/TileUI/tile_ui.tscn*.tmp` (multiple temp snapshots)
- `overworldNav.tscn*.tmp` (multiple temp snapshots)
- `Narrative/SlideDecks/desktop.ini`
- `Assets/desktop.ini`
- `Assets/Sprites/Characters/minttärä_counter - Copy.png`
- `Assets/Sprites/Characters/minttärä_portrait_base - Copy.png`
- `enemies/meehp_f/meehp_f_base - Copy.png`

Reference-risk note for these candidates:
- Any candidate is only archived/deleted after confirming no active `res://` references in `.gd/.tscn/.tres` and no narrative pipeline dependency.

Configuration updates:
- `.gitignore`: add robust ignores for Godot temp artifacts and editor leftovers if missing.
- Optional `.editorconfig` additions for naming/style hints and line endings consistency.

[Functions]
Primary function changes will be path-reference and loader stabilization functions to make moved content non-breaking.

New functions (planned):
- `Scripts/autoload/path_registry.gd` (optional phase-2 utility)
  - `func resolve_scene(key: String) -> String`
  - `func resolve_resource(key: String) -> String`
  - Purpose: centralize critical paths so folder changes touch one place.

- `Tools/migration/reference_checker.gd` (editor/tool script, optional)
  - `func scan_res_paths(root: String) -> Array[String]`
  - `func find_broken_references(paths: Array[String]) -> Array[String]`
  - Purpose: post-move validation automation.

Modified functions:
- `global/scene_manager.gd`
  - `_get_combat_scene()`: load from new canonical path if moved.
  - `return_to_previous_scene()`: update fallback scene path.

- `Code/encounter_manager.gd`
  - `_get_combat_scene()`, `_get_overworld_scene()`, `_ensure_default_encounter_content()` path constant updates.

- `global/dialog_scene_selector.gd`
  - `_get_*_scene()` methods keep behavior, but constants updated to new data locations.

- `global/gamestate.gd`
  - `_ready()`, `_ensure_fallback_items_loaded()`, `check_and_equip_fallback()` path constants and debug item references.

Removed functions:
- None required in phase 1.
- Any removals happen only after reference-check and usage audit in later cleanup phases.

[Classes]
Class behavior remains mostly intact; changes focus on ownership/location and optional helper classes for path governance.

New classes (optional but recommended):
- `PathRegistry` (`Scripts/autoload/path_registry.gd`)
  - Key methods: `resolve_scene`, `resolve_resource`, `has_key`
  - Inheritance: `extends Node` (autoload optional)

- `MigrationReferenceChecker` (`Tools/migration/reference_checker.gd`)
  - Key methods: scanning and report generation
  - Inheritance: `extends Node` or `EditorScript`

Modified classes (location/path update only):
- `DialogManager` (`global/dialog_manager.gd`)
- `DialogSceneLoader` (`Code/DialogCode/dialog_scene_loader.gd`)
- `DialogSceneSelector` (`global/dialog_scene_selector.gd`)
- `Combat` (`Scenes/Combat/combat.gd`)
- `EncounterManager` (`Code/encounter_manager.gd`)
- `GameState` (`global/gamestate.gd`)
- Enemy action classes under `enemies/*/*.gd`

Removed classes:
- None in phase 1.

[Dependencies]
No external package dependencies are required; this is an internal project-structure and reference-management migration.

Dependency changes:
- Keep Godot 4.4 project setup unchanged.
- Keep existing addons unchanged (`godot-git-plugin` and configured dialog/ink related settings).
- No NPM/PIP/Cargo/Go dependency additions.

[Testing]
Validation is performed via reference integrity checks, scene load checks, and gameplay smoke tests for high-risk systems.

Test requirements:
1. Static reference checks:
   - Scan `.tscn`, `.tres`, `.gd`, `.json` for stale `res://` paths.
   - Ensure no missing `[ext_resource]` links after each migration batch.
   - Mandatory rewrite scope for every moved file: `.tscn`, `.tres`, `.gd`, `.json`, `project.godot`, and migration manifests/reports under `Tools/migration/`.
   - Batch completion gate: stale references to moved old paths must be exactly zero (`stale refs = 0`) before the next batch.

2. Boot/autoload checks:
   - Project starts without autoload errors.
   - `GameState`, `SceneManager`, `DialogSceneSelector`, `PileManager`, `GameUI`, `MusicPlayer`, `SFXPlayer`, `AmbiencePlayer` initialize correctly.

3. System smoke tests:
   - Overworld scene loads (`overworldNav.tscn`/new canonical path).
   - Encounter trigger to combat transition works.
   - Combat pre/post dialog for enemy packs (`teqqellon`, `murisk_n`, `meehp_f`) still works.
   - Dialog location switching (`klyftet`, `hotbaths`, `inn`, `oldmine`) still resolves.

4. Data integrity checks:
   - Fallback items load in `GameState`.
   - Encounter tables/entries still resolve to enemy resources.
   - Character portrait decks still resolve textures/resources.

5. Orphan candidate review process:
   - Every orphan candidate tagged as `keep`, `archive`, or `delete_later`.
   - No hard deletion in phase 1.

6. Fast path-break detection checklist (must pass after each migration batch):
   - `project.godot` autoload entries resolve.
   - `SceneManager` combat path constant resolves.
   - `EncounterManager` default enemy/table paths resolve.
   - `DialogSceneSelector` location scene `.tres` paths resolve.
   - `GameState` fallback equipment + debug item paths resolve.

[Implementation Order]
Implement in small, validated batches: define conventions, map moves, migrate one domain at a time, and run reference checks between each batch.

1. Create migration docs (`folder_conventions`, `naming_conventions`, `move_map_phase1`, `orphan_audit_phase1`).
2. Freeze naming rules and canonical folder tree.
3. Migrate autoload-related scripts first (lowest count, highest risk) and update `project.godot`.
4. Migrate dialog domain (`Code/DialogCode`, `Dialog`, narrative data paths) with selector/loader updates.
5. Migrate combat/enemy domain to feature-owned script folders while preserving enemy pack grouping style (`enemies/teqqellon` pattern as template).
6. Normalize `Resources/Items`, `Resources/Tiles`, and encounter data locations; update hardcoded paths/constants.
7. Clean scene organization (`Scenes/`) and move clear legacy scene duplicates to archive.
8. Run full reference validation and boot/smoke test pass.
9. Archive approved suspicious files (`*.tmp`, `*_OLD`, `* - Copy*`, duplicates) into `Archive/phase1_candidates/`.
10. Produce final migration report and rollback map snapshot.
11. Enforce migration gate for every subsequent batch: no batch may be considered complete until all references to moved old paths are updated and verified as `stale refs = 0`.
