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

Document the project mocking package here: handwritten fakes and custom Dio adapters

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

Current golden policy: no golden tests in Phase 1

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

## Phase 1 baseline coverage

- Runtime configuration validation
- Dio failure normalization
- Secure session storage with in-memory fake coverage
- Session restoration and clearing
- Auth interceptor bearer attachment and single-flight refresh behavior
- Router redirect and payment callback normalization
- App startup smoke coverage
- Shared loading, error, and empty widgets

## Phase 2.1 auth coverage

- Auth request model serialization for login, register, verify OTP, and logout
- Auth token and message response parsing, including nullable and malformed payload cases
- Auth API request path, method, body, and normalized error mapping
- Auth repository session persistence for login and verify OTP
- Auth repository local logout clearing even when remote logout fails

## Phase 2.2 login coverage

- Login controller initial, submitting, success, failure, validation, retry, duplicate-submit, and two-factor-required states
- Login controller normalization of backend field errors and general errors
- Login widget rendering, password visibility toggle, loading disablement, duplicate-tap safety, viewport safety, and autofill/input configuration
- Router regressions for `/login`, protected redirect behavior, and successful login transition to the protected placeholder
- Login-specific backend contract coverage for pre-auth `requiresTwoFactor` responses

## Phase 2.3 registration coverage

- Registration controller initial, submitting, success, failure, validation, retry, duplicate-submit, and no-session-authentication states
- Registration controller normalization of backend field errors and business errors for duplicate-email and invalid-phone responses
- Registration widget rendering, password visibility toggles, loading disablement, duplicate-tap safety, viewport safety, and autofill/input configuration
- Router regressions for `/register`, authenticated redirect-away behavior, login-to-register and register-to-login navigation, and safe transition to the `/verify-otp` placeholder

## Phase 2.4 OTP verification coverage

- OTP controller initial, validating, submitting, success, failure, invalid-challenge, and duplicate-submit states
- OTP controller coverage for registration verification, login 2FA verification, backend field errors, malformed responses, and session synchronization only after full token responses
- OTP widget coverage for masked email display, six-digit input behavior, loading disablement, backend error rendering, safe missing-challenge handling, and success transition into the authenticated shell
- Router regressions for `/verify-otp` access control, authenticated redirect-away behavior, and safe handoff from registration and login 2FA flows
- Startup regressions confirming login is the no-session entry screen and authenticated sessions resolve to the shell

## Supported Phase 1 auth and profile coverage

- Forgot-password widget coverage for the public request screen and basic phone validation
- Profile overview widget coverage for summary rendering and authenticated actions
- Updated shell regressions proving `/app/profile` is a real authenticated feature and profile child routes preserve shell ownership
- Updated login, registration, and OTP widget regressions for the current Vietnamese auth labels and redirect behavior

## Startup experience coverage

- Bootstrap host coverage that confirms the startup screen renders while initialization is pending and disappears once the app settles
- Startup widget coverage for app name, loading indicator, accessibility semantics, light/dark rendering, and small-viewport or large-text safety
- Session-restore regressions for refresh failure, malformed refresh responses, and secure-storage read failures resolving safely to `/login`
- Router regression confirming the protected root `/app` is the startup entry location before redirects resolve

## Live auth verification status

- 2026-07-29 Android emulator + local backend verification confirmed app startup, login into `/app/home`, session restoration after restart, and logout clearing behavior.
- 2026-07-29 local backend verification confirmed registration reaches `POST /auth/register` and persists an OTP for the new account.
- In-app `/verify-otp` runtime completion was not fully confirmed on 2026-07-29 even though repository-level and widget-level OTP regressions pass.
- 2026-07-30 Android emulator verification against the current Azure-configured build confirmed native launch, Flutter startup UI, and the logged-out transition into `/login`.
- Azure-authenticated restore and logout were not reverified on 2026-07-30 because no non-secret Azure test credentials were available in the repository context.

## UI Phase 1 design foundation coverage

- Theme construction for light and dark Material 3 variants, required color roles, text styles, and accessible control sizes
- Shared widget rendering and interaction for buttons, text fields, cards, badges, avatars, page layout, and state views
- Debug component showcase route resolution in debug builds
- Regression coverage confirming login and registration flows still render, validate, navigate, and preserve existing auth behavior after shared-component migration

## UI Phase 2 app shell coverage

- Authenticated shell resolution from `/app` to `/app/home`
- Unauthenticated redirect behavior for `/app/*`
- Persistent bottom navigation rendering with exactly four destinations
- Route-driven selected tab behavior, Vietnamese destination labels, destination taps, and direct shell route resolution
- Back-button behavior from non-home shell tabs to home
- Rounded Material 3 navigation surface styling, visible selected indicator, and distinct unselected icon state
- Light and dark shell rendering, bottom safe-area handling, narrow-width stability, and large-text accessibility stability
- Placeholder destination rendering without API or loading behavior
- Regressions for login/register redirects, payment callbacks, debug showcase routing, and unknown-route handling
