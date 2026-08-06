# AI-Assisted Change Log

Keep entries concise. Do not paste full diffs, logs, or private reasoning.

## Entry template

### YYYY-MM-DD — Short task title

- Implemented:
- Changed:
- Tests:
- Validation:
- Remaining risk:

---

2026-08-05 - Implemented supported Phase 1 auth and profile flows.

- Implemented: forgot-password by phone OTP, profile overview, edit profile, change password, authenticated 2FA setup/enable/disable UI, and safe login 2FA redirect completion.
- Changed: GoRouter now includes `/forgot-password`, `/forgot-password/verify`, `/app/profile/edit`, `/app/profile/change-password`, and `/app/profile/security`; `/app/profile` is backed by a real profile screen instead of a placeholder.
- Tests: updated existing login/register/OTP/shell regressions and added focused widget coverage for forgot-password and profile overview.
- Validation: `flutter pub get`, `flutter analyze`, and `flutter test` passed on 2026-08-05; format check passed after formatting the changed test files; `flutter run -d emulator-5554` could not run because that device was unavailable.
- Remaining risk: avatar upload, phone registration, phone login, and session-management UI remain intentionally deferred.

---

2026-08-06 - Implemented authenticated Phase 2 Home.

- Implemented: `/app/home` now shows a personalized greeting, continue-learning summary, three quick actions, featured published courses, active categories, recent public articles, and a compact testimonials section.
- Changed: added the Home API/repository/controller slice, reused `ProfileController` for header state, and preserved existing shell-only navigation for Home actions.
- Tests: added Home API, repository, controller, and widget coverage; updated shell regressions so `/app/home` resolves to the real Home screen.
- Validation: `flutter pub get`, `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, and `flutter test` passed on 2026-08-06; `flutter run -d emulator-5554` launched successfully on the available emulator, but terminal-only execution did not provide direct visual confirmation of the rendered UI.
- Remaining risk: Learning detail routes, article detail, and checkout remain intentionally deferred, and direct visual runtime verification is still unconfirmed from terminal output alone.

---

2026-08-06 - Redesigned login and registration screens.

- Implemented: a branded wellness-style auth surface for `/login` and `/register` with decorative leaves, warm background treatment, rounded inputs, and updated Vietnamese layout copy.
- Changed: preserved the existing auth controllers, routes, OTP handoff, forgot-password path, and session behavior while replacing only the login and registration presentation widgets.
- Tests: updated login and registration widget coverage for the new layouts, hidden unsupported social-login options, responsive scrolling, validation, loading, and cross-route navigation.
- Validation: `flutter pub get`, `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, and `flutter test` passed on 2026-08-06; `flutter run -d emulator-5554` was attempted twice and timed out before direct visual inspection could be confirmed.
- Remaining risk: runtime visual verification against the emulator is still pending direct inspection, and the refreshed auth UI was not manually compared on-device from within the CLI session.
