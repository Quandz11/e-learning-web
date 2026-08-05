param(
    [string]$ProjectRoot = (Get-Location).Path,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
Set-Location $ProjectRoot

function Write-ProjectFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $directory = Split-Path -Parent $Path
    if ($directory -and -not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    if ((Test-Path $Path) -and -not $Force) {
        Write-Host "Skipped existing: $Path" -ForegroundColor Yellow
        return
    }

    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Host "Written: $Path" -ForegroundColor Green
}

$folders = @(
    ".codex",
    "docs",
    "docs/decisions",
    "scripts",
    "test/unit",
    "test/widget",
    "test/helpers",
    "test/fixtures",
    "integration_test"
)

foreach ($folder in $folders) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
}

Write-ProjectFile "AGENTS.md" @'
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

List only real unresolved risks. Write `None` when there are none.
'@

Write-ProjectFile ".codex/INDEX.md" @'
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
'@

Write-ProjectFile ".codex/MEMORY.md" @'
# Project Memory

This file contains stable project facts that should remain useful across future tasks.
Do not place temporary task notes here.

## Product

- Application name: TODO
- Product purpose: TODO
- Primary platforms: Android and iOS
- Additional platforms: TODO
- Supported locales: TODO
- Minimum Android version: TODO
- Minimum iOS version: TODO

## Toolchain

- Flutter version: Read from project/tooling
- Dart version: Read from `pubspec.yaml` SDK constraints
- Package manager: Dart Pub
- Build environments: TODO
- CI provider: TODO

## Technical stack

- Architecture: TODO
- Feature organization: TODO
- State management: TODO
- Routing: TODO
- Networking: TODO
- Persistence: TODO
- Dependency injection: TODO
- Serialization: TODO
- Code generation: TODO
- Authentication: TODO
- Analytics: TODO
- Crash reporting: TODO
- Backend services: TODO

## Stable conventions

- Follow existing feature patterns before introducing alternatives.
- Keep business logic outside widget build methods.
- Do not access infrastructure directly from UI unless documented architecture permits it.
- Keep generated files generated.
- Add or update tests for behavior changes.
- Run formatting, analysis, and relevant tests before completion.

## Error handling

- Error model: TODO
- User-facing error mapping: TODO
- Logging approach: TODO
- Retry policy: TODO

## Security

- Secrets source: TODO
- Environment configuration: TODO
- Secure storage: TODO
- Certificate or signing handling: Never commit private keys, credentials, or signing secrets.

## Testing

- Unit test framework: `flutter_test`
- Mocking approach: TODO
- Widget test helpers: `test/helpers/`
- Fixtures: `test/fixtures/`
- Integration tests: `integration_test/`

## Required validation

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

## Known platform constraints

### Android

- TODO

### iOS

- TODO

### Other platforms

- TODO

## Important stable decisions

Record only decisions that are expected to affect many future tasks.

- TODO
'@

Write-ProjectFile ".codex/PROJECT_STATE.md" @'
# Project State

Last updated: YYYY-MM-DD

## Current objective

- TODO

## In progress

- TODO

## Completed recently

- TODO

## Known failures

- None recorded.

## Blockers

- None recorded.

## Technical debt

- TODO

## Test status

- Formatting: Unknown
- Analyzer: Unknown
- Unit and widget tests: Unknown
- Integration tests: Unknown

## Next recommended actions

1. Fill stable project information in `.codex/MEMORY.md`.
2. Review architecture and conventions documents against the existing codebase.
3. Run `scripts/check.ps1` and record any pre-existing failures.
'@

Write-ProjectFile ".codex/DECISIONS.md" @'
# Technical Decisions

Use this file for concise records of long-lived architectural or technical choices.
Do not record routine implementation details.

## Decision template

### ADR-000: Decision title

- Date: YYYY-MM-DD
- Status: Proposed | Accepted | Superseded | Rejected
- Context: What problem or constraint required a decision?
- Decision: What was chosen?
- Alternatives: What realistic alternatives were considered?
- Consequences: What tradeoffs, migration work, or constraints result?
- Affected areas: Which features, packages, platforms, or teams are affected?
- Verification: How will the decision be validated?

---

## Decisions

No decisions recorded yet.
'@

Write-ProjectFile ".codex/CHANGELOG_AI.md" @'
# AI-Assisted Change Log

Keep entries concise. Do not paste full diffs, logs, or private reasoning.

## Entry template

### YYYY-MM-DD — Short task title

- Implemented:
- Changed:
- Tests:
- Validation:
- Remaining risk:

---

No entries yet.
'@

Write-ProjectFile ".codex/TASK_TEMPLATE.md" @'
# Codex Task Template

Use the relevant Flutter skills for this task.

Before changing code:

1. Read and follow all applicable `AGENTS.md` files.
2. Read `.codex/INDEX.md`.
3. Select only the relevant skills and read their complete `SKILL.md` files.
4. Inspect relevant project documentation, source files, and tests.
5. Search for an existing implementation pattern.

## Task

Describe the exact feature, bug, refactor, or maintenance task.

## Expected behavior

- TODO

## Constraints

- Follow the existing architecture and conventions.
- Make the smallest complete change.
- Do not modify unrelated files.
- Do not add dependencies unless necessary.
- Do not manually edit generated files.
- Preserve platform behavior unless explicitly changed.
- Add or update tests for changed behavior.

## Acceptance criteria

- TODO

## Required validation

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

When code generation changes:

```bash
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code
```

Do not claim completion unless required checks pass or environmental limitations are clearly documented.
'@

Write-ProjectFile ".codex/PROMPTS.md" @'
# Prompt Library

## Repository inspection

```text
Inspect this Flutter repository without modifying files.

1. Read all applicable AGENTS.md files.
2. Read .codex/INDEX.md and the minimum required memory files.
3. List available Flutter skills by name and one-line purpose.
4. Inspect pubspec.yaml, analysis_options.yaml, source organization, and tests.
5. Identify architecture, state management, routing, networking, persistence, dependency injection, code generation, and test setup.
6. Report missing or conflicting documentation.
7. Do not load every SKILL.md and do not modify files.
```

## Feature implementation

```text
Use the relevant Flutter feature and testing skills.
Read and follow AGENTS.md and .codex/INDEX.md.

Task:
[Describe the feature.]

Expected behavior:
[List exact behaviors and states.]

Constraints:
- Reuse existing architecture and patterns.
- Make the smallest complete change.
- Do not add dependencies unless necessary.
- Add or update tests.
- Run formatting, analysis, and relevant tests.

Do not claim completion without validation evidence.
```

## Bug fix

```text
Use the relevant Flutter debugging and testing skills.
Read and follow AGENTS.md and .codex/INDEX.md.

Bug evidence:
[Paste error, stack trace, steps, current behavior, and expected behavior.]

Work in this order:
1. Trace the failure.
2. Identify the root cause.
3. Add or update a regression test when practical.
4. Make the smallest safe fix.
5. Run targeted tests, formatter, analyzer, and broader relevant tests.
6. Report root cause, changed files, validation, and remaining uncertainty.
```

## Code review

```text
Use the relevant Flutter review skill.
Read AGENTS.md and inspect the diff and affected tests.

Review for:
- Correctness and regressions
- Architecture violations
- Async and lifecycle safety
- Null safety and error handling
- Security and privacy
- Performance problems
- Accessibility and localization
- Missing tests

Report findings in severity order with exact file paths and actionable fixes.
Do not rewrite code unless requested.
```
'@

Write-ProjectFile "docs/architecture.md" @'
# Architecture

## Purpose

This document describes the intended structure and dependency boundaries of the Flutter application.
Update it to reflect the actual project rather than imposing a new architecture without need.

## Architecture principles

- Organize code by cohesive product responsibility.
- Keep business rules testable without rendering widgets.
- Keep infrastructure details behind stable boundaries.
- Make dependencies explicit.
- Prefer simple structures that match current project size.
- Avoid abstractions that have only one speculative use.

## Current architecture

- Architecture style: TODO
- Source organization: TODO
- State management: TODO
- Dependency injection: TODO
- Routing: TODO
- Networking: TODO
- Persistence: TODO

## Recommended layer responsibilities

Use these responsibilities only where they match the existing project.

### Presentation

Contains:

- Screens and pages
- Reusable widgets
- View models, controllers, blocs, cubits, or notifiers
- Presentation-specific state
- UI validation and formatting

Must not:

- Directly call concrete HTTP clients or databases
- Contain reusable business rules that belong in domain or application code
- Start side effects from widget `build` methods

### Application

Contains:

- Use cases
- Commands and queries
- Workflow orchestration
- Application services
- State transitions not tied to rendering

### Domain

Contains:

- Entities and value objects
- Domain rules
- Repository contracts where appropriate
- Domain failures

Must remain independent from Flutter UI classes and concrete infrastructure.

### Data or infrastructure

Contains:

- API clients and data sources
- DTOs and serializers
- Repository implementations
- Persistence adapters
- Platform service adapters

Must map external data and errors into project-owned types before exposing them to higher layers.

## Feature organization

Document the actual feature layout here.

Example feature-first structure:

```text
lib/
  core/
  features/
    authentication/
      data/
      domain/
      presentation/
```

Do not reorganize the entire repository merely to match this example.

## Dependency direction

Dependencies should move toward stable business rules.

Typical direction:

```text
presentation -> application/domain
infrastructure -> domain/application contracts
```

Avoid circular dependencies and hidden service locator usage.

## Shared code

Shared code belongs in a common area only when:

- It is used by multiple features.
- Its ownership is clear.
- It has a stable responsibility.

Do not create generic `utils` dumping grounds.

## Error flow

Document:

1. How infrastructure exceptions are caught.
2. How they are mapped into project failures.
3. How application state represents failure.
4. How presentation maps failure into localized user messages.
5. What is logged and what must remain private.

Current error flow: TODO

## Dependency injection

- Mechanism: TODO
- Registration location: TODO
- Test override mechanism: TODO
- Lifecycle rules: TODO

Dependencies must be replaceable in tests without using production services.

## Code generation

- Generators in use: TODO
- Generated file patterns: TODO
- Generation command: TODO

Never manually edit generated output.

## Architecture change policy

A meaningful architecture change requires:

1. Evidence that current structure cannot reasonably support the task.
2. A focused migration plan.
3. Updated tests.
4. Updated documentation.
5. A record in `.codex/DECISIONS.md`.

Avoid architecture changes inside unrelated feature work.
'@

Write-ProjectFile "docs/conventions.md" @'
# Coding Conventions

## Dart style

- Follow `dart format` and project analyzer rules.
- Use descriptive names based on product intent.
- Prefer small cohesive functions.
- Avoid boolean parameters when named types or enums express intent better.
- Avoid unnecessary `dynamic` and unsafe casts.
- Keep nullability meaningful.
- Use comments to explain why, not restate what code already says.

## Files and naming

- Use `snake_case.dart` file names.
- Use `UpperCamelCase` for types.
- Use `lowerCamelCase` for variables, parameters, functions, and members.
- Use names consistent with the surrounding feature.
- Keep one primary public responsibility per file when practical.

## Widgets

- Prefer immutable widgets.
- Use `const` constructors when valid.
- Keep `build` declarative.
- Extract widgets by clear responsibility, reuse, testability, or rebuild isolation.
- Avoid very large anonymous widget trees when named widgets improve clarity.
- Do not store derived UI values as mutable state when they can be computed.
- Preserve accessibility semantics and touch target usability.

## Asynchronous code

- Handle errors explicitly.
- Check `mounted` before using `BuildContext` after an async gap.
- Cancel or dispose owned asynchronous resources.
- Prevent duplicate submissions where user actions trigger asynchronous work.
- Avoid arbitrary delays as synchronization.

## State

- Keep state immutable where the selected approach supports it.
- Model loading, data, empty, and failure states explicitly.
- Avoid multiple competing sources of truth.
- Keep transient widget state local when it does not belong in application state.
- Do not introduce another state-management library into an existing feature.

## Models

- Separate external DTO shape from domain shape when the project architecture requires it.
- Validate and normalize external data at boundaries.
- Avoid leaking transport-specific fields into UI.
- Preserve backwards compatibility when reading persisted data.

## Errors and logging

- Never silently ignore unexpected errors.
- Do not display raw exceptions to users.
- Do not log credentials, tokens, personal data, or sensitive payloads.
- Include enough technical context for diagnosis without exposing secrets.

## Dependencies

Before adding a package:

1. Confirm existing dependencies and SDK features are insufficient.
2. Check compatibility with the current Flutter and Dart constraints.
3. Evaluate maintenance, platform support, license, and transitive impact.
4. Document why it is needed.
5. Add tests around behavior introduced through the dependency.

## Generated code

- Edit the annotated source, never the generated output.
- Run the configured generator.
- Review generated changes.
- Do not commit stale generated output if the repository tracks it.

## Imports

- Follow existing project import style.
- Remove unused imports.
- Avoid fragile deep imports into package internals.
- Keep import ordering formatter-compatible.

## User-facing content

- Use the project localization system.
- Avoid hard-coded user-facing strings when localization is enabled.
- Use consistent terminology.
- Ensure error messages are actionable and safe.
'@

Write-ProjectFile "docs/testing.md" @'
# Testing Strategy

## Goals

Tests should provide fast, deterministic evidence that changed behavior works and important existing behavior remains intact.

## Test pyramid

### Unit tests

Use for:

- Business rules
- Validation
- Data mapping
- Error mapping
- Use cases
- Controllers, blocs, cubits, or notifiers without rendering
- Repository behavior with fake data sources

Unit tests should be fast and avoid Flutter rendering when not needed.

### Widget tests

Use for:

- Rendering states
- User interaction
- Form validation
- Navigation triggers
- Accessibility semantics
- Loading, empty, success, and error presentation
- Theme and localization integration where relevant

### Integration tests

Use for:

- Critical user journeys
- Cross-layer behavior
- Platform integration
- Authentication or checkout flows
- Realistic startup and navigation paths

Keep integration coverage focused because it is slower and more environment-dependent.

## Folder structure

```text
test/
  unit/
  widget/
  helpers/
  fixtures/
integration_test/
```

Mirror source feature names where practical.

## Test naming

Use descriptive behavior names.

Example:

```dart
test('returns validation failure when email is empty', () {});
```

Widget example:

```dart
testWidgets('shows progress indicator while submission is loading', (tester) async {});
```

## Arrange, act, assert

Keep tests readable:

1. Arrange dependencies and state.
2. Act through the public behavior.
3. Assert observable outcomes.

Avoid testing private implementation details.

## Test isolation

- Reset global state between tests.
- Do not depend on execution order.
- Avoid production network calls.
- Avoid real analytics and crash-reporting calls.
- Use temporary storage or fakes for persistence.
- Control clocks, randomness, and schedulers when relevant.
- Avoid arbitrary `Future.delayed` synchronization.

## Fakes and mocks

Prefer simple fakes for stable interfaces and stateful behavior.
Use mocks where interaction verification is important.
Do not over-mock value objects or pure functions.

Document the project mocking package here: TODO

## Regression tests

For a bug fix:

1. Add a test that demonstrates the reported failure when practical.
2. Confirm it fails for the expected reason before the fix when possible.
3. Apply the fix.
4. Confirm the test passes.
5. Run related broader tests.

## Golden tests

Use only when visual output is important and the project has a stable golden workflow.

Golden tests require:

- Stable fonts and rendering environment
- Clear update process
- Review of image changes
- Avoidance of overly broad screenshots

Current golden policy: TODO

## Test helpers

Place reusable setup in `test/helpers/` when it improves readability across multiple tests.
Do not hide essential test behavior behind excessive helper abstraction.

Common helpers may include:

- App or widget pump helpers
- Dependency overrides
- Fake repositories
- Test localization setup
- Router setup
- Fixture readers

## Fixtures

Place static representative data under `test/fixtures/`.
Fixtures must:

- Contain no real credentials or personal information.
- Be small and focused.
- Be named by scenario.
- Avoid copying large production payloads unnecessarily.

## Required commands

All tests:

```bash
flutter test
```

Specific file:

```bash
flutter test test/path/to/test_file.dart
```

Integration tests:

```bash
flutter test integration_test
```

Coverage when required:

```bash
flutter test --coverage
```

## Completion criteria

A behavior change is sufficiently tested when:

- Core business rules are covered at the lowest useful level.
- Relevant UI states and interactions are covered.
- A fixed defect has regression coverage when feasible.
- Tests are deterministic.
- Relevant suites pass.
- Skipped environmental checks are clearly reported.
'@

Write-ProjectFile "docs/state-management.md" @'
# State Management

## Current approach

- Library or pattern: TODO
- Provider or registration location: TODO
- State model convention: TODO
- Side-effect convention: TODO
- Test override convention: TODO

## Principles

- Use the existing state-management approach.
- Keep one clear source of truth for each state.
- Keep state immutable when supported.
- Model meaningful states explicitly.
- Separate state transitions from widget rendering.
- Keep transient visual state local when appropriate.
- Do not perform side effects from widget `build` methods.

## Recommended state shape

Where applicable, represent:

- Initial or idle
- Loading
- Data or success
- Empty
- Validation failure
- Recoverable failure
- Terminal failure

Avoid multiple loosely related booleans that allow invalid combinations.

## Async operations

- Prevent duplicate concurrent submissions when required.
- Preserve previous data during refresh when product behavior expects it.
- Handle cancellation and disposal.
- Map infrastructure errors into project-owned failures.
- Expose user-safe error information to presentation.

## UI integration

Widgets should:

- Watch only the state they need.
- Trigger actions through the existing controller or notifier boundary.
- Avoid direct API or database access.
- Render all expected states.
- Avoid repeated side effects caused by rebuilds.

## Testing

State tests should cover:

- Initial state
- Successful transition
- Validation failure
- Infrastructure failure mapping
- Retry or refresh behavior
- Duplicate action prevention when relevant
- Disposal or cancellation behavior when relevant
'@

Write-ProjectFile "docs/navigation.md" @'
# Navigation

## Current setup

- Router library: TODO
- Router configuration location: TODO
- Route naming convention: TODO
- Authentication guards: TODO
- Deep-link support: TODO

## Rules

- Use the existing router and route declaration style.
- Do not introduce direct `Navigator` calls when the project consistently uses a router abstraction.
- Keep route arguments typed where supported.
- Validate external deep-link input.
- Avoid passing sensitive information in route URLs.
- Preserve browser and system back behavior.
- Keep navigation side effects outside widget `build`.

## Authentication and authorization

Document:

- Unauthenticated entry behavior
- Protected routes
- Role or permission checks
- Redirect loops prevention
- Session expiration behavior

Current behavior: TODO

## Deep links

- Supported schemes and domains: TODO
- Unknown link behavior: TODO
- Required validation: TODO

## Testing

Navigation tests should cover:

- Expected destination
- Required arguments
- Authentication redirects
- Back behavior
- Unknown routes
- Deep-link parsing where supported
'@

Write-ProjectFile "docs/networking.md" @'
# Networking

## Current setup

- HTTP client: TODO
- Client creation location: TODO
- Base URL configuration: TODO
- Authentication mechanism: TODO
- Serialization: TODO
- Retry policy: TODO
- Timeout policy: TODO

## Boundary rules

- Widgets must not directly call concrete HTTP clients unless explicitly allowed by existing architecture.
- Keep transport DTOs at the data boundary.
- Map responses into project-owned models.
- Map transport errors into project-owned failures.
- Do not expose raw server exceptions to users.

## Requests

- Use configured timeouts.
- Validate required input before sending.
- Avoid logging secrets, authorization headers, cookies, or sensitive payloads.
- Use idempotency or duplicate-submission prevention where required.
- Encode query and path parameters safely.

## Responses

- Validate required response fields.
- Handle optional and backward-compatible fields safely.
- Treat malformed data as a controlled failure.
- Avoid unsafe casts from decoded JSON.

## Authentication

Document:

- Token storage: TODO
- Refresh flow: TODO
- Expiration behavior: TODO
- Logout cleanup: TODO
- Concurrent refresh behavior: TODO

## Offline and retry behavior

- Offline strategy: TODO
- Retryable failures: TODO
- Maximum retries: TODO
- Backoff strategy: TODO
- User-visible retry behavior: TODO

Do not retry non-idempotent operations blindly.

## Testing

Networking tests should cover:

- Successful mapping
- Expected status failures
- Timeout or connectivity failure
- Malformed response
- Authentication expiration
- Retry behavior where configured
- Sensitive data not being logged
'@

Write-ProjectFile "docs/security.md" @'
# Security

## Principles

- Never commit secrets, credentials, private keys, signing files, production tokens, or sensitive environment values.
- Treat all external input as untrusted.
- Minimize collection, storage, and logging of personal data.
- Use platform secure storage for sensitive client-side values when required.
- Enforce authorization on the server; client checks are user experience controls, not security boundaries.

## Secrets and configuration

Document:

- Environment mechanism: TODO
- Secret injection process: TODO
- Local development setup: TODO
- CI secret source: TODO

Safe repository files may contain example placeholders only.

## Authentication

- Avoid storing passwords.
- Protect tokens using the approved storage mechanism.
- Clear credentials and sensitive cached state on logout.
- Handle token refresh without exposing tokens in logs.
- Avoid duplicate refresh races.
- Treat session expiration explicitly.

## Data protection

- Do not log personal or sensitive payloads.
- Redact identifiers where possible.
- Avoid unnecessary local persistence.
- Define data deletion behavior.
- Encrypt sensitive data in transit and use trusted TLS configuration.

## Input and output safety

- Validate user and external input.
- Encode values appropriately for URLs and serialization.
- Avoid rendering unsafe remote HTML without a controlled sanitizer and clear product need.
- Validate file types, sizes, and names for uploads.
- Do not trust client-side authorization flags.

## Platform configuration

Review platform changes for:

- Android exported components
- Android permissions
- Network security configuration
- iOS entitlements
- iOS URL schemes
- Keychain usage
- Deep-link validation
- Backup behavior

## Dependencies

Before adding or upgrading security-sensitive dependencies:

- Check maintenance status.
- Check compatibility.
- Review known advisories.
- Minimize permissions and transitive dependencies.

## Security review checklist

- No secrets in diff
- No sensitive logging
- Inputs validated
- Errors user-safe
- Authorization assumptions documented
- Storage appropriate for sensitivity
- Platform permissions minimal
- Tests cover failure and expiration paths
'@

Write-ProjectFile "docs/performance.md" @'
# Performance

## Principles

- Measure before major optimization.
- Fix observable bottlenecks rather than optimizing speculative paths.
- Preserve correctness and clarity.
- Avoid unnecessary rebuilds and repeated expensive work.

## Rendering

- Keep expensive computation out of `build`.
- Use `const` where valid.
- Watch the minimum necessary state.
- Avoid rebuilding large trees for small state changes.
- Use lazy builders for long lists.
- Provide stable keys where identity matters.
- Avoid unnecessary opacity, clipping, and save-layer operations.

## Images

- Request appropriately sized images.
- Avoid decoding very large images for small display areas.
- Use project caching policy.
- Handle placeholders and errors.
- Avoid bundling unnecessary high-resolution assets.

## Data and networking

- Paginate or stream large datasets.
- Avoid duplicate requests.
- Cache only where correctness and invalidation are understood.
- Move expensive parsing or computation off the UI isolate when justified by measurement.

## Startup

- Avoid unnecessary synchronous work before first frame.
- Defer optional initialization.
- Keep dependency setup predictable.
- Measure startup using appropriate Flutter profiling tools.

## Memory and lifecycle

- Dispose owned resources.
- Avoid retaining large collections or widget contexts unnecessarily.
- Cancel unused subscriptions and requests when supported.
- Review image and cache limits.

## Validation

For performance-sensitive changes:

1. Record the scenario.
2. Record the baseline.
3. Apply the focused change.
4. Re-measure in profile or release mode.
5. Report tradeoffs and device conditions.

Do not claim performance improvement without evidence when measurement is practical.
'@

Write-ProjectFile "docs/localization.md" @'
# Localization

## Current setup

- Localization package or Flutter generation: TODO
- ARB or source location: TODO
- Generated access class: TODO
- Supported locales: TODO
- Fallback behavior: TODO

## Rules

- Do not hard-code user-facing strings when localization is configured.
- Reuse existing message keys where meaning is identical.
- Add new keys with clear semantic names.
- Keep placeholders typed and documented.
- Avoid building sentences by concatenating translated fragments.
- Support pluralization and gender where required.
- Preserve right-to-left layout support when applicable.

## Formatting

Use locale-aware formatting for:

- Dates and times
- Numbers
- Currency
- Percentages
- Relative time

Do not assume English word order or formatting.

## Error messages

- Map technical failures to localized user-safe messages.
- Keep actionable recovery guidance.
- Do not display raw server or exception text.

## Testing

Localization tests should cover:

- New keys exist for supported locales
- Placeholder rendering
- Important layouts with longer strings
- Right-to-left behavior where supported
- Locale switching if supported
'@

Write-ProjectFile "docs/release.md" @'
# Release Process

## Release targets

- Android: TODO
- iOS: TODO
- Other platforms: TODO

## Versioning

- Version source: `pubspec.yaml`
- Version policy: TODO
- Build number policy: TODO
- Tagging convention: TODO

## Pre-release checks

1. Confirm clean working tree or reviewed intended changes.
2. Run formatter.
3. Run analyzer.
4. Run unit and widget tests.
5. Run relevant integration tests.
6. Regenerate code and localization output where applicable.
7. Review dependency and platform configuration changes.
8. Verify environment selection.
9. Verify no secrets or debug endpoints are included.
10. Review release notes.

## Standard validation

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

## Android

Document:

- Application ID: TODO
- Signing source: TODO
- Build command: TODO
- Flavor commands: TODO
- Play Console process: TODO
- Required permission review: TODO

Never commit private keystores or signing passwords.

## iOS

Document:

- Bundle identifier: TODO
- Team and signing approach: TODO
- Build command: TODO
- Flavor or scheme mapping: TODO
- App Store Connect process: TODO
- Entitlement review: TODO

Never commit private certificates, profiles containing sensitive data, or signing credentials.

## Rollback

- Rollback owner: TODO
- Feature flag strategy: TODO
- Previous release restoration process: TODO
- Data migration compatibility requirements: TODO

## Release evidence

Record:

- Commit and tag
- Build number
- Environment
- Validation results
- Known limitations
- Migration or rollout notes
'@

Write-ProjectFile "docs/decisions/README.md" @'
# Architecture Decision Records

Use this directory for detailed Architecture Decision Records when a decision is too substantial for a concise entry in `.codex/DECISIONS.md`.

## File naming

```text
NNNN-short-decision-title.md
```

Example:

```text
0001-use-existing-state-management.md
```

## Template

```markdown
# ADR-NNNN: Decision title

- Status: Proposed | Accepted | Superseded | Rejected
- Date: YYYY-MM-DD
- Owners: TODO

## Context

Describe the problem, constraints, and evidence.

## Decision

Describe the chosen approach precisely.

## Alternatives considered

Describe realistic alternatives and why they were not selected.

## Consequences

List benefits, costs, migration work, limitations, and operational impact.

## Validation

Describe tests, metrics, or rollout evidence.

## Follow-up

List required follow-up work.
```

Do not create ADRs for routine implementation choices.
'@

Write-ProjectFile "test/helpers/README.md" @'
# Test Helpers

Place reusable testing infrastructure here.

Suitable examples:

- Widget pump helpers
- Dependency overrides
- Fake repositories and services
- Router setup
- Test localization setup
- Deterministic clocks
- Test-only builders

Rules:

- Keep helpers small and explicit.
- Do not hide important test actions.
- Do not depend on production network or analytics services.
- Reset shared state between tests.
- Avoid a single oversized helper used for unrelated scenarios.
'@

Write-ProjectFile "test/fixtures/README.md" @'
# Test Fixtures

Place small static fixture files here.

Rules:

- Never include real personal information, credentials, access tokens, or production secrets.
- Keep fixtures minimal and scenario-specific.
- Use descriptive names such as `login_success.json` or `malformed_profile.json`.
- Prefer programmatic builders for highly variable test data.
- Document unusual fields inside the test that uses the fixture.
'@

Write-ProjectFile "test/unit/README.md" @'
# Unit Tests

Place tests for pure logic and non-rendered application behavior here.

Typical coverage:

- Validators
- Mappers
- Value objects
- Use cases
- Repositories with fake data sources
- State controllers without widget rendering
- Error mapping

Mirror feature paths where practical and use descriptive behavior-based test names.
'@

Write-ProjectFile "test/widget/README.md" @'
# Widget Tests

Place rendering and interaction tests here.

Typical coverage:

- Loading, empty, success, and error states
- Form validation
- Taps, text input, scrolling, and submission
- Navigation triggers
- Accessibility semantics
- Localization and theme integration

Use shared setup from `test/helpers/` only when it improves clarity.
'@

Write-ProjectFile "integration_test/README.md" @'
# Integration Tests

Place critical end-to-end or cross-layer Flutter flows here.

Use integration tests for high-value journeys such as:

- App startup
- Authentication
- Checkout or booking
- Deep links
- Native platform integration

Requirements:

- Keep scenarios deterministic.
- Isolate test accounts and data.
- Do not run destructive actions against production.
- Document required emulator, device, environment, and credentials setup using placeholders only.

Run with:

```bash
flutter test integration_test
```
'@

Write-ProjectFile "scripts/check.ps1" @'
param(
    [switch]$SkipTests,
    [switch]$RunIntegration,
    [switch]$RunCodegen
)

$ErrorActionPreference = "Stop"

function Invoke-Step {
    param(
        [string]$Name,
        [scriptblock]$Command
    )

    Write-Host "`n==> $Name" -ForegroundColor Cyan
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE"
    }
}

if (-not (Test-Path "pubspec.yaml")) {
    throw "Run this script from the Flutter project root."
}

Invoke-Step "Flutter environment" { flutter --version }
Invoke-Step "Dependency resolution" { flutter pub get }

if ($RunCodegen) {
    Invoke-Step "Code generation" {
        dart run build_runner build --delete-conflicting-outputs
    }
}

Invoke-Step "Formatting check" {
    dart format --output=none --set-exit-if-changed .
}

Invoke-Step "Static analysis" { flutter analyze }

if (-not $SkipTests) {
    Invoke-Step "Unit and widget tests" { flutter test }
}

if ($RunIntegration) {
    if (-not (Test-Path "integration_test")) {
        throw "integration_test directory does not exist."
    }
    Invoke-Step "Integration tests" { flutter test integration_test }
}

Write-Host "`nAll requested checks passed." -ForegroundColor Green
'@

Write-ProjectFile "scripts/test.ps1" @'
param(
    [string]$Path,
    [switch]$Coverage,
    [switch]$Integration
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path "pubspec.yaml")) {
    throw "Run this script from the Flutter project root."
}

$arguments = @("test")

if ($Integration) {
    $arguments += "integration_test"
} elseif ($Path) {
    $arguments += $Path
}

if ($Coverage) {
    $arguments += "--coverage"
}

Write-Host "Running: flutter $($arguments -join ' ')" -ForegroundColor Cyan
& flutter @arguments

if ($LASTEXITCODE -ne 0) {
    throw "Tests failed with exit code $LASTEXITCODE"
}

Write-Host "Tests passed." -ForegroundColor Green
'@

Write-ProjectFile "scripts/generate.ps1" @'
param(
    [switch]$Watch
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path "pubspec.yaml")) {
    throw "Run this script from the Flutter project root."
}

if ($Watch) {
    dart run build_runner watch --delete-conflicting-outputs
} else {
    dart run build_runner build --delete-conflicting-outputs
}

if ($LASTEXITCODE -ne 0) {
    throw "Code generation failed with exit code $LASTEXITCODE"
}
'@

Write-ProjectFile "scripts/bootstrap.ps1" @'
$ErrorActionPreference = "Stop"

if (-not (Test-Path "pubspec.yaml")) {
    throw "Run this script from the Flutter project root."
}

Write-Host "Resolving Flutter dependencies..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed" }

if (Test-Path ".agents/skills") {
    Write-Host "Flutter agent skills found under .agents/skills." -ForegroundColor Green
} else {
    Write-Warning "No .agents/skills directory found. Install the Flutter agent skills if required."
}

Write-Host "Running initial analyzer check..." -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Analyzer reported existing issues. Review them before agent-assisted development."
}

Write-Host "Bootstrap complete." -ForegroundColor Green
'@

Write-ProjectFile "README-CODEX.md" @'
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
'@

Write-Host "`nFlutter Codex workspace setup completed." -ForegroundColor Green
Write-Host "Review TODO fields, then run: .\scripts\bootstrap.ps1" -ForegroundColor Cyan
