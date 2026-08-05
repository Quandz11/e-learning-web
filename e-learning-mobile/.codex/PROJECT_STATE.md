# Project State

Last updated: 2026-07-30

## Current objective

- Production startup and splash experience implemented on top of the completed auth, registration, OTP, and authenticated shell foundation

## In progress

- No active implementation task recorded after authenticated shell navigation modernization

## Completed recently

- Implemented Phase 1 app foundation from the current worktree only
- Replaced stale pre-rebuild tests with a deterministic foundation test suite
- Implemented handwritten auth request and response models, auth API parsing, and auth repository session persistence behavior
- Implemented login state, login UI, `/login` routing, and deterministic login controller and widget tests
- Implemented registration state, registration UI, `/register` routing, and deterministic registration controller and widget tests
- Replaced the old `/verify-otp` placeholder with a real OTP verification screen for both registration and login 2FA completion
- Implemented centralized Material 3 light and dark themes with small spacing, radius, size, and typography token sets
- Added shared buttons, text fields, cards, page layout, section headers, avatars, badges, skeletons, and refined loading/error/empty views
- Added a debug-only `/dev/components` showcase route and migrated login and registration screens to the shared design system without changing auth behavior
- Implemented an authenticated `AppShell` with `NavigationBar` destinations for Home, Learning, Community, and Profile
- Replaced the old protected placeholder route behavior with shell-based `/app/home`, `/app/learning`, `/app/community`, and `/app/profile` placeholders
- Modernized the authenticated shell navigation surface with a compact Material 3 `NavigationBar`, Vietnamese destination labels, route-driven indicator styling, bottom safe-area handling, and regression coverage for light/dark themes plus accessibility-scaled text
- Implemented shared OTP challenge state, OTP verification submission, login 2FA completion, authenticated-session creation after successful OTP verification, and deterministic OTP controller/widget/router/startup regressions
- Confirmed live Android-emulator auth runtime against the local backend on 2026-07-29 for app startup, registration endpoint reachability, normal login, session restoration after restart, and logout clearing behavior
- Implemented a themed Flutter startup host that renders immediately, keeps config/session restoration outside the router until settled, and transitions once into either `/login`, `/app/home`, or the startup failure screen
- Changed the router initial location to `/app` so route guards resolve from the protected root after startup without temporary login or shell flicker
- Added deterministic startup widget, bootstrap, router, and session-restore failure regressions plus Android/iOS launch-screen tinting to reduce white-flash risk

## Known failures

- Registration creates a backend user and OTP, but the in-app handoff to `/verify-otp` was not completed during live emulator verification
- Live login against a newly registered local account requires the backend user row to be both verified and `Status = ACTIVE`
- Azure-authenticated startup restoration was not reverified on 2026-07-30 because no non-secret Azure test credentials were available in the repository context

## Blockers

- None recorded.

## Technical debt

- OTP resend UX, nested shell feature routes, real feature flows, checkout business logic, realtime, and push flows are intentionally deferred

## Test status

- Formatting: Passed on 2026-07-30
- Analyzer: Passed on 2026-07-30
- Unit and widget tests: Passed on 2026-07-30
- Integration tests: Not added in Phase 1
- APK debug build: Passed on 2026-07-30
- Live emulator verification on 2026-07-30: startup still launches on Android emulator; authenticated shell visual verification depends on an already authenticated session because this task did not add API work or auth bypasses

## Next recommended actions

1. Implement resend-OTP UX only after product copy, limits, and cooldown requirements are confirmed.
2. Reverify valid-session startup and post-logout restart against the Azure environment when a non-secret test account is available.
3. Build real feature UI inside the existing shell destinations without adding duplicate tab state.
