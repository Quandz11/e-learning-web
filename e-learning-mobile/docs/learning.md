# Learning

## Scope

- `/app/learning` is the authenticated Learning destination inside the existing App Shell.
- `/app/learning/course/:courseId` shows backend-confirmed course detail under the Learning tab.
- `/app/learning/course/:courseId/lesson/:lessonPartId` shows a single embedded lesson part under the Learning tab.
- Phase 4 covers course detail, embedded lesson lists, progress display, preview access, lesson completion, media playback, document reading, and lesson-part stack navigation.
- Checkout, enrollment purchase, payment results, orders, refunds, watched-duration progress mutation, and native direct PDF rendering are intentionally deferred.

## Backend contracts

- `GET /api/courses` is called as `/courses?isPublished=true` through the configured API base URL and returns a direct list of `CourseResponse`.
- `GET /api/courses/{id}` returns `CourseResponse` with `lessons`; missing courses return 404.
- Embedded lesson parts include `id`, `title`, `type`, `orderIndex`, `isPreview`, `videoId`, `videoDuration`, `playbackUrl`, `documentId`, `documentUrl`, and `content`.
- Video lesson parts use the backend-provided `playbackUrl`; the mobile app does not construct Bunny CDN URLs.
- Document lesson parts use the backend-provided `documentUrl`; the mobile app does not construct Bunny Storage URLs.
- `GET /api/enrollments` returns a direct authenticated list of active user enrollments.
- `GET /api/enrollments/{courseId}/progress` returns `CourseProgressResponse` for an active, unexpired enrollment.
- `POST /api/enrollments/{courseId}/lessons/{lessonPartId}/complete` marks one lesson part complete and returns a message envelope.
- Progress failures are access signals for locked non-preview lessons when the backend returns not-found or forbidden for missing, inactive, or expired enrollment.
- The backend does not expose catalog pagination metadata, category filtering, search, currency, ratings, reviews, checkout state, or lesson playback requirements for this phase.

## Mobile architecture

- `LearningScreen` watches `LearningController` and never calls Dio directly.
- `CourseDetailScreen` watches `CourseDetailController` and never calls Dio directly.
- `LessonScreen` watches `LessonController` and never calls Dio directly.
- `MediaPlayerScreen` and `DocumentReaderScreen` watch `LessonController` and consume only the lesson part returned by the existing repository boundary.
- `LearningRepository` orchestrates catalog endpoints.
- `CourseDetailRepository` orchestrates course detail, progress, lesson lookup, and lesson completion.
- `LearningApi` maps backend JSON into handwritten immutable Dart models and uses the existing `ApiClient` and Dio error mapper.
- Learning does not duplicate session, profile, or selected-tab state.

## UI behavior

- The catalog page shows a compact header, enrolled-course summaries, optional active categories, and the published course catalog.
- Course cards display only confirmed course fields, including title, description, instructor name, thumbnail, free/paid state from `isFree`, and access duration when present.
- Course detail shows the title, instructor, access duration, progress summary when available, description, learning outcomes, and backend-provided lessons and lesson parts.
- Lesson detail shows lesson-part title, type, preview/completion state, watched duration when available, HTML content when present, and a completion action when enrolled progress is available.
- Numeric prices are not displayed because the backend response does not confirm currency semantics.

## Media and documents

- Course and enrollment thumbnails use the existing cached image package with bounded decode sizes and local icon fallbacks.
- HTML lesson content uses the existing HTML rendering dependency already present in the project.
- Video playback uses the direct `video_player` dependency with the backend-provided `playbackUrl`, loading/error states, retry, play/pause, scrubbing, buffering feedback, and safe URL validation.
- Document viewing uses the existing WebView dependency with JavaScript disabled and the backend-provided `documentUrl`.
- Unsupported media states and invalid URLs show safe user-facing messages rather than fake playback or raw backend data.

## Progress and access

- Course progress is loaded separately from course detail because the backend exposes it under enrollments.
- Preview lesson parts can be opened when course progress is unavailable.
- Non-preview lesson parts require accessible course progress.
- Lesson completion posts to the confirmed backend endpoint and reloads lesson detail afterward so UI reflects backend-confirmed progress.
- Previous/next lesson navigation is derived from backend lesson-part ordering.
- Progress update by watched duration is not wired to a fake media timer because the backend contract for playback progress mutation is not confirmed.

## Error and empty states

- Course catalog failure renders the main retry state.
- Enrollment and category failures are isolated so the course catalog remains visible when it loaded successfully.
- Course progress failures are shown as access warnings on course detail when course detail itself loads.
- Missing course or missing lesson parts render user-safe not-found states.
- Empty lesson lists show an empty state.

## Navigation

- `/app/learning` remains one of exactly four authenticated shell destinations.
- `/app/learning/course/:courseId`, `/app/learning/course/:courseId/lesson/:lessonPartId`, `/app/learning/course/:courseId/lesson/:lessonPartId/media`, and `/app/learning/course/:courseId/lesson/:lessonPartId/document` are authenticated Learning child routes.
- Learning child routes keep the `Học tập` bottom-navigation destination selected because tab state is derived from the GoRouter location.
- Learning child routes do not create a second navigator, nested `MaterialApp`, or additional bottom-navigation tab.
