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

- Dart version: `^3.8.1`
- Package manager: Dart Pub
- Build environments: `dev`, `staging`, `prod`

## Technical stack

- Architecture: Minimal feature-first
- Feature organization: `app/`, `core/`, `features/`, `shared/`
- State management: Riverpod
- Routing: GoRouter
- Authenticated shell: `ShellRoute` with `/app/home`, `/app/learning`, `/app/community`, and `/app/profile`
- Home feature: `/app/home` reuses `ProfileController` for the greeting header and loads published courses, authenticated enrollments, active categories, recent public articles, and active testimonials through a dedicated Home repository
- Authenticated profile child routes: `/app/profile/edit`, `/app/profile/change-password`, `/app/profile/security`
- Public recovery routes: `/forgot-password`, `/forgot-password/verify`
- Bottom navigation source of truth: current GoRouter location only
- Home actions route only to existing shell destinations until dedicated Learning and article-detail routes exist
- Networking: Dio with app-owned auth and error interceptors
- Persistence: Flutter Secure Storage for access token, refresh token, and expiry only
- Serialization: Handwritten immutable Dart models
- Backend auth pattern: JWT bearer access tokens plus refresh-token body refresh against `/auth/refresh`
- Shared OTP route: `/verify-otp` handles both registration verification and login 2FA completion through in-memory challenge state
- Forgot-password pattern: phone number only is stored in a short-lived in-memory challenge; OTP and passwords are never persisted
- Profile pattern: profile data is loaded from `/profile/me` and kept separate from session-token state
- Two-factor management: setup secrets and QR URIs remain in memory only until enable flow completion or screen disposal

## Stable conventions

- Keep business logic outside widget build methods.
- Keep authenticated child routes under the existing `/app/*` shell instead of creating a second scaffold or navigator.
- Do not duplicate selected-tab state when the route already identifies the active destination.
- Add or update tests for behavior changes.

## Error handling

- Error model: `AppFailure`
- Dio errors are normalized into user-safe failures before presentation
- Sensitive auth payloads, passwords, OTPs, tokens, and 2FA secrets must not be logged

## Security

- Environment configuration: `assets/env/.env.dev`, `.env.staging`, `.env.prod`
- Tokens are stored only in Flutter Secure Storage
- Passwords, OTPs, pre-auth 2FA tokens, and 2FA setup secrets are never persisted
- Login 2FA pre-auth tokens remain in Riverpod memory only until `/auth/2fa/login-verify` succeeds or the challenge is cleared

## Testing

- Unit and widget tests use `flutter_test`
- Mocking approach: small handwritten fakes and custom Dio adapters
- Widget test helpers live under `test/helpers/`

## Required validation

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```
