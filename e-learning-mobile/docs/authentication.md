# Authentication

## Implemented mobile flows

- Email login using `/auth/login`
- Registration handoff to `/verify-otp`
- Shared OTP verification for registration and login 2FA
- Forgot-password by phone OTP using `/auth/phone/request-forgot-password-otp`, `/auth/phone/resend-forgot-password-otp`, and `/auth/phone/verify-forgot-password-otp`
- Authenticated 2FA setup, enable, and disable using `/auth/2fa/setup`, `/auth/2fa/enable`, and `/auth/2fa/disable`
- Logout using the existing auth repository and secure-session cleanup

## State ownership

- `SessionController` is the only authoritative session-token owner.
- `AuthOtpChallengeController` keeps the temporary registration or login-2FA challenge in memory only.
- `ForgotPasswordChallengeController` keeps only the phone number for an active password-reset challenge in memory.
- Widgets do not call Dio or secure storage directly.

## Redirect behavior

- Unauthenticated `/app` and `/app/*` routes redirect to `/login`.
- `/login` preserves a safe `from` destination under `/app/*`.
- Successful login 2FA verification returns to the safe intended destination when present.
- `/forgot-password` and `/forgot-password/verify` remain public and outside the authenticated shell.
- `/verify-otp` requires an active in-memory challenge or an initial typed route handoff.

## Sensitive-data handling

- Access tokens, refresh tokens, and expiry are stored only in secure storage.
- Passwords, OTP values, pre-auth tokens, and 2FA setup secrets are never persisted.
- 2FA setup secrets and QR URIs are cleared from state on disposal or after successful enablement.
- The app does not log passwords, OTPs, tokens, or 2FA secrets.

## Deferred work

- Phone registration
- Phone login
- Active session or device-management UI
- Avatar file selection and upload
