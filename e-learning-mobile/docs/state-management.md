# State Management

## Current approach

- Library or pattern: Riverpod with `StateNotifierProvider`
- Provider or registration location: root app and `core/*` providers
- State model convention: immutable state classes with explicit restoring/authenticated/unauthenticated status plus feature-specific immutable controller state
- Side-effect convention: session restore and refresh happen in controllers/repositories, never in widget `build`
- Test override convention: provider overrides with `ProviderContainer`

## Principles

- Use the existing state-management approach.
- Keep one clear source of truth for each state.
- Keep state immutable when supported.
- Model meaningful states explicitly.
- Separate state transitions from widget rendering.
- Keep transient visual state local when appropriate.
- Do not perform side effects from widget `build` methods.

## Recommended state shape

Where applicable, represent:

- Initial or idle
- Loading
- Data or success
- Empty
- Validation failure
- Recoverable failure
- Terminal failure

Avoid multiple loosely related booleans that allow invalid combinations.

## Async operations

- Prevent duplicate concurrent submissions when required.
- Preserve previous data during refresh when product behavior expects it.
- Handle cancellation and disposal.
- Map infrastructure errors into project-owned failures.
- Expose user-safe error information to presentation.

Current login behavior:

- `loginControllerProvider` owns login submission, validation, failure mapping, and 2FA-required state.
- `SessionController` remains the single app-wide session source of truth.
- `bootstrapAndRun()` drives the visible startup phase from one async bootstrap future and does not introduce another session-restoration source of truth.
- Successful normal login synchronizes `SessionController` from the repository result without writing secure storage a second time.
- Login widgets keep transient text-editing and password-visibility state locally.
- `registerControllerProvider` owns registration submission, local field validation, backend field-error mapping, duplicate-submit prevention, and submitted-email handoff state.
- Registration success does not write session state because backend signup returns only a message and requires OTP verification later.
- `authOtpChallengeControllerProvider` owns the temporary OTP challenge for registration verification and login two-factor completion and keeps login pre-auth tokens in memory only.
- `verifyOtpControllerProvider` owns OTP validation, submit-once behavior, backend failure mapping, session synchronization after successful verification, and challenge cleanup.
- Successful OTP verification is the first point where registration or login-2FA flows may update `SessionController` and create a persisted authenticated session.
- Unexpected secure-storage or restore failures fall back to `SessionState.unauthenticated()` after a best-effort clear instead of aborting startup.

## UI integration

Widgets should:

- Watch only the state they need.
- Trigger actions through the existing controller or notifier boundary.
- Avoid direct API or database access.
- Render all expected states.
- Avoid repeated side effects caused by rebuilds.

## Testing

State tests should cover:

- Initial state
- Successful transition
- Validation failure
- Infrastructure failure mapping
- Retry or refresh behavior
- Duplicate action prevention when relevant
- Disposal or cancellation behavior when relevant
- Distinct two-factor-required behavior when the backend reports pre-auth login completion
- Registration success without session authentication when the backend returns only a message
- OTP verification success for both registration and login 2FA
- OTP verification failure, invalid challenge handling, and challenge cleanup after success or explicit return to login
- Safe fallback to unauthenticated state when session restore or storage reads fail unexpectedly
