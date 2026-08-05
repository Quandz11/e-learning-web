# AI-Assisted Change Log

Keep entries concise. Do not paste full diffs, logs, or private reasoning.

## Entry template

### YYYY-MM-DD â€” Short task title

- Implemented:
- Changed:
- Tests:
- Validation:
- Remaining risk:

---

No entries yet.
2026-07-29 - Implemented Phase 1 Flutter foundation with validated runtime config, secure session storage, session restoration, Dio auth refresh handling, GoRouter placeholders, shared state widgets, and deterministic foundation tests.
2026-07-29 - Implemented Phase 2.1 auth data layer with handwritten auth DTOs, endpoint-specific Dio parsing, repository-backed session persistence for login and OTP verification, and deterministic auth API/repository tests.
2026-07-29 - Implemented Phase 2.2 login with Riverpod controller state, `/login` routing, 2FA-preauth handling without OTP UI, and deterministic login controller/widget/router regressions.
2026-07-29 - Implemented Phase 2.3 registration with Riverpod form state, `/register` routing, OTP-placeholder handoff after successful signup, and deterministic registration controller/widget/router regressions.
2026-07-29 - Implemented Phase 2.4 OTP verification with a shared `/verify-otp` screen for registration and login 2FA, in-memory OTP challenge state, authenticated session creation only after successful OTP verification, and deterministic auth/router/startup/widget regressions.
2026-07-29 - Implemented UI Phase 1 design foundation with centralized Material 3 light/dark themes, shared design tokens and widgets, a debug-only component showcase route, and widget regressions for shared UI plus auth screens.
2026-07-29 - Implemented UI Phase 2 authenticated app shell with four bottom-navigation destinations, shell-based `/app/*` routing, lightweight placeholder screens, and deterministic shell/router regressions.
2026-07-29 - Added Android-emulator localhost/TLS dev transport support, safe auth diagnostics, a profile logout action, and auth runtime regression fixes for registration/query OTP handoff while confirming live startup, login, session restore, and logout behavior against the local backend.
2026-07-30 - Implemented a production startup experience with an immediate themed Flutter bootstrap host, single-transition session restoration, protected-root router startup, startup widget/session/router regressions, and Android/iOS launch-screen tint updates.
2026-07-30 - Modernized the authenticated app shell navigation with a compact Material 3 bottom bar, Vietnamese labels, pill indicator styling, safe-area treatment, and expanded shell widget regressions without changing `/app/*` routing behavior.
