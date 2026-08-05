# Codex Project Index

This file controls selective loading of project context.

## Always read

- `../AGENTS.md`
- `MEMORY.md`

## Feature implementation

Read:

- `PROJECT_STATE.md`
- `../docs/architecture.md`
- `../docs/conventions.md`
- Relevant feature source files
- Relevant feature tests
- The selected Flutter feature skill
- `../docs/testing.md` when behavior changes

## Bug fixing

Read:

- `PROJECT_STATE.md`
- Relevant source and test files
- The selected debugging skill
- `../docs/testing.md`

Do not read unrelated feature directories.

## Architecture changes

Read:

- `DECISIONS.md`
- `../docs/architecture.md`
- `../docs/decisions/README.md`
- Relevant dependency and package documentation

Architecture changes require an explicit decision record.

## State-management changes

Read:

- `../docs/state-management.md`
- Existing state-management implementation in the same feature
- Relevant state tests

## Navigation changes

Read:

- `../docs/navigation.md`
- Existing router configuration
- Relevant navigation tests

## Networking changes

Read:

- `../docs/networking.md`
- `../docs/security.md`
- Relevant API client, data source, repository, model, and error-mapping files

## Testing tasks

Read:

- `../docs/testing.md`
- Relevant test helpers and fixtures
- The selected Flutter testing skill

## Performance tasks

Read:

- `../docs/performance.md`
- The specific affected widget, rendering, data, or startup paths

## Localization tasks

Read:

- `../docs/localization.md`
- Existing localization configuration and generated access patterns

## Release and native tasks

Read:

- `../docs/release.md`
- Relevant files under `android/`, `ios/`, `macos/`, `windows/`, `linux/`, or `web/`
- The selected native or release skill

## Memory update policy

- Update `PROJECT_STATE.md` after meaningful task completion.
- Update `DECISIONS.md` only for long-lived technical decisions.
- Update `MEMORY.md` only when stable project facts change.
- Append a concise entry to `CHANGELOG_AI.md` after completed code changes.
- Never store full logs, copied source code, secrets, temporary reasoning, or speculative conclusions.
