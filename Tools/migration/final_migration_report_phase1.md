# Final Migration Report (Phase 1)

## What moved
- res://global/events.gd -> res://Scripts/autoload/events.gd (source_exists=False, target_exists=True)
- res://global/gamestate.gd -> res://Scripts/autoload/gamestate.gd (source_exists=False, target_exists=True)
- res://global/scene_manager.gd -> res://Scripts/autoload/scene_manager.gd (source_exists=False, target_exists=True)
- res://global/dialog_scene_selector.gd -> res://Scripts/autoload/dialog_scene_selector.gd (source_exists=False, target_exists=True)
- res://Code/DialogCode/dialog_scene_loader.gd -> res://Scripts/dialog/dialog_scene_loader.gd (source_exists=False, target_exists=True)
- res://Code/DialogCode/dialog_parser.gd -> res://Scripts/dialog/dialog_parser.gd (source_exists=False, target_exists=True)
- res://Code/DialogCode/dialog_logic_handler.gd -> res://Scripts/dialog/dialog_logic_handler.gd (source_exists=False, target_exists=True)
- res://Code/DialogCode/dialog_flow_manager.gd -> res://Scripts/dialog/dialog_flow_manager.gd (source_exists=False, target_exists=True)
- res://Code/DialogCode/dialog_command_executor.gd -> res://Scripts/dialog/dialog_command_executor.gd (source_exists=False, target_exists=True)
- res://Code/DialogCode/dialog_line_spawner.gd -> res://Scripts/dialog/dialog_line_spawner.gd (source_exists=False, target_exists=True)

## What was archived
- Archive location: `Archive/phase1_candidates/`
- Archived file count: 38
- Remaining suspicious files outside archive: 0
- Includes `desktop.ini`, `*.tmp`, `*Copy*`, `*_OLD*`, `*chatgptversion*` candidates approved during migration batches.

## What was left untouched
- Active non-suspicious project assets/scripts and existing gameplay resources were left in place.

## Validation summary
- Broken `res://` scan: broken_refs=0
- `project.godot` autoload paths validated against moved autoload scripts.
- Encounter/dialog/gamestate path constants were validated for file existence.
- Manual in-editor smoke result: core behavior appears unchanged (boot/flow works), with one known issue: overworld movement is still possible while GameUI is open.

## Remaining risks / manual follow-ups
- Follow-up bugfix recommended: gate/lock overworld movement input while GameUI is open.
- Godot CLI executable was not available in PATH in this environment, so runtime launch tests could not be executed here; smoke was validated manually in-editor by user.
