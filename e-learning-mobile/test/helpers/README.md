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
