# Folder Conventions (Phase 1)

## Canonical Roots
- `Scripts/` for runtime GDScript grouped by feature domain.
- `Data/` for authored non-binary gameplay content (`.json`, selected `.tres`).
- `Scenes/` for scene assets, grouped by feature domain.
- `Resources/` for reusable Godot resources not treated as authored content.
- `Assets/` for media-only content (textures, audio, fonts, shaders).
- `Archive/phase1_candidates/` for suspicious/legacy files in archive-first flow.

## Script Domain Rules
- `Scripts/autoload/`: singleton scripts/scenes referenced by `project.godot`.
- `Scripts/dialog/`: dialog pipeline scripts and zone/hotspot runtime helpers.
- `Scripts/combat/`: combat flow and effect logic scripts.
- `Scripts/world/`: overworld systems (time/biome/audio/navigation helpers).
- `Scripts/ui/`: gameplay UI scripts.
- `Scripts/entities/enemies/<enemy_id>/`: enemy AI/action scripts.
- `Scripts/entities/player/`: player-specific scripts.

## Data Domain Rules
- `Data/dialog/`: narrative/dialog JSON by location/feature.
- `Data/encounters/`: encounter tables/entries treated as authored content.
- `Data/characters/`: character metadata/dialog-facing resources.

## Migration Constraints
1. No phase-1 hard deletes for suspicious files.
2. Every move must be logged in `move_map_phase1.json`.
3. Every suspicious candidate must be logged in `orphan_audit_phase1.json`.
4. Batch validation must pass before next batch.

## Mandatory Reference Rewrite Rule
When any file is moved, every reference to its old `res://` path must be updated in the same migration batch.

Required scan targets:
- `.tscn`
- `.tres`
- `.gd`
- `.json`
- `project.godot`
- migration manifests/reports under `Tools/migration/`

Completion gate:
- A migration batch is **not complete** until stale old-path references are verified as **zero** (`stale refs = 0`).
