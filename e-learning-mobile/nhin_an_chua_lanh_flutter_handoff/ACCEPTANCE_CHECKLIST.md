# Acceptance checklist

## Product navigation
- [ ] Exactly four bottom tabs: Trang chủ, Khóa học, Cá nhân hóa, Cá nhân
- [ ] No meditation bottom tab
- [ ] No standalone document/PDF bottom tab
- [ ] Course detail opens video and PDF lesson routes
- [ ] Learning viewers hide the bottom nav

## Visual design
- [ ] Green wellness palette from design tokens
- [ ] White/light surfaces, subtle borders, restrained shadows
- [ ] Consistent typography and spacing
- [ ] Clear, crisp icons
- [ ] Safe areas correct on Android/iPhone
- [ ] Small phone layouts do not overflow

## Home
- [ ] Greeting + notification
- [ ] Search
- [ ] Quick actions
- [ ] Continue learning
- [ ] Featured courses
- [ ] Learning progress summary

## Courses
- [ ] All / In progress / Completed filters
- [ ] Course cards show progress where relevant
- [ ] Course details contain expandable chapters
- [ ] Video/PDF lesson types visually clear
- [ ] Lock/completed/in-progress states

## Video
- [ ] Portrait player works
- [ ] Landscape fullscreen works
- [ ] Play/pause
- [ ] Seek
- [ ] ±10 seconds
- [ ] Speed
- [ ] Time display
- [ ] Playback resume persisted
- [ ] Orientation/system UI restored on exit

## PDF
- [ ] Real PDF rendering
- [ ] Zoom
- [ ] Page indicator
- [ ] Last page persisted
- [ ] Resume at last page
- [ ] Completion supported
- [ ] Error state

## Personalization
- [ ] Primary tab, not nested under profile
- [ ] Goals section
- [ ] Water reminder
- [ ] Movement reminder
- [ ] Rest reminder
- [ ] Study reminder
- [ ] Daily habits
- [ ] Interests
- [ ] Progress entry point

## Reminder editor
- [ ] Type
- [ ] Title
- [ ] Message
- [ ] Enable toggle
- [ ] Interval/specific-time scheduling
- [ ] Start/end time
- [ ] Repeat days
- [ ] Sound/vibration
- [ ] Validation
- [ ] Save/edit/delete behavior

## Notifications
- [ ] Android/iOS initialization
- [ ] Contextual permission request
- [ ] Create/update/cancel schedules
- [ ] Timezone aware
- [ ] No unnecessary exact-alarm permission

## Profile/settings
- [ ] User summary
- [ ] Achievements
- [ ] Learning history
- [ ] Settings
- [ ] Help/about
- [ ] Logout
- [ ] Privacy/terms rows

## Engineering
- [ ] Feature-first structure
- [ ] Riverpod state
- [ ] go_router navigation
- [ ] Central theme/tokens
- [ ] Mock/local repository separation
- [ ] Local persistence
- [ ] Loading/empty/error states
- [ ] `flutter format` / formatting complete
- [ ] `flutter analyze` passes or limitations documented
- [ ] Tests added and run
- [ ] Available platform build/smoke run completed
