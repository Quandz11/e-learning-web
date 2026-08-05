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
