# AGENTS.md

## Purpose

This file defines the mandatory working rules for coding agents operating in this Flutter repository.
These instructions apply to the entire repository unless a more specific `AGENTS.md` exists in a subdirectory.

The goal is to produce small, correct, testable, maintainable changes while preserving the existing architecture and minimizing unnecessary context usage.

## Instruction priority

Apply instructions in this order:

1. Explicit user requirements for the current task.
2. The nearest applicable `AGENTS.md` file.
3. This root `AGENTS.md`.
4. Relevant selected agent skills.
5. Existing project conventions and implementation patterns.
6. General Flutter and Dart best practices.

When instructions conflict, follow the higher-priority instruction and report the conflict in the final response.

## Required startup workflow

Before editing code:

1. Read this file.
2. Read `.codex/INDEX.md`.
3. Read only the memory and documentation files relevant to the task.
4. Inspect `pubspec.yaml` and `analysis_options.yaml` when the task may be affected by dependencies, code generation, linting, SDK constraints, or project configuration.
5. Inspect the relevant source files and their tests.
6. Search for an existing implementation pattern before creating a new abstraction.
7. Select only the skills relevant to the task.
8. Read the complete `SKILL.md` only for selected skills.

Do not scan the entire repository unless targeted inspection is insufficient.
Do not read all skills or all documentation by default.

## Agent skills

Flutter skills are installed under `.agents/skills/`.

For each task:

1. Discover available skill names and descriptions.
2. Select the smallest relevant set of skills.
3. Read the complete `SKILL.md` for selected skills only.
4. Follow their workflow, checks, and constraints.
5. Do not invoke unrelated skills.

A skill does not override project-specific architecture or explicit user requirements.

## Project source of truth

Use these documents as the project knowledge system:

- Stable project facts: `.codex/MEMORY.md`
- Current work state: `.codex/PROJECT_STATE.md`
- Technical decisions: `.codex/DECISIONS.md`
- AI change history: `.codex/CHANGELOG_AI.md`
- Architecture: `docs/architecture.md`
- Coding conventions: `docs/conventions.md`
- Testing strategy: `docs/testing.md`
- State management: `docs/state-management.md`
- Navigation: `docs/navigation.md`
- Networking: `docs/networking.md`
- Security: `docs/security.md`
- Performance: `docs/performance.md`
- Localization: `docs/localization.md`
- Release process: `docs/release.md`

When documentation conflicts with code, do not silently choose one. Identify the conflict, determine the most reliable source from repository evidence, and report it.

## Core working rules

- Make the smallest complete change that solves the task.
- Preserve existing behavior unless the task explicitly changes it.
- Do not modify unrelated files.
- Do not perform broad refactors during a focused feature or bug-fix task.
- Reuse established patterns before introducing new abstractions.
- Do not add, remove, or upgrade dependencies unless necessary.
- Do not guess package APIs. Inspect the installed version, existing project usage, generated API documentation, or package source.
- Do not manually edit generated files.
- Do not suppress analyzer warnings without a documented reason.
- Do not weaken or delete tests merely to make them pass.
- Do not expose credentials, API keys, signing files, access tokens, secrets, or private environment values.
- Do not claim completion without validation evidence.

## Context efficiency

- Start from the requested feature, error, or file.
- Follow imports and references only as needed.
- Prefer targeted search over broad directory traversal.
- Do not repeatedly reopen unchanged files.
- Summarize large files rather than copying them into notes.
- Do not include full command output when only a concise error is relevant.
- Prefer patches over rewriting complete files.
- Do not load old changelog entries unless they are relevant.
- Do not store temporary reasoning or full logs in memory files.

## Flutter and Dart rules

- Follow the Dart analyzer and project lint configuration.
- Prefer immutable data and widgets.
- Use `const` when valid and useful.
- Keep widget `build` methods declarative and free of side effects.
- Do not start network, storage, navigation, analytics, or state mutation directly from `build`.
- Check `mounted` before using `BuildContext` after asynchronous gaps.
- Dispose controllers, focus nodes, animation controllers, streams, and subscriptions owned by the object.
- Avoid unsafe casts, unnecessary null assertions, and dynamic values.
- Model expected failures explicitly rather than swallowing exceptions.
- Preserve null safety.
- Keep public APIs documented when their intent is not obvious.
- Prefer composition over deep inheritance.
- Extract widgets by responsibility and reuse, not only by line count.
- Avoid premature optimization while preventing obvious unnecessary rebuilds.

## Architecture rules

Follow `docs/architecture.md` and existing code.

Unless documented otherwise:

- UI code must not directly depend on concrete networking or persistence implementations.
- Domain and business logic must remain independent of Flutter UI classes.
- Infrastructure concerns must be behind interfaces or established service boundaries.
- State management must follow the existing project approach.
- Features must not bypass repositories, use cases, controllers, blocs, notifiers, or services already used by the project.
- Cross-feature dependencies should be explicit and minimal.

Do not introduce a new architectural pattern without explicit need and a decision record.

## Generated code

Never manually edit generated files, including common patterns such as:

- `*.g.dart`
- `*.freezed.dart`
- generated localization files
- generated route files
- generated mocks

When annotated sources change and generation is configured, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Review generated diffs before completion.

## Feature workflow

For feature tasks:

1. Confirm expected behavior and acceptance criteria.
2. Inspect the closest existing equivalent feature.
3. Identify impacted layers and tests.
4. Implement the smallest complete vertical slice.
5. Cover loading, empty, success, validation, and failure states where applicable.
6. Preserve accessibility and localization.
7. Add or update tests.
8. Run targeted validation, then broader validation.

## Bug-fix workflow

For bug fixes:

1. Reproduce or trace the failure from available evidence.
2. Identify the root cause before changing code.
3. Inspect related code paths and recent patterns.
4. Make the smallest safe correction.
5. Add a regression test when practical.
6. Check only closely related locations for the same defect pattern.
7. Run the failing test first, then relevant broader checks.

Do not hide failures with broad exception handling, arbitrary delays, analyzer suppression, unsafe casts, or force unwraps.

## Testing requirements

Follow `docs/testing.md`.

- Add or update tests for behavior changes.
- Prefer unit tests for pure business logic.
- Use widget tests for UI behavior, rendering, validation, and interaction.
- Use integration tests for critical cross-layer flows.
- Tests must be deterministic and isolated.
- Avoid real network calls, production services, and arbitrary time delays.
- A fixed bug should have a regression test when feasible.
- Test names must describe behavior and expected outcome.

## Validation workflow

Run the narrowest relevant check first.

Default required checks:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

When integration tests are relevant and a configured device is available:

```bash
flutter test integration_test
```

When code generation is affected:

```bash
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code
```

If the repository provides scripts, prefer:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check.ps1
```

If a required command cannot run, report:

- Exact command
- Reason it could not run
- What remains unverified
- Recommended next command

## Documentation updates

Update documentation only when the change affects documented behavior, architecture, conventions, setup, testing, security, or release processes.

Update memory files using these rules:

- `.codex/MEMORY.md`: only stable facts expected to remain useful across many future tasks.
- `.codex/PROJECT_STATE.md`: meaningful current status, blockers, and next work.
- `.codex/DECISIONS.md`: long-lived technical or architectural decisions.
- `.codex/CHANGELOG_AI.md`: concise summary of completed agent-assisted changes.

Never store secrets, full source files, long logs, temporary hypotheses, or private reasoning in memory files.

## Definition of done

A task is complete only when:

- Requested behavior is implemented.
- Existing architecture and conventions are preserved.
- Relevant tests are added or updated.
- Changed Dart code is formatted.
- Static analysis passes or unrelated pre-existing failures are clearly identified.
- Relevant tests pass or environmental limitations are clearly reported.
- Generated files are current when applicable.
- No unrelated changes or secrets appear in the diff.
- Relevant documentation and project state are updated.

## Required final response

Use this structure:

### Implemented

Concise description of completed behavior.

### Changed files

List each changed file and its purpose.

### Validation

List every command run and its result.

### Remaining risks

## Sibling backend access

The backend application is located at `e-learning-server`.

The backend is read-only reference material unless a task explicitly authorizes
backend changes.

When implementing or modifying API-connected Flutter behavior:

1. Inspect the relevant backend route, controller, validation schema, model,
   authentication middleware, and error handler.
2. Derive request and response models only from confirmed backend evidence.
3. Record the backend source path for important API assumptions.
4. Do not infer a contract from route names alone.
5. Never expose values from backend secret or environment files.
6. Do not copy backend-only validation, database, or framework concerns into
   Flutter unless they are part of the public API contract.
7. If the backend implementation and mobile documentation conflict, stop and
   report the conflict before expanding it.
8. Modify only the Flutter project unless backend changes are explicitly
   requested.

Do not scan the entire backend by default. Begin with route registration and
follow only the imports needed for the current mobile feature.

List only real unresolved risks. Write `None` when there are none.
