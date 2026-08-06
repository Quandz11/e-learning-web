# Navigation

## Current setup

- Router library: GoRouter
- Router configuration location: `lib/core/routing/app_router.dart`
- Route naming convention: path constants in `lib/core/routing/deep_link_config.dart`
- Authentication guards: redirect based on session restoration and authenticated state
- Deep-link support: payment return and cancel callbacks plus documented payment return aliases

## Rules

- Use the existing router and route declaration style.
- Do not introduce direct `Navigator` calls when the project consistently uses a router abstraction.
- Keep route arguments typed where supported.
- Validate external deep-link input.
- Avoid passing sensitive information in route URLs.
- Preserve browser and system back behavior.
- Keep navigation side effects outside widget `build`.

## Authentication and authorization

Document:

- Unauthenticated entry behavior
- Protected routes
- Role or permission checks
- Redirect loops prevention
- Session expiration behavior

Current behavior: TODO
Current behavior:

- The router starts from `/app` so startup can resolve into the protected root after session restoration settles.
- A separate bootstrap host shows the startup screen before `MaterialApp.router` is mounted, preventing temporary login or shell content during initialization.
- Unauthenticated users are redirected from `/app` and `/app/*` routes to `/login`.
- Unauthenticated users may open `/login`.
- Unauthenticated users may open `/register`.
- Unauthenticated users may open `/forgot-password`.
- Unauthenticated users may open `/forgot-password/verify` only when the app holds a valid in-memory forgot-password challenge or a typed route extra carries one for the initial handoff.
- Unauthenticated users may open `/verify-otp` only when the app holds a valid in-memory OTP challenge or a route extra carries one for the initial handoff.
- Authenticated users are redirected away from `/login` to the safe intended `/app/*` destination when present, otherwise `/app/home`.
- Authenticated users are redirected away from `/register` to `/app/home`.
- Authenticated users are redirected away from forgot-password routes to `/app/home`.
- Authenticated users are redirected away from `/verify-otp` to `/app/home`.
- Authenticated users are redirected from the public welcome route to `/app/home`.
- Redirects pause while the session is restoring to avoid loops.
- Payment callback routes remain publicly reachable placeholders.

Current auth-route map:

- `/welcome` remains a public placeholder route.
- `/login` hosts the Phase 2.2 login screen.
- `/register` hosts the Phase 2.3 registration screen.
- `/verify-otp` hosts the shared OTP verification screen for registration completion and login 2FA completion.
- `/forgot-password` hosts the phone-based forgot-password request screen.
- `/forgot-password/verify` hosts the phone OTP plus new-password verification screen.
- `/dev/components` is available only in debug builds for internal component verification and is not linked from product navigation.
- `/app` redirects authenticated traffic to `/app/home`.
- `/app/home` hosts the Phase 2 Home screen.
- `/app/learning`, `/app/community`, and `/app/profile` remain the other authenticated shell destinations.
- `/app/profile/edit`, `/app/profile/change-password`, and `/app/profile/security` are authenticated child routes under the `Cá nhân` shell destination.

## Authenticated shell

- The app shell uses GoRouter shell-based routing with a persistent `NavigationBar`.
- The current route location is the only source of truth for the selected bottom-navigation destination.
- The authenticated shell keeps exactly four destinations: `Trang chủ`, `Học tập`, `Cộng đồng`, and `Cá nhân`.
- The shell navigation surface is a compact Material 3 bar rendered by the shell scaffold itself, with rounded top treatment, theme-derived container colors, and a pill-shaped selected indicator.
- The shell must preserve safe bottom insets and back-button return from non-home tabs to `/app/home`.
- Home-level navigation continues to target only existing shell destinations until dedicated Learning and article-detail routes are implemented.
- Future nested routes should be added under the existing `/app/<tab>/...` path structure where practical.
- Profile child routes under `/app/profile/...` keep `Cá nhân` selected in the bottom navigation.
- Do not store duplicate selected-tab state in Riverpod or local widget state when the router location already identifies the active tab.

## Deep links

- Supported schemes and domains: `skvi`, `skvi-dev`, `skvi-staging`, `nhinanchualanh.vn`, `www.nhinanchualanh.vn`
- Unknown link behavior: unresolved links fall through to the unknown-route screen
- Required validation: runtime callback URLs are validated at startup and external payment callback links are normalized before route matching

## Testing

Navigation tests should cover:

- Expected destination
- Required arguments
- Authentication redirects
- Back behavior
- Unknown routes
- Deep-link parsing where supported
- Successful login transition from `/login` to the protected route
- Registration transition from `/register` to the `/verify-otp` placeholder without creating a session
- Registration and login two-factor handoff to `/verify-otp` without persisting a partial session
- `/verify-otp` redirect protection when the OTP challenge is missing or the user is already authenticated
- Direct authenticated route resolution for `/app/home`, `/app/learning`, `/app/community`, and `/app/profile`
- Back-button behavior from non-home shell tabs to `/app/home`
- Shell styling regressions for the rounded Material 3 container, visible selected indicator, and distinct unselected destinations
- Bootstrap transition from the startup host into `/login` or `/app/home` without route flicker
