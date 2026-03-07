# Naming Conventions (Phase 1)

## General
- Folders: `snake_case`.
- Godot scripts: `snake_case.gd` matching responsibility.
- Resource files (`.tres`): lowercase `snake_case` domain names.
- Dialogue JSON: `<context>_<phase>.json`.

## Scene Naming
- Existing project contains mixed scene naming. During phase 1, preserve behavior over renaming.
- New scene files should follow one style per folder (prefer existing local style to avoid churn).

## Forbidden Production Suffixes
Do not keep these in active runtime locations:
- `*_OLD*`, `*_old*`
- `* - Copy*`, `*copy*` duplicates
- `*chatgptversion*`
- `*.tmp`
- `desktop.ini`

These are archived first, never mass-deleted in phase 1.
