# Flutter Codex Workspace

This repository includes a project instruction, memory, documentation, testing, and validation system for coding agents.

## Main files

- `AGENTS.md`: mandatory repository-wide agent rules
- `.agents/skills/`: installed Flutter skills
- `.codex/INDEX.md`: selective context-loading map
- `.codex/MEMORY.md`: stable project facts
- `.codex/PROJECT_STATE.md`: current work state
- `.codex/DECISIONS.md`: long-lived technical decisions
- `.codex/CHANGELOG_AI.md`: concise AI-assisted change history
- `docs/`: architecture and engineering policies
- `scripts/`: repeatable validation commands
- `test/` and `integration_test/`: testing structure

## Initial setup

1. Fill all `TODO` values that can be confirmed from the repository.
2. Do not invent architecture information.
3. Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap.ps1
```

4. Record pre-existing failures in `.codex/PROJECT_STATE.md`.

## Validate the project

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check.ps1
```

Optional flags:

```powershell
.\scripts\check.ps1 -RunCodegen
.\scripts\check.ps1 -RunIntegration
.\scripts\check.ps1 -SkipTests
```

## Start a Codex session

Use this prompt:

```text
Inspect this repository without modifying files.

1. Read AGENTS.md and .codex/INDEX.md.
2. Read only the minimum relevant memory files.
3. List installed Flutter skills by name and one-line purpose.
4. Inspect pubspec.yaml, analysis_options.yaml, architecture, source layout, and tests.
5. Fill no files yet.
6. Report confirmed project facts, unknown TODO fields, existing validation commands, and documentation conflicts.
```

## Daily task prompt

Copy `.codex/TASK_TEMPLATE.md`, select the relevant skills, and replace all TODO sections with concrete requirements.

## Important rules

- Do not force the agent to read every skill.
- Do not store temporary logs in memory files.
- Do not mark a task complete without validation evidence.
- Do not overwrite existing architecture with generic template assumptions.
