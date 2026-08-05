# Project Memory

This file contains stable project facts that should remain useful across future tasks.
Do not place temporary task notes here.

## Product

- Application name: SKVI Mobile
- Product purpose: Flutter mobile app for the SKVI e-learning platform
- Primary platforms: Android and iOS
- Additional platforms: None confirmed
- Supported locales: English and Vietnamese assets are present
- Minimum Android version: 23
- Minimum iOS version: 12.0

## Toolchain

- Flutter version: Read from project/tooling
- Dart version: `^3.8.1`
- Package manager: Dart Pub
- Build environments: `dev`, `staging`, `prod`
- CI provider: TODO

## Technical stack

- Architecture: Minimal feature-first
- Feature organization: `app/`, `core/`, `features/`, `shared/`
- State management: Riverpod
- Routing: GoRouter
- App startup: `bootstrapAndRun()` mounts a themed Flutter startup host immediately and keeps config loading plus session restoration outside the router until they settle
- Authenticated shell: `ShellRoute` with `NavigationBar` and `/app/home`, `/app/learning`, `/app/community`, `/app/profile` as top-level authenticated destinations
- Authenticated shell labels: `Trang chủ`, `Học tập`, `Cộng đồng`, `Cá nhân`
- Networking: Dio with app-owned auth/error interceptors
- Android emulator dev networking: localhost API hosts are normalized to `10.0.2.2`, and dev HTTPS transport allows localhost certificates only for local development hosts
- Persistence: Flutter Secure Storage for session tokens only
- Dependency injection: Riverpod providers
- Theme system: centralized Material 3 light/dark themes with shared tokens and reusable widgets under `shared/`
- Serialization: Handwritten immutable Dart models for current foundation
- Code generation: Not used in the Phase 1 foundation
- Authentication: JWT bearer tokens with refresh-token body refresh against backend `/auth/refresh`
- Auth data layer: handwritten auth contracts for `/auth/login`, `/auth/register`, `/auth/verify-otp`, and `/auth/logout`
- Login route: `/login` with Riverpod-managed controller state and redirect to the protected placeholder after successful normal login
- Startup routing: GoRouter starts from `/app` so authenticated users resolve into `/app/home` and unauthenticated users resolve into `/login` after startup completes
- Registration route: `/register` with Riverpod-managed controller state and redirect to `/verify-otp` placeholder after successful signup
- Shared OTP route: `/verify-otp` handles both registration verification and login two-factor completion through an in-memory challenge provider
- Debug component route: `/dev/components` is available only in debug builds for internal visual verification
- Bottom navigation source of truth: the active GoRouter location; no separate selected-tab state is stored
- Bottom navigation presentation: compact Material 3 `NavigationBar` inside the shell scaffold with a rounded surface container, pill indicator, and safe bottom inset handling
- Two-factor login contract: backend login may return a short-lived pre-auth token with `requiresTwoFactor = true`; Flutter does not persist it as an authenticated session
- Registration contract: backend signup returns only a message, does not authenticate the app session, and requires later OTP verification
- OTP security rule: the login pre-auth bearer token is kept only in memory until `/auth/2fa/login-verify` succeeds and is never written to secure storage
- Analytics: TODO
- Crash reporting: TODO
- Backend services: ASP.NET Core backend with JWT auth and payment callbacks

## Stable conventions

- Follow existing feature patterns before introducing alternatives.
- Keep business logic outside widget build methods.
- Do not access infrastructure directly from UI unless documented architecture permits it.
- Keep generated files generated.
- Add or update tests for behavior changes.
- Run formatting, analysis, and relevant tests before completion.
- Feature screens should consume shared theme tokens and reusable UI widgets instead of hard-coded styling.
- Future nested authenticated routes should live under the existing `/app/*` shell structure rather than creating another top-level scaffold.

## Error handling

- Error model: `AppFailure`
- User-facing error mapping: Dio errors are normalized into user-safe failures
- Logging approach: Sensitive auth payloads and tokens must not be logged
- Dev auth diagnostics: request method, request path, HTTP status, and normalized backend code may be logged in development only
- Retry policy: Single retry after a successful refresh for eligible 401 responses

## Security

- Secrets source: No backend secrets are stored in Flutter env files
- Environment configuration: `assets/env/.env.dev`, `.env.staging`, `.env.prod`
- Secure storage: Flutter Secure Storage for access token, refresh token, and expiry only
- Certificate or signing handling: Never commit private keys, credentials, or signing secrets.

## Testing

- Unit test framework: `flutter_test`
- Mocking approach: Small handwritten fakes and adapters
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

- Custom deep-link schemes: `skvi`, `skvi-dev`, `skvi-staging`
- Universal link hosts: `nhinanchualanh.vn`, `www.nhinanchualanh.vn`
- Notification permission declared: `POST_NOTIFICATIONS`

### iOS

- Minimum deployment target: 12.0
- Custom deep-link schemes: `skvi`, `skvi-dev`, `skvi-staging`
- Background remote notification mode is enabled

### Other platforms

- Phase 1 uses the current worktree only and does not restore deleted Flutter source.

## Important stable decisions

Record only decisions that are expected to affect many future tasks.

- TODO
