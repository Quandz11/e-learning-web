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
