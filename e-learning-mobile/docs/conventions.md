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
- Prefer shared theme tokens and `shared/widgets/*` components over per-screen styling when the behavior is generic.
- Do not hard-code repeated spacing, radius, colors, or button/input styling inside feature screens.
- Keep shared UI abstractions narrow; do not wrap standard Flutter widgets with unnecessary pass-through APIs.
- Prefer standard Material 3 navigation components for authenticated shell chrome unless a custom surface is necessary to preserve existing route behavior.

## Asynchronous code

- Handle errors explicitly.
- Check `mounted` before using `BuildContext` after an async gap.
- Cancel or dispose owned asynchronous resources.
- Prevent duplicate submissions where user actions trigger asynchronous work.
- Avoid arbitrary delays as synchronization.
- Keep startup and configuration handoff state-driven; do not navigate from stale contexts during bootstrap.

## State

- Keep state immutable where the selected approach supports it.
- Model loading, data, empty, and failure states explicitly.
- Avoid multiple competing sources of truth.
- Keep transient widget state local when it does not belong in application state.
- Do not introduce another state-management library into an existing feature.
- Do not store selected bottom-navigation tab state separately when the active GoRouter location already provides it.
- Do not introduce a second session-restoration process or another startup-state source when the bootstrap/session flow already models the transition.

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

## Design system usage

- Use `Theme.of(context).colorScheme` and the centralized theme before introducing raw color constants in screens.
- Use the small token sets in `shared/theme/` for spacing, radius, sizes, and typography-driven styling.
- Keep visual development and regression checks in the debug-only component showcase route rather than in product navigation.
- Keep authenticated shell chrome in the dedicated shell scaffold instead of recreating app bars or bottom navigation at each destination root.
- Keep bottom-navigation presentation route-driven and compact; visual shell polish must not introduce duplicate tab state, a second navigator, or per-tab scaffolds.
