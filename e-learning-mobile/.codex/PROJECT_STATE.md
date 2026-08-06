# Project State

Last updated: 2026-08-06

## Current objective

- Phase 2 authenticated Home is implemented on top of the completed Phase 1 auth/profile foundation.

## In progress

- No active implementation task recorded after the Phase 2 Home slice.

## Completed recently

- Redesigned only the public login and registration screens to use a branded wellness-style auth surface with decorative leaves, warm backgrounds, rounded inputs, and scroll-safe responsive layouts.
- Preserved the existing login, register, OTP, forgot-password, 2FA handoff, refresh, session-restoration, and authenticated redirect behavior while modernizing the auth presentation.
- Updated auth widget regressions to cover the new branded layouts, hidden unsupported social-login options, scrollable narrow-screen behavior, and navigation between login and registration.
- Replaced the authenticated `/app/home` placeholder with a production-usable Home screen that reuses profile state for the personalized greeting header.
- Implemented confirmed Home loading for `GET /courses?isPublished=true`, `GET /enrollments`, `GET /categories/active`, `GET /articles?page=1&pageSize=4`, and `GET /testimonials/active`.
- Added Home API, repository, controller, widget, and shell regressions covering loading, partial failure isolation, refresh, navigation, and responsive behavior.
- Implemented public forgot-password routes at `/forgot-password` and `/forgot-password/verify` with Riverpod request/reset state, in-memory challenge handoff, OTP resend cooldown, and safe return to `/login`.
- Preserved the existing email login, registration, OTP verification, refresh, secure storage, and session-restoration foundation while adding safe redirect-path handoff for login 2FA completion.
- Replaced the authenticated `/app/profile` placeholder with a production-usable student profile overview backed by `GET /api/profile/me`.
- Added authenticated `/app/profile/edit`, `/app/profile/change-password`, and `/app/profile/security` routes under the existing shell without changing the four bottom-navigation destinations.
- Implemented profile update for `FullName`, `Phone`, and preserved `AvatarUrl` against `PUT /api/profile/me`.
- Implemented secure change-password submission against `POST /api/profile/change-password`.
- Implemented authenticated 2FA setup, enable, and disable UI against `/api/auth/2fa/setup`, `/api/auth/2fa/enable`, and `/api/auth/2fa/disable` without persisting setup secrets.
- Added focused widget regressions for the forgot-password entry screen and the profile overview, and updated existing auth and shell tests for the new Vietnamese UI and profile route behavior.

## Known failures

- Full Learning, course detail, article detail, lesson playback, and checkout remain intentionally deferred; Home routes those actions to `/app/learning`.
- Avatar selection and upload remain deferred because this phase does not introduce a file-picker dependency.
- Active session or device management remains deferred even though backend endpoints exist.
- Phone registration and phone-login flows remain deferred in mobile.

## Blockers

- None recorded.

## Technical debt

- Newly added auth and profile user-facing strings are still inline and should move into the project localization system in a later phase.
- Profile edit discard-confirmation and broader end-to-end auth/profile integration tests are still desirable follow-up work.

## Test status

- Formatting: `dart format --output=none --set-exit-if-changed .` passed on 2026-08-06
- Analyzer: `flutter analyze` passed on 2026-08-06
- Unit and widget tests: `flutter test` passed on 2026-08-06
- Integration tests: Not added in this phase
- Runtime verification: the auth UI refresh completed required `flutter run -d emulator-5554` attempts on 2026-08-06, but both CLI launches timed out before direct visual inspection could be confirmed

## Next recommended actions

1. Build the Learning experience only after Phase 3 route and screen scope are explicitly approved.
2. Move new Vietnamese strings into the existing localization assets once translation workflow is resumed.
3. Add avatar selection and upload only after an approved image-picker capability is available in the repository.
