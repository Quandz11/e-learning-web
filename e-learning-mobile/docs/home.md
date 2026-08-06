# Home

## Scope

Phase 2 replaces only the authenticated `/app/home` placeholder.

Implemented sections:

- Personalized greeting with profile avatar
- Continue-learning summary from authenticated enrollments
- Three quick actions
- Featured published courses
- Active categories
- Recent public articles
- Compact active testimonials

Deferred:

- Full Learning experience
- Course detail
- Lesson playback
- Search and filters
- Article detail
- Checkout and payment

## Data ownership

- `features/home/data/home_api.dart` owns confirmed Home transport calls.
- `features/home/data/home_repository.dart` owns Home orchestration and continue-learning selection.
- `features/home/presentation/controllers/home_controller.dart` owns Home loading, refresh, retry, and primary-vs-optional failure state.
- `features/profile/presentation/controllers/profile_controller.dart` remains the only profile-state owner and is reused by the Home header.

## Endpoints used

- `GET /courses?isPublished=true`
- `GET /enrollments`
- `GET /categories/active`
- `GET /articles?page=1&pageSize=4`
- `GET /testimonials/active`
- `GET /profile/me` via existing profile feature reuse

## Continue-learning rule

- Use the most recently accessed incomplete active enrollment.
- Ignore completed or expired enrollments.
- Omit the section when no incomplete enrollment exists.
- Route the action to `/app/learning` until Learning detail routes exist.

## Partial failure behavior

- Featured published courses are the primary Home section.
- Optional enrollment, category, article, and testimonial failures stay local to their sections.
- Profile failure falls back to a generic Vietnamese greeting.
- Refresh keeps prior Home content visible and surfaces a retry message instead of replacing the screen with a blocking loader.

## Images

- Home cards use `cached_network_image` because it is already installed.
- Missing or failed remote images fall back to local icon placeholders.
- Relative image paths are resolved against the configured API base URL when possible.

## Routing

- Avatar → `/app/profile`
- Continue learning → `/app/learning`
- Quick actions → existing shell routes only
- Featured course card → `/app/learning`
- `Xem tất cả` → `/app/learning`
- Category chip → `/app/learning`

No new Home-owned route is introduced in Phase 2.
