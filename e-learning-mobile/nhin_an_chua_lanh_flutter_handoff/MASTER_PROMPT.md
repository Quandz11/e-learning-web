# MASTER IMPLEMENTATION PROMPT — NHÌN ĂN CHỮA LÀNH

You are the lead Flutter engineer and product UI engineer for this repository.

Your job is to implement the complete Android/iOS Flutter application described in this document. Do not stop after scaffolding. Do not only produce plans or pseudocode. Build the app end-to-end using mock/local data where backend APIs are not available, and leave clean repository interfaces so real APIs can be connected later.

Use `ui_reference.png` in the repository as the visual reference. Match its visual language, spacing, component hierarchy, green palette, rounded cards, calm wellness aesthetic and overall information architecture. Do not try to OCR or pixel-copy text from the image. Follow this specification as the source of truth whenever image details conflict with this document.

---

## 1. Product definition

App name: **Nhìn Ăn Chữa Lành**

Platform: **Flutter for Android and iOS**

Product type: **health-focused learning application**.

The app is NOT a meditation app and must NOT have a meditation tab.

The application teaches users through structured courses. A course contains chapters and lessons. Lessons can be either:

1. video lessons;
2. PDF lessons.

Documents/PDFs live inside courses. There must be NO standalone “Tài liệu” bottom-navigation tab.

The second major area is personalized healthy-habit support. Users can configure reminders such as drinking water, standing/walking, resting and studying.

Primary navigation must contain exactly four tabs:

1. **Trang chủ**
2. **Khóa học**
3. **Cá nhân hóa**
4. **Cá nhân**

The app language in this implementation is Vietnamese.

---

## 2. Product principles

The app should feel:

- calm;
- trustworthy;
- premium but not luxurious;
- modern;
- easy to read;
- uncluttered;
- health-oriented without looking clinical;
- friendly to users who are not highly technical.

Avoid:

- overuse of gradients;
- neon colors;
- glassmorphism;
- excessive shadows;
- excessively rounded/pill-shaped everything;
- decorative icons with unclear meaning;
- very small text;
- dense dashboard layouts;
- meditation-specific imagery or terminology unless it appears inside a particular course.

Accessibility and clarity are more important than decorative styling.

---

## 3. Design system

Create a centralized design system. Do not scatter raw color values, radii or text sizes throughout screens.

### 3.1 Color tokens

Use the values in `design_tokens.json`. Equivalent Dart constants should be created under `lib/app/theme/`.

Core palette:

- Primary green: `#176B43`
- Primary dark: `#0F5132`
- Primary light: `#DDEFE5`
- Sage: `#84A98C`
- Soft mint: `#EDF7F0`
- App background: `#F7FAF7`
- Surface: `#FFFFFF`
- Warm surface: `#F8F6F1`
- Primary text: `#1F2D27`
- Secondary text: `#6B7770`
- Muted text: `#98A19C`
- Border: `#E4EAE6`
- Success: `#218B57`
- Warning: `#DFA73C`
- Error: `#C94A4A`
- Info: `#3D7EA6`

Reminder-type accents should be subtle:

- water: light blue icon/background;
- movement: warm amber/orange;
- rest: soft lavender;
- study: light green;
- meal/habit: warm sand.

Do not allow these accent colors to overpower the primary brand green.

### 3.2 Typography

Prefer **Be Vietnam Pro**. If unavailable or problematic, use **Inter**.

Implement typography tokens roughly following:

- Display: 28/34, semibold
- H1: 24/30, semibold
- H2: 20/26, semibold
- H3: 18/24, semibold
- Title: 16/22, semibold
- Body large: 16/24, regular
- Body: 14/21, regular
- Label: 13/18, medium
- Caption: 12/17, regular

Use `TextTheme` and extension/helper styles. Ensure dynamic text scale does not destroy layout.

### 3.3 Spacing

Base spacing scale:

- 4
- 8
- 12
- 16
- 20
- 24
- 32
- 40
- 48

Default horizontal screen padding: 16 px on phones, 24 px on larger layouts.

### 3.4 Radius

- small: 8
- medium: 12
- large: 16
- xLarge: 20
- full/pill: 999 only for chips, segmented controls and selected navigation indicators.

### 3.5 Shadows

Use very light shadows only on elevated hero cards, modal surfaces and bottom sheets. Prefer borders or tonal separation for ordinary cards.

### 3.6 Icons

Use Material Symbols/Material icons consistently, with crisp line weight. Use SVG only where a custom brand icon is required.

Use recognizable icons:

- home: home/outlines;
- courses: menu_book or school;
- personalization: tune/favorite/auto_awesome depending on context;
- profile: person;
- video lesson: play_circle;
- PDF lesson: picture_as_pdf or description;
- reminder: notifications;
- water: water_drop;
- walking: directions_walk;
- rest: bedtime;
- study: menu_book;
- settings: settings;
- achievements: emoji_events.

---

## 4. Technical architecture

Use current stable Flutter and Dart supported by the environment.

Use a clean feature-first architecture. Keep it pragmatic: do not overengineer with dozens of abstract layers for mock data.

Recommended packages:

- `flutter_riverpod` — state management
- `go_router` — routing
- `google_fonts` — typography
- `video_player` — base video playback
- `chewie` — playback controls and fullscreen handling
- `pdfx` — PDF viewer
- `flutter_local_notifications` — local reminders
- `timezone` — schedule local notifications accurately
- `shared_preferences` — small persisted preferences
- `flutter_svg` — SVG assets
- `cached_network_image` — remote course artwork where applicable
- `intl` — Vietnamese/date formatting
- `url_launcher` — help/legal external links where necessary
- `path_provider` — PDF/cache helpers if needed

Avoid paid/license-dependent packages unless already present in the project.

If a recommended package has become obsolete or incompatible with the current Flutter SDK, replace it with a reputable current equivalent and document the substitution.

### 4.1 Directory structure

Create or refactor toward:

```text
lib/
  main.dart
  app/
    app.dart
    router/
      app_router.dart
      route_names.dart
    theme/
      app_colors.dart
      app_typography.dart
      app_spacing.dart
      app_radius.dart
      app_shadows.dart
      app_theme.dart
  core/
    constants/
    extensions/
    utils/
    widgets/
      app_scaffold.dart
      app_top_bar.dart
      app_section_header.dart
      app_empty_state.dart
      app_error_state.dart
      app_loading.dart
      primary_button.dart
      secondary_button.dart
  features/
    onboarding/
      presentation/
    home/
      data/
      domain/
      presentation/
    courses/
      data/
      domain/
      presentation/
        screens/
        widgets/
    learning/
      data/
      domain/
      presentation/
        video/
        pdf/
    personalization/
      data/
      domain/
      presentation/
    notifications/
      data/
      domain/
      services/
      presentation/
    progress/
      data/
      domain/
      presentation/
    profile/
      data/
      domain/
      presentation/
    settings/
      presentation/
assets/
  images/
  icons/
  mock/
```

Keep reusable course-specific widgets within the `courses` feature; only globally reusable widgets belong in `core/widgets`.

---

## 5. Data models

Create immutable domain models. Freezed is optional; avoid introducing it if it adds unnecessary build complexity.

### 5.1 UserProfile

Fields:

- id
- displayName
- email
- avatarUrl/localAsset
- learningStreakDays
- completedLessons
- totalLearningMinutes
- achievements

### 5.2 Course

Fields:

- id
- title
- subtitle
- description
- coverImage
- category
- level
- totalLessons
- completedLessons
- estimatedMinutes
- progress 0..1
- chapters
- isFeatured
- updatedAt

### 5.3 CourseChapter

Fields:

- id
- title
- order
- lessons

### 5.4 Lesson

Fields:

- id
- chapterId
- title
- description
- type: `video | pdf`
- durationMinutes for video
- pageCount for PDF
- videoUrl / local sample source
- pdfUrl / bundled local sample source
- thumbnail
- order
- isLocked
- isCompleted
- progress 0..1
- lastVideoPositionSeconds
- lastPdfPage

### 5.5 Reminder

Fields:

- id
- type: `water | movement | rest | study | custom`
- title
- message
- enabled
- frequency type: interval or scheduled times
- intervalMinutes nullable
- specificTimes list nullable
- startTime
- endTime
- repeatDays (Mon-Sun)
- soundEnabled
- vibrationEnabled
- createdAt
- updatedAt

### 5.6 PersonalizationProfile

Fields:

- dailyWaterGoalMl
- movementGoalMinutes
- studyGoalMinutes
- preferredLearningTime
- interests
- reminders
- notificationPermissionState

### 5.7 LearningProgress

Fields:

- courseId
- completedLessonIds
- percent
- totalMinutes
- lastOpenedLessonId
- lastAccessedAt

---

## 6. Navigation

Use `go_router` with a stateful shell or equivalent persistent bottom navigation.

Bottom navigation routes:

- `/home`
- `/courses`
- `/personalization`
- `/profile`

Nested routes:

- `/courses/:courseId`
- `/courses/:courseId/lesson/:lessonId/video`
- `/courses/:courseId/lesson/:lessonId/pdf`
- `/personalization/reminders`
- `/personalization/reminders/new`
- `/personalization/reminders/:reminderId/edit`
- `/progress`
- `/settings`
- `/profile/achievements`
- `/profile/history`

Splash/onboarding can sit outside the shell.

When opening a video or PDF lesson, hide bottom navigation and use an immersive learning screen.

Preserve tab navigation state where feasible.

---

## 7. Required screens

Implement ALL screens below.

### 7.1 Splash / welcome

Visual:

- pale green/cream background;
- centered leaf-style brand mark or simple temporary vector mark;
- “Nhìn Ăn Chữa Lành”;
- tagline: “Học để sống an lành hơn mỗi ngày”;
- restrained nature artwork or soft abstract botanical background;
- primary CTA “Bắt đầu”;
- secondary login text link “Đã có tài khoản? Đăng nhập”.

No complex authentication implementation is required unless existing APIs already exist. The CTA may enter the mocked app shell.

### 7.2 HomeScreen

Sections in this order:

1. greeting row with avatar, “Xin chào, {name}” and notification icon;
2. search field “Tìm khóa học, bài học...”;
3. optional editorial banner / quote card;
4. quick actions:
   - Tiếp tục học
   - Khóa học
   - Cá nhân hóa
   - Nhắc nhở
5. “Tiếp tục học” card if an active course exists;
6. “Khóa học nổi bật” horizontal or vertical cards;
7. compact learning progress summary;
8. optional suggestion card tied to personalization.

Avoid cramming everything above the fold. Use clear vertical rhythm.

### 7.3 CourseListScreen

Header: “Khóa học”

Controls:

- search;
- segmented status filters: Tất cả / Đang học / Đã hoàn thành;
- optional category chips below when useful.

Each course list tile/card shows:

- thumbnail;
- title;
- short subtitle/category;
- lesson count;
- progress if started;
- chevron.

Include sensible empty state for filters.

### 7.4 CourseDetailScreen

Top hero:

- course cover image;
- back button;
- favorite/bookmark icon optional.

Content:

- course title;
- short description;
- metadata: lesson count, estimated duration, level;
- progress indicator;
- tabs or segmented area for “Nội dung / Giới thiệu” (an “Đánh giá” tab is optional if mock data exists);
- expandable chapter sections.

Lesson tile displays:

- icon based on video/PDF;
- lesson number + title;
- `Video · 12 phút` or `PDF · 8 trang`;
- completed state;
- locked state;
- current lesson progress.

Tapping unlocked lesson opens appropriate viewer.

### 7.5 VideoLessonScreen

Must be production-quality enough for an app prototype.

Portrait mode:

- app bar/back;
- 16:9 player;
- title below;
- progress/status;
- optional previous/next lesson controls;
- lesson description/notes area.

Fullscreen:

- landscape orientation;
- dark/black player chrome;
- play/pause;
- seek bar;
- elapsed/total time;
- 10-second rewind/forward;
- playback speed control;
- fullscreen exit;
- device orientation restored after exit.

Persist playback position locally. Resume near previous position when reopening.

Mark lesson completed when playback passes a sensible threshold such as 90%, but keep this logic isolated/configurable.

Handle loading/error states.

### 7.6 PdfLessonScreen

Use a real PDF viewer implementation.

Requirements:

- app bar with lesson/PDF title;
- vertical PDF reading by default;
- pinch zoom;
- page number indicator `x / total`;
- search if easily supported by chosen package; if package cannot support search reliably, omit search rather than fake it;
- optional bookmark button;
- remember last viewed page locally;
- reopen at last viewed page;
- mark completion when the user reaches the final page or taps “Hoàn thành bài học”.

For development, include one small bundled sample PDF asset if no real backend PDF exists.

### 7.7 PersonalizationScreen

This is one of the FOUR PRIMARY TABS and must look important, not like a settings afterthought.

Header: “Cá nhân hóa”

Subtitle: “Thiết lập thói quen lành mạnh phù hợp với bạn”

Sections:

1. **Mục tiêu của tôi**
   - water goal;
   - movement goal;
   - study goal.
2. **Nhắc nhở**
   - water;
   - movement;
   - rest;
   - study;
   - entry point to full reminder list.
3. **Thói quen hằng ngày**
   - compact daily completion rows/cards.
4. **Sở thích & mối quan tâm**
   - categories used later for course recommendations.
5. **Báo cáo tiến độ**
   - link to progress screen.
6. **Dữ liệu cá nhân hóa**
   - simple explanation that settings are used to tailor reminders/content;
   - do not make unsupported medical claims.

### 7.8 ReminderListScreen

Title: “Nhắc nhở”

Show cards/rows for configured reminders:

- icon;
- title;
- summary of frequency;
- toggle;
- tap to edit.

CTA: “Thêm nhắc nhở”.

Recommended starter reminders:

- Uống nước
- Đi lại / Vận động
- Nghỉ ngơi
- Giờ học

Toggling should schedule/cancel notifications correctly.

### 7.9 ReminderEditorScreen

Fields:

- reminder type selector;
- title;
- notification message;
- enabled toggle;
- schedule mode:
  - every N minutes within window;
  - selected specific time(s);
- start time;
- end time;
- repeat days;
- sound toggle;
- vibration toggle;
- save button.

Validation:

- end cannot logically precede start unless overnight handling is intentionally implemented;
- interval minimum should be reasonable;
- at least one repeat day for repeating reminders;
- empty title not allowed.

Request notification permission contextually, not immediately on first app launch.

### 7.10 LearningProgressScreen

Header: “Tiến độ học tập”

Show:

- circular/linear completion summary;
- courses in progress;
- courses completed;
- total lessons completed;
- total learning minutes;
- optional weekly learning summary with simple bars, but do not introduce a heavy chart dependency merely for decoration.

### 7.11 ProfileScreen

Header: “Cá nhân”

Top card:

- avatar;
- name;
- email.

Rows:

- Hồ sơ của tôi
- Thành tích
- Lịch sử học tập
- Cài đặt
- Trung tâm trợ giúp
- Về ứng dụng
- Đăng xuất

Make logout destructive/red but visually restrained.

### 7.12 SettingsScreen

Rows:

- Tài khoản
- Thông báo
- Giao diện
- Ngôn ngữ (Tiếng Việt)
- Quyền riêng tư
- Xóa bộ nhớ đệm
- Điều khoản sử dụng
- Chính sách bảo mật
- Về ứng dụng

Do not add unrelated settings.

---

## 8. Bottom navigation shell

Exactly four items:

```text
Trang chủ | Khóa học | Cá nhân hóa | Cá nhân
```

Icons must be crisp and recognizable.

Selected item:

- primary green icon;
- medium-weight label;
- subtle tinted background or indicator.

Unselected:

- neutral gray/green.

Use safe-area aware bottom navigation compatible with gesture navigation on Android and home indicator on iPhone.

---

## 9. Reusable widgets

At minimum build:

- `AppScaffold`
- `AppTopBar`
- `AppSectionHeader`
- `PrimaryButton`
- `SecondaryButton`
- `SearchField`
- `CourseCard`
- `CourseListTile`
- `ContinueLearningCard`
- `CourseProgressBar`
- `ChapterExpansionTile`
- `LessonTile`
- `ReminderTile`
- `HabitProgressTile`
- `SettingTile`
- `ProfileMenuTile`
- `EmptyState`
- `LoadingState`
- `ErrorState`

Keep widgets composable and avoid screens exceeding a huge monolithic build method.

---

## 10. Mock content

Create realistic Vietnamese mock data. Do not fill the UI with Lorem Ipsum.

Suggested courses:

1. **Sống khỏe từ bên trong**
   - subtitle: Hiểu cơ thể – Nuôi dưỡng tâm trí
2. **Dinh dưỡng lành mạnh**
3. **Giấc ngủ chất lượng**
4. **Quản lý căng thẳng**
5. **Thói quen tốt mỗi ngày**
6. **Làm việc hiệu quả**

Example chapters for “Sống khỏe từ bên trong”:

**Chương 1: Nền tảng của sức khỏe**

- Sức khỏe là gì? — video — 12 phút
- Những yếu tố tạo nên sức khỏe — PDF — 8 trang
- Lối sống lành mạnh — video — 15 phút

**Chương 2: Dinh dưỡng cân bằng**

- Hiểu cơ bản về dinh dưỡng — video
- Nguyên tắc xây dựng bữa ăn — PDF
- Thực hành theo dõi thói quen — PDF

Add at least one locked lesson and several completed/in-progress examples.

Mock user:

- name: Mai Dung
- email: maid******@gmail.com or a neutral demo address; avoid showing unnecessary personal data if no user account exists.

Prefer `demo@nhinanchualanh.vn` for public demo data.

---

## 11. Local persistence

Persist at minimum:

- selected personalization goals;
- reminder definitions;
- reminder enabled state;
- video last playback position;
- PDF last page;
- lesson completion state;
- course progress derived from lessons;
- whether onboarding/splash CTA has been completed if needed.

Use repository/service abstractions so backend integration can replace local storage later.

Do not persist sensitive medical data. This prototype should only store basic app preferences and learning/reminder state.

---

## 12. Local notifications

Implement actual local-notification plumbing for Android and iOS.

Requirements:

- initialize `flutter_local_notifications`;
- request permission only when user enables/creates reminders;
- Android notification channel for healthy habit reminders;
- iOS notification authorization;
- timezone-aware scheduling;
- cancellation/update when reminders change;
- unique stable notification IDs per reminder/schedule slot;
- notification tap should deep-link to the personalization/reminders area if feasible.

For interval reminders constrained to a start/end window, generate concrete scheduled occurrences for the appropriate future horizon, or use a robust supported mechanism. Avoid unsupported fake recurrence semantics.

Account for Android 13+ notification permission and modern Android exact-alarm restrictions. Do not require exact alarm privileges unless truly needed. Habit reminders can normally tolerate inexact scheduling.

Include any necessary native configuration in AndroidManifest / iOS Info.plist or AppDelegate according to current package requirements.

---

## 13. Video orientation behavior

When entering fullscreen video:

- allow/force landscape left/right;
- use immersive mode appropriately;
- player controls remain usable;
- when exiting, restore portrait orientations and standard system UI.

Do not globally lock the entire app to portrait if it breaks player fullscreen.

---

## 14. Responsive layout

Target:

- small Android phones;
- modern Android phones;
- compact iPhones;
- large iPhones;
- tablets remain usable though a full tablet redesign is not required.

Use `SafeArea`, constraints and responsive widths. Avoid absolute positioning for primary layout.

Landscape support is mandatory for video. PDF can remain usable in both orientations.

---

## 15. Loading / empty / error states

Every data-driven screen should have a reasonable state model.

Required examples:

- course list empty filter;
- course load error;
- video failed to load;
- PDF failed to load;
- no reminders yet;
- no current courses;
- progress screen with no history.

Do not leave blank screens.

---

## 16. Interaction details

Use subtle haptics only where helpful, such as successful save or selection if supported.

Buttons:

- minimum touch target around 44–48 logical pixels;
- disabled state visibly distinct;
- loading state prevents duplicate submission.

Cards:

- tap feedback;
- use InkWell/InkResponse with clipping/radius correctly.

Forms:

- dismiss keyboard sensibly;
- show inline validation;
- time/day selectors should be native-feeling.

---

## 17. Accessibility

Implement:

- semantic labels for icon-only actions;
- enough contrast;
- text scaling tolerance;
- minimum tap targets;
- no information communicated only by color;
- readable player controls;
- meaningful labels for video/PDF lesson types.

---

## 18. Assets

`ui_reference.png` is a design reference, not an in-app production asset.

Create simple placeholder visual assets where required. Prefer gradients made from subtle brand colors, local abstract botanical shapes or legal/royalty-free placeholders already in the repository.

Do not scrape or embed copyrighted images from the public internet.

If the existing project already has approved branding/logo assets, use them.

---

## 19. App theme behavior

Initial scope is light theme only, consistent with the reference.

Architect the theme cleanly so a future dark theme is possible, but do not spend time designing dark mode unless it already exists in the project.

---

## 20. API readiness

Use interfaces such as:

- `CourseRepository`
- `LearningProgressRepository`
- `PersonalizationRepository`
- `ReminderRepository`

Provide mock/local implementations now.

Do not hard-wire network implementation assumptions into presentation code.

When a future API is introduced, UI should not need to be rewritten.

---

## 21. Quality requirements

Before finishing:

1. run formatting;
2. run `flutter analyze`;
3. fix analyzer errors and meaningful warnings;
4. run tests;
5. verify app builds at least for the available target(s) in the environment;
6. inspect the major screens visually;
7. verify routing;
8. verify local persistence;
9. verify reminder create/edit/toggle flows;
10. verify video portrait/fullscreen-landscape transitions;
11. verify PDF open/page-resume;
12. verify no stray “Tài liệu” or “Thiền” bottom tab exists.

Do not claim success for checks you could not run. If the environment prevents a platform build, report that clearly and still complete all feasible static/runtime checks.

---

## 22. Tests

Add a practical test suite, not exhaustive enterprise testing.

At minimum:

- unit test course progress calculation;
- unit test reminder validation;
- unit test persistence mapping if nontrivial;
- widget test bottom navigation has exactly 4 tabs;
- widget test course detail renders video and PDF lesson types;
- widget test personalization reminder toggle UI;
- routing smoke test for video/PDF lesson routes where feasible.

---

## 23. Native platform considerations

### Android

Handle:

- Android notification permission on supported versions;
- app icon/splash placeholder if project setup allows;
- landscape fullscreen video;
- edge-to-edge/safe area;
- no unnecessary storage permission for bundled/network PDFs.

### iOS

Handle:

- notification permission;
- orientation support required for fullscreen landscape video;
- safe areas/home indicator;
- standard network/media settings only if necessary.

Do not request permissions that are not needed.

---

## 24. Security / privacy principles

- Never commit secrets or API keys.
- Do not store passwords.
- Do not collect health diagnosis or medical-condition fields in this prototype.
- Personalization means preferences, goals and reminder settings, not medical diagnosis.
- Any health-related educational text is informational and should avoid promises of treatment/cure.

---

## 25. Definition of done

The task is done only when the repository contains a navigable, cohesive Flutter application that demonstrates the complete product flow:

```text
Splash
  ↓
Main app shell
  ├─ Trang chủ
  ├─ Khóa học
  │    └─ Chi tiết khóa học
  │          ├─ Video lesson → portrait + fullscreen landscape player
  │          └─ PDF lesson → real PDF viewer
  ├─ Cá nhân hóa
  │    ├─ Mục tiêu
  │    ├─ Danh sách nhắc nhở
  │    └─ Tạo / chỉnh sửa nhắc nhở → local notification
  └─ Cá nhân
       ├─ Tiến độ / lịch sử / thành tích
       └─ Cài đặt
```

It must look like one coherent product, not a collection of unrelated demo screens.

---

## 26. Work mode

Proceed autonomously.

Do not ask for confirmation for ordinary implementation details. Make reasonable product decisions consistent with this specification.

If an existing Flutter codebase is present, preserve working architecture/code where practical and integrate cleanly rather than deleting everything.

If the repository is empty, create the Flutter project structure needed to implement this specification.

Do not stop after generating files. Run the app/checks available in the environment, fix issues and iterate.

At the end, provide a concise implementation summary containing:

- screens implemented;
- key packages used;
- important architectural choices;
- commands/checks run;
- any environment-limited items that still need validation on a real Android/iOS device.

START IMPLEMENTATION NOW.
