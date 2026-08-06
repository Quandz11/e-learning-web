# Project State

Last updated: 2026-08-05

## Current objective

- Supported Phase 1 student authentication, forgot-password, profile, and 2FA flows are implemented on top of the existing app foundation.

## In progress

- No active implementation task recorded after the supported Phase 1 auth and profile slice.

## Completed recently

- Implemented public forgot-password routes at `/forgot-password` and `/forgot-password/verify` with Riverpod request/reset state, in-memory challenge handoff, OTP resend cooldown, and safe return to `/login`.
- Preserved the existing email login, registration, OTP verification, refresh, secure storage, and session-restoration foundation while adding safe redirect-path handoff for login 2FA completion.
- Replaced the authenticated `/app/profile` placeholder with a production-usable student profile overview backed by `GET /api/profile/me`.
- Added authenticated `/app/profile/edit`, `/app/profile/change-password`, and `/app/profile/security` routes under the existing shell without changing the four bottom-navigation destinations.
- Implemented profile update for `FullName`, `Phone`, and preserved `AvatarUrl` against `PUT /api/profile/me`.
- Implemented secure change-password submission against `POST /api/profile/change-password`.
- Implemented authenticated 2FA setup, enable, and disable UI against `/api/auth/2fa/setup`, `/api/auth/2fa/enable`, and `/api/auth/2fa/disable` without persisting setup secrets.
- Added focused widget regressions for the forgot-password entry screen and the profile overview, and updated existing auth and shell tests for the new Vietnamese UI and profile route behavior.

## Known failures

- Avatar selection and upload remain deferred because this phase does not introduce a file-picker dependency.
- Active session or device management remains deferred even though backend endpoints exist.
- Phone registration and phone-login flows remain deferred in mobile.

## Blockers

- None recorded.

## Technical debt

- Newly added auth and profile user-facing strings are still inline and should move into the project localization system in a later phase.
- Profile edit discard-confirmation and broader end-to-end auth/profile integration tests are still desirable follow-up work.

## Test status

- Formatting: Passed on 2026-08-05
- Analyzer: Passed on 2026-08-05
- Unit and widget tests: Passed on 2026-08-05
- Integration tests: Not added in this phase
- Runtime verification: Android emulator launch target `emulator-5554` was unavailable on 2026-08-05; desktop or web devices were available instead

## Next recommended actions

1. Add phone-registration and active-session flows only after product scope and mobile dependency constraints are explicitly approved.
2. Move new Vietnamese strings into the existing localization assets once translation workflow is resumed.
3. Add avatar selection and upload only after an approved image-picker capability is available in the repository.
