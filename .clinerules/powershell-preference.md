## Brief overview
- Project rule for command-line editing and automation in this workspace.
- Prefer PowerShell-based commands and edits when possible.
- Avoid Python commands unless the user explicitly asks for Python or PowerShell is not a practical option.

## Command preferences
- Prefer PowerShell for file edits, search-and-replace tasks, and batch command-line operations on this machine.
- Avoid using Python one-liners or Python scripts for routine workspace edits when a PowerShell solution is reasonable.
- If both approaches are viable, choose PowerShell first.

## Exceptions
- Use Python only when the user explicitly requests it.
- Use Python only when PowerShell would be substantially less reliable, much more complex, or clearly unsuitable for the task.
- If Python is truly necessary, briefly say why before using it.

## Workflow guidance
- When planning command-line edits, consider a PowerShell command before reaching for Python.
- Keep PowerShell commands as simple and non-interactive as possible.
- For bulk file edits, prefer targeted replacements and then verify the result afterward.