# Navigation

## Current setup

- Router library: GoRouter.
- Router configuration location: `lib/core/routing/app_router.dart`.
- Route naming convention: path constants and builders in `lib/core/routing/deep_link_config.dart`.
- Authentication guards: redirect based on session restoration and authenticated state.
- Deep-link support: payment return and cancel callbacks plus documented payment return aliases.

## Rules

- Use the existing router and route declaration style.
- Do not introduce direct `Navigator` calls when the project consistently uses a router abstraction.
- Keep route arguments typed where supported and validate external path parameters.
- Avoid passing sensitive information in route URLs.
- Preserve browser and system back behavior.
- Keep navigation side effects outside widget `build`.
- Keep the App Shell as the only authenticated shell scaffold owner.

## Authentication and authorization

- The router starts from `/app` so startup can resolve into the protected root after session restoration settles.
- A separate bootstrap host shows the startup screen before `MaterialApp.router` is mounted, preventing temporary login or shell content during initialization.
- Unauthenticated users are redirected from `/app` and `/app/*` routes to `/login`.
- Unauthenticated users may open `/login`, `/register`, `/forgot-password`, and valid challenge-backed verification routes.
- Authenticated users are redirected away from public auth routes to a safe `/app/*` destination or `/app/home`.
- Redirects pause while the session is restoring to avoid loops.
- Payment callback routes remain publicly reachable placeholders.

## Current route map

- `/welcome` remains a public placeholder route.
- `/login` hosts the login screen.
- `/register` hosts the registration screen.
- `/verify-otp` hosts the shared OTP verification screen for registration completion and login 2FA completion.
- `/forgot-password` hosts the phone-based forgot-password request screen.
- `/forgot-password/verify` hosts the phone OTP plus new-password verification screen.
- `/dev/components` is available only in debug builds for internal component verification and is not linked from product navigation.
- `/app` redirects authenticated traffic to `/app/home`.
- `/app/home` hosts the Home screen.
- `/app/learning` hosts the Learning catalog screen.
- `/app/learning/course/:courseId` hosts authenticated course detail under the Learning shell destination.
- `/app/learning/course/:courseId/lesson/:lessonPartId` hosts authenticated lesson-part detail under the Learning shell destination.
- `/app/learning/course/:courseId/lesson/:lessonPartId/media` hosts authenticated lesson video playback under the Learning shell destination.
- `/app/learning/course/:courseId/lesson/:lessonPartId/document` hosts authenticated lesson document reading under the Learning shell destination.
- `/app/community` remains an authenticated placeholder destination.
- `/app/profile` hosts the authenticated profile overview.
- `/app/profile/edit`, `/app/profile/change-password`, and `/app/profile/security` are authenticated child routes under the `Cá nhân` shell destination.

## Authenticated shell

- The app shell uses GoRouter shell-based routing with a persistent `NavigationBar`.
- The current route location is the only source of truth for the selected bottom-navigation destination.
- The authenticated shell keeps exactly four destinations: `Trang chủ`, `Học tập`, `Cộng đồng`, and `Cá nhân`.
- Learning child routes under `/app/learning/...`, including media and document child routes, keep `Học tập` selected in the bottom navigation.
- Profile child routes under `/app/profile/...` keep `Cá nhân` selected in the bottom navigation.
- The shell navigation surface is a compact Material 3 bar rendered by the shell scaffold itself, with rounded top treatment, theme-derived container colors, and a pill-shaped selected indicator.
- The shell must preserve safe bottom insets and back-button return from non-home tabs to `/app/home`.
- Do not store duplicate selected-tab state in Riverpod or local widget state when the router location already identifies the active tab.

## Deep links

- Supported schemes and domains: `skvi`, `skvi-dev`, `skvi-staging`, `nhinanchualanh.vn`, `www.nhinanchualanh.vn`.
- Unknown link behavior: unresolved links fall through to the unknown-route screen.
- Required validation: runtime callback URLs are validated at startup and external payment callback links are normalized before route matching.

## Testing

Navigation tests should cover:

- Expected destination and required arguments.
- Authentication redirects and redirect-loop prevention.
- Unknown routes and payment callback normalization.
- Successful login transition from `/login` to the protected route.
- Registration and login two-factor handoff to `/verify-otp` without persisting a partial session.
- `/verify-otp` redirect protection when the OTP challenge is missing or the user is already authenticated.
- Direct authenticated route resolution for `/app/home`, `/app/learning`, `/app/community`, and `/app/profile`.
- Direct authenticated route resolution for `/app/learning/course/:courseId`, `/app/learning/course/:courseId/lesson/:lessonPartId`, `/media`, and `/document` child routes.
- Learning child routes keeping the `Học tập` shell destination selected.
- Profile child routes keeping the `Cá nhân` shell destination selected.
- Back-button behavior from non-home shell tabs to `/app/home`.
- Shell styling regressions for the rounded Material 3 container, visible selected indicator, and distinct unselected destinations.
