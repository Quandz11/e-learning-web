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

- Architecture style: Minimal feature-first
- Source organization: `app/`, `core/`, `features/`, `shared/`
- State management: Riverpod
- Dependency injection: Riverpod providers
- Routing: GoRouter
- Networking: Dio
- Persistence: Flutter Secure Storage for session tokens only

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

Current Phase 1 does not introduce a separate application layer.
Feature controllers may depend directly on repositories until meaningful client-side workflow orchestration justifies another layer.

### Domain

Current Phase 1 does not introduce a separate domain layer.
Client-owned models should remain small, immutable, and shaped by confirmed backend contracts.

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

Current Phase 1 structure:

```text
lib/
  app/
  core/
    config/
    errors/
    network/
    routing/
    session/
    storage/
  features/
    foundation/
      presentation/
  shared/
    theme/
    widgets/
```

Expand features incrementally instead of adding empty architectural layers.

Current auth feature ownership:

- `features/auth/data/auth_api.dart` owns raw auth HTTP contracts and request-specific parsing for login, registration, OTP verification, 2FA login verification, logout, and refresh.
- `features/auth/data/auth_repository.dart` owns auth workflow persistence boundaries and writes secure session state only after full token responses.
- `features/auth/presentation/controllers/login_controller.dart`, `register_controller.dart`, and `verify_otp_controller.dart` own validation, duplicate-submit prevention, and feature state transitions.
- `features/auth/presentation/controllers/auth_otp_challenge_controller.dart` owns the short-lived in-memory OTP challenge needed to finish registration verification or login 2FA without persisting a partial session.
- `features/auth/presentation/screens/verify_otp_screen.dart` owns OTP entry UI and routes successful verification into the authenticated shell.

Current startup ownership:

- `app/bootstrap.dart` owns the immediate bootstrap host, async config/session initialization, and safe switch to either `App` or `StartupFailureScreen`.
- `features/foundation/presentation/startup_screen.dart` owns the lightweight startup UI shown while real bootstrap work is running.
- `core/session/session_controller.dart` remains the only app session source of truth and resolves unexpected restore failures to an unauthenticated state instead of crashing startup.

Current authenticated shell ownership:

- `core/routing/app_router.dart` owns the authenticated shell route structure and redirect policy.
- `features/foundation/presentation/app_shell.dart` owns the persistent authenticated scaffold and bottom navigation.
- Shell destination placeholders remain thin presentation screens and do not introduce repositories, controllers, or API calls.

Current UI foundation ownership:

- `shared/theme/` owns Material 3 themes plus small design-token files for color seed, spacing, radius, sizes, and typography.
- `shared/widgets/` owns reusable presentation primitives such as buttons, text fields, cards, layout shells, status views, badges, avatars, and skeleton placeholders.
- Feature screens compose shared widgets and theme roles rather than redefining common visual styles locally.

## Dependency direction

Dependencies should move toward stable business rules.

Current direction:

```text
presentation -> repositories/core services
repositories -> core network/storage
```

Avoid circular dependencies and general service locators.

## Shared code

Shared code belongs in a common area only when:

- It is used by multiple features.
- Its ownership is clear.
- It has a stable responsibility.

Do not create generic `utils` dumping grounds.

Current shared UI boundaries:

- Shared widgets may depend on Flutter framework and shared theme tokens.
- Shared widgets must not depend on feature controllers, repositories, or backend contracts.
- Feature screens may customize copy, layout composition, and field wiring while reusing shared visual primitives.
- The authenticated shell should read selected-tab state from the current route location instead of introducing a second navigation source of truth.

## Error flow

Document:

1. How infrastructure exceptions are caught.
2. How they are mapped into project failures.
3. How application state represents failure.
4. How presentation maps failure into localized user messages.
5. What is logged and what must remain private.

Current error flow:

1. Dio transport errors enter the app-owned error mapper.
2. The mapper normalizes inconsistent backend envelopes into `AppFailure`.
3. Session refresh failures clear secure session storage and session state.
4. Presentation renders user-safe messages through shared loading/error/empty widgets.
5. Tokens and auth payloads are never logged.

## Dependency injection

- Mechanism: Riverpod providers
- Registration location: `core/*` and `app/*` provider files
- Test override mechanism: `ProviderContainer` and provider overrides
- Lifecycle rules: App-wide providers live at the root container; feature-specific state should stay scoped where possible

Dependencies must be replaceable in tests without using production services.

## Code generation

- Generators in use: None in Phase 1
- Generated file patterns: None in Phase 1
- Generation command: Not applicable in Phase 1

Never manually edit generated output.

## Architecture change policy

A meaningful architecture change requires:

1. Evidence that current structure cannot reasonably support the task.
2. A focused migration plan.
3. Updated tests.
4. Updated documentation.
5. A record in `.codex/DECISIONS.md`.

Avoid architecture changes inside unrelated feature work.
