# Networking

## Current setup

- HTTP client: Dio
- Client creation location: `lib/core/network/network_providers.dart`
- Base URL configuration: validated `API_BASE_URL` from runtime env assets
- Android emulator dev base URL behavior: localhost hosts are rewritten to `10.0.2.2` so the emulator reaches the host backend without hard-coding emulator addresses in Dart source
- Authentication mechanism: bearer access token with refresh-token body refresh against `/auth/refresh`
- Serialization: handwritten JSON mapping for foundation and Phase 2.1 auth contracts
- Retry policy: one retry after a successful token refresh for eligible 401 responses
- Timeout policy: 30-second connect, send, and receive timeouts
- Dev localhost HTTPS behavior: the app-owned Dio clients allow localhost and `10.0.2.2` certificates only in `dev` flavor for local backend verification

## Boundary rules

- Widgets must not directly call concrete HTTP clients unless explicitly allowed by existing architecture.
- Keep transport DTOs at the data boundary.
- Map responses into project-owned models.
- Map transport errors into project-owned failures.
- Do not expose raw server exceptions to users.

## Requests

- Use configured timeouts.
- Validate required input before sending.
- Avoid logging secrets, authorization headers, cookies, or sensitive payloads.
- Safe dev diagnostics may log only request method, request path, HTTP status, and normalized backend error code.
- Use idempotency or duplicate-submission prevention where required.
- Encode query and path parameters safely.

## Responses

- Validate required response fields.
- Handle optional and backward-compatible fields safely.
- Treat malformed data as a controlled failure.
- Avoid unsafe casts from decoded JSON.

## Authentication

Document:

- Token storage: Flutter Secure Storage for access token, refresh token, and expiry only
- Auth endpoints currently modeled in Flutter: `POST /auth/login`, `POST /auth/register`, `POST /auth/verify-otp`, `POST /auth/logout`
- Additional auth endpoint currently modeled in Flutter: `POST /auth/2fa/login-verify`
- Auth data layer location: `lib/features/auth/data/`
- Login response contract: `accessToken`, `refreshToken`, `expiresAt`, `requiresTwoFactor`
- Verify OTP response contract: `accessToken`, `refreshToken`, `expiresAt`, `message`
- Login 2FA verify contract: request body `{ code }`, pre-auth bearer token in the `Authorization` header, and full token response `accessToken`, `refreshToken`, `expiresAt`, `message`
- Register and logout response contract: `message`
- Refresh flow: `POST /auth/refresh` with `{ refreshToken }`, update storage on success, clear session on failure
- Expiration behavior: session restoration attempts refresh when the stored expiry is in the past
- Logout cleanup: clear secure storage and session state even when the remote logout call fails
- Concurrent refresh behavior: one in-flight refresh is shared across concurrent eligible 401 responses
- OTP verification failure handling: backend envelopes such as `{ code, message, errors }`, `{ message }`, and malformed or empty error bodies are normalized into `AppFailure`

## Offline and retry behavior

- Offline strategy: no offline cache in Phase 1
- Retryable failures: only authenticated 401 responses after a successful refresh
- Maximum retries: one replay per request
- Backoff strategy: none in Phase 1
- User-visible retry behavior: presentation may expose explicit retry actions through shared error UI

Do not retry non-idempotent operations blindly.

## Testing

Networking tests should cover:

- Successful mapping
- Expected status failures
- Timeout or connectivity failure
- Malformed response
- Auth endpoint method, path, and body serialization
- Auth repository session persistence and local logout clearing
- Authentication expiration
- Retry behavior where configured
- Sensitive data not being logged

## Runtime verification notes

- Local backend listeners confirmed on 2026-07-29: `https://localhost:7145` and `http://localhost:5166`
- Confirmed mobile API base path in runtime traffic: `/api/auth/*`
- Confirmed live app requests on 2026-07-29: `POST /auth/register` and `POST /auth/login`
