# Project State

Last updated: 2026-09-09

## Current objective

- Phase 4 Media Player, Document Reader, and Learning UI is implemented on top of the completed auth/profile, Home, Learning catalog, course detail, lesson, and progress foundations.

## In progress

- No active implementation task recorded after the Phase 4 media/document slice.

## Completed recently

- Redesigned only the public login and registration screens to use a branded wellness-style auth surface with decorative leaves, warm backgrounds, rounded inputs, and scroll-safe responsive layouts.
- Preserved the existing login, register, OTP, forgot-password, 2FA handoff, refresh, session-restoration, and authenticated redirect behavior while modernizing the auth presentation.
- Updated auth widget regressions to cover the new branded layouts, hidden unsupported social-login options, scrollable narrow-screen behavior, and navigation between login and registration.
- Replaced the authenticated `/app/home` placeholder with a production-usable Home screen that reuses profile state for the personalized greeting header.
- Implemented confirmed Home loading for `GET /courses?isPublished=true`, `GET /enrollments`, `GET /categories/active`, `GET /articles?page=1&pageSize=4`, and `GET /testimonials/active`.
- Added Home API, repository, controller, widget, and shell regressions covering loading, partial failure isolation, refresh, navigation, and responsive behavior.
- Implemented public forgot-password routes at `/forgot-password` and `/forgot-password/verify` with Riverpod request/reset state, in-memory challenge handoff, OTP resend cooldown, and safe return to `/login`.
- Preserved the existing email login, registration, OTP verification, refresh, secure storage, and session-restoration foundation while adding safe redirect-path handoff for login 2FA completion.
- Replaced the authenticated `/app/profile` placeholder with a production-usable student profile overview backed by `GET /api/profile/me`.
- Added authenticated `/app/profile/edit`, `/app/profile/change-password`, and `/app/profile/security` routes under the existing shell without changing the four bottom-navigation destinations.
- Implemented profile update for `FullName`, `Phone`, and preserved `AvatarUrl` against `PUT /api/profile/me`.
- Implemented secure change-password submission against `POST /api/profile/change-password`.
- Implemented authenticated 2FA setup, enable, and disable UI against `/api/auth/2fa/setup`, `/api/auth/2fa/enable`, and `/api/auth/2fa/disable` without persisting setup secrets.
- Added focused widget regressions for the forgot-password entry screen and the profile overview, and updated existing auth and shell tests for the new Vietnamese UI and profile route behavior.
- Replaced the authenticated `/app/learning` placeholder with a production-usable Learning screen that loads confirmed backend course, enrollment, and category contracts.
- Added Learning API, repository, controller, and widget layers using the existing Dio API client, `AppFailure` mapping, Riverpod state ownership, cached image handling, and shared visual components.
- Preserved the existing App Shell, four bottom-navigation destinations, route-driven selected-tab state, authentication redirects, Profile routes, Home route, and payment callback routes.
- Added Learning regressions for direct-list API parsing, nullable fields, malformed responses, optional-section failure isolation, refresh, empty states, image fallback, responsive layout, dark mode, and `/app/learning` tab selection.
- Added `/app/learning/course/:courseId` course detail routing under the existing authenticated shell without adding a bottom-navigation destination.
- Added `/app/learning/course/:courseId/lesson/:lessonPartId` lesson routing under the existing authenticated Learning destination.
- Implemented course detail loading from `GET /api/courses/{id}` with embedded backend lesson and lesson-part data.
- Implemented learning progress loading from `GET /api/enrollments/{courseId}/progress`, with preview lessons still viewable when authenticated progress is unavailable.
- Implemented lesson completion through `POST /api/enrollments/{courseId}/lessons/{lessonPartId}/complete` and reloads backend-confirmed progress after success.
- Added Phase 4 API, repository, controller, route, and widget regressions for course detail, lesson detail, progress parsing, access handling, completion, nested routing, responsive layout, and retained content on refresh.
- Added a direct `video_player` dependency for the existing transitive player package so the app can import it safely and play backend-provided lesson playback URLs.
- Implemented authenticated media and document child routes under `/app/learning/course/:courseId/lesson/:lessonPartId`.
- Added native Flutter chrome for lesson video playback with loading, retry, buffering, controls, scrubbing, and duration formatting.
- Added document reading through the existing WebView dependency using backend-provided document URLs with JavaScript disabled and safe invalid-URL handling.
- Added previous/next lesson-part stack navigation inside `LessonScreen` without introducing nested navigation or duplicate selected-tab state.

## Known failures

- Enrollment purchase flow, checkout, payment result handling, orders, and refunds remain intentionally deferred.
- Android WebView PDF rendering remains platform/CDN dependent because no compatible direct PDF viewer package is installed for the current Flutter/iOS baseline.
- Search, filters, category filtering, and pagination are not implemented because the confirmed Phase 3 backend contracts do not expose those behaviors for the mobile catalog.
- Article detail remains intentionally deferred; Home routes article-related actions only to approved existing destinations.
- Avatar selection and upload remain deferred because this phase does not introduce a file-picker dependency.
- Active session or device management remains deferred even though backend endpoints exist.
- Phone registration and phone-login flows remain deferred in mobile.

## Blockers

- None recorded.

## Technical debt

- Newly added auth and profile user-facing strings are still inline and should move into the project localization system in a later phase.
- Profile edit discard-confirmation and broader end-to-end auth/profile integration tests are still desirable follow-up work.

## Test status

- Formatting: `dart format --output=none --set-exit-if-changed .` passed on 2026-09-09 after Phase 4 media/document
- Analyzer: `flutter analyze` passed on 2026-09-09 after Phase 4 media/document
- Unit and widget tests: `flutter test` passed on 2026-09-09 after Phase 4 media/document
- Integration tests: Not added in this phase
- Runtime verification: `flutter run -d emulator-5554 --no-resident` launched on 2026-09-08; Home, Learning, course detail, and lesson screens were visually checked from emulator screenshots

## Next recommended actions

1. Build checkout, enrollment purchase, payment result, orders, and refunds only after Phase 5 scope and backend contracts are approved.
2. Move new Vietnamese strings into the existing localization assets once translation workflow is resumed.
3. Add avatar selection and upload only after an approved image-picker capability is available in the repository.


