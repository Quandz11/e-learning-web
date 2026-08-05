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
