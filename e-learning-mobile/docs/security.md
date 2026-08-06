# Security

## Principles

- Never commit secrets, credentials, private keys, signing files, production tokens, or sensitive environment values.
- Treat all external input as untrusted.
- Minimize collection, storage, and logging of personal data.
- Use platform secure storage for sensitive client-side values when required.
- Enforce authorization on the server; client checks are user experience controls, not security boundaries.

## Secrets and configuration

Document:

- Environment mechanism: runtime `.env` assets selected by app flavor
- Secret injection process: backend secrets are not stored in Flutter env assets
- Local development setup: local env assets may include non-secret mobile runtime values only
- CI secret source: TODO

Safe repository files may contain example placeholders only.

## Authentication

- Avoid storing passwords.
- Protect tokens using the approved storage mechanism.
- Clear credentials and sensitive cached state on logout.
- Handle token refresh without exposing tokens in logs.
- Avoid duplicate refresh races.
- Treat session expiration explicitly.
- Do not persist a full authenticated session from login when the backend reports `requiresTwoFactor == true`.

## Data protection

- Do not log personal or sensitive payloads.
- Redact identifiers where possible.
- Avoid unnecessary local persistence.
- Define data deletion behavior.
- Encrypt sensitive data in transit and use trusted TLS configuration.

Current Phase 1 storage and transport rules:

- Tokens are stored only in Flutter Secure Storage.
- Passwords are never stored.
- Refresh failures clear local session state.
- Bearer tokens are injected at request time and are not logged.
- Development-only localhost certificate bypass is limited to localhost and `10.0.2.2` hosts in `dev` flavor.
- Development diagnostics log only method, path, status, and normalized backend code; they do not log passwords, OTPs, tokens, or authorization headers.

Current Phase 2.2 login rules:

- Login trims surrounding email whitespace before request serialization and leaves passwords untouched.
- Login validation remains lightweight on-device; backend validation remains authoritative.
- Backend `requiresTwoFactor` login responses are surfaced to UI as a distinct pre-auth state and do not mark the app session authenticated.
- Login pre-auth access tokens for 2FA completion are kept only in Riverpod memory until `/auth/2fa/login-verify` succeeds.

Current Phase 2.3 registration rules:

- Registration trims surrounding whitespace for `fullName`, `email`, `phone`, and `referralCode`, while leaving passwords untouched.
- Registration performs only lightweight client validation and preserves backend authority for business validation and normalization.
- Registration success does not persist tokens or mark the app session authenticated because backend signup returns only a message and requires OTP verification later.
- Registration UI surfaces normalized field-level and general failures without exposing raw Dio exceptions or server stack traces.

Current Phase 2.4 OTP rules:

- Registration OTP verification and login 2FA share the same `/verify-otp` route but use distinct confirmed backend endpoints.
- OTP success is the first point where full auth tokens may be persisted for registration verification or login 2FA completion.
- The app clears temporary OTP challenge state after successful verification or explicit return to login.
- The app does not persist partial auth state when OTP verification fails, the challenge is malformed, or the backend rejects the code.

Current supported Phase 1 recovery and profile rules:

- Forgot-password challenge state stores only the normalized phone number required for the active reset flow.
- Forgot-password routes never place phone numbers, OTP values, or passwords into query parameters.
- Profile updates submit only `fullName`, `phone`, and the preserved backend `avatarUrl`.
- Change-password requests submit only `currentPassword` and `newPassword`.
- Authenticated 2FA setup secrets and QR URIs remain in memory only and are cleared when the security screen is disposed or the enable flow succeeds.
- The app does not add avatar selection or upload in this phase because no approved mobile picker capability is present in the repository.

Current live-backend auth findings on 2026-07-29:

- Backend login rejects users that are not both verified and `ACTIVE`.
- Registration creates an OTP for later verification and does not create an authenticated mobile session by itself.

## Input and output safety

- Validate user and external input.
- Encode values appropriately for URLs and serialization.
- Avoid rendering unsafe remote HTML without a controlled sanitizer and clear product need.
- Validate file types, sizes, and names for uploads.
- Do not trust client-side authorization flags.

## Platform configuration

Review platform changes for:

- Android exported components
- Android permissions
- Network security configuration
- iOS entitlements
- iOS URL schemes
- Keychain usage
- Deep-link validation
- Backup behavior

Current Phase 1 platform considerations:

- Android deep-link schemes and verified payment return hosts are declared in the manifest.
- iOS custom URL schemes and remote-notification background mode are present in `Info.plist`.
- No Firebase, SignalR, WebView, or HTML rendering initialization is performed in Phase 1.

## Dependencies

Before adding or upgrading security-sensitive dependencies:

- Check maintenance status.
- Check compatibility.
- Review known advisories.
- Minimize permissions and transitive dependencies.

## Security review checklist

- No secrets in diff
- No sensitive logging
- Inputs validated
- Errors user-safe
- Authorization assumptions documented
- Storage appropriate for sensitivity
- Platform permissions minimal
- Tests cover failure and expiration paths
