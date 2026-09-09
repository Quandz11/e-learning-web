# Performance

## Principles

- Measure before major optimization.
- Fix observable bottlenecks rather than optimizing speculative paths.
- Preserve correctness and clarity.
- Avoid unnecessary rebuilds and repeated expensive work.

## Rendering

- Keep expensive computation out of `build`.
- Use `const` where valid.
- Watch the minimum necessary state.
- Avoid rebuilding large trees for small state changes.
- Use lazy builders for long lists.
- Provide stable keys where identity matters.
- Avoid unnecessary opacity, clipping, and save-layer operations.
- Keep visual design primitives lightweight; avoid heavy shadows, gradients, animation controllers, and decorative layers unless measured need exists.
- Prefer shared layout widgets with constrained content width for forms and small-screen readability instead of ad hoc nested scroll structures.
- Keep shell tab selection route-driven so the scaffold does not maintain duplicate navigation state or preserve unnecessary inactive trees for placeholder screens.
- Keep authenticated shell navigation styling lightweight by using standard Material 3 `NavigationBar` motion and a single shell-owned surface instead of custom animation stacks or extra navigation layers.
- Keep auth and profile forms scrollable and controller-driven so temporary field state stays local to the screen and does not trigger shell-wide rebuilds.
- Keep Home rendering to one scrollable list with constrained content width and controller-driven loading so repeated child rebuilds do not trigger duplicate requests.
- Keep Learning rendering to one scrollable list with constrained content width; the controller triggers the initial request once after mount and retains loaded content during refresh.
- Keep course detail and lesson rendering to a single scrollable surface under the existing shell; controllers trigger initial loads once and retain existing content during refresh or completion failures.
- Media and document child routes reuse the existing lesson repository/controller boundary and do not rebuild the router or shell for playback/reading state.

## Images

- Request appropriately sized images.
- Avoid decoding very large images for small display areas.
- Use project caching policy.
- Handle placeholders and errors.
- Avoid bundling unnecessary high-resolution assets.
- Home cards cap cached image decode sizes and use local icon fallbacks instead of heavier custom image pipelines.
- Learning course and enrollment cards use the existing cached image dependency with bounded image dimensions, capped cache widths, zero fade delay, and local icon fallbacks for missing or failed thumbnails.
- Course detail thumbnails use the existing cached image dependency with bounded cache dimensions and lightweight fallback icons.
- Document reading does not add a PDF bitmap cache; it delegates the backend-provided URL to the existing WebView surface.

## Data and networking

- Paginate or stream large datasets.
- Avoid duplicate requests.
- Cache only where correctness and invalidation are understood.
- Move expensive parsing or computation off the UI isolate when justified by measurement.
- The confirmed Learning backend returns direct lists without pagination metadata, so Phase 3 does not invent pagination or infinite scroll.
- Learning loads courses as the primary section and isolates enrollment/category failures so one optional failure does not hide the catalog.
- Course detail loads progress separately from course content and treats not-found/forbidden progress responses as access-state information for locked non-preview lessons.
- Lesson completion reloads backend-confirmed progress after success instead of mutating complex local progress state.
- Video playback streams the backend-provided URL through `video_player`; the app does not download media files into Dart memory.
- Watched-duration progress is not simulated without a confirmed backend progress mutation contract.

## Startup

- Avoid unnecessary synchronous work before first frame.
- Defer optional initialization.
- Keep dependency setup predictable.
- Measure startup using appropriate Flutter profiling tools.
- Keep internal development utilities such as the component showcase behind debug-only routing so they do not alter normal user navigation or release startup behavior.
- Keep visible startup work outside the router until config load and session restoration settle so the app does not render temporary login or shell content.
- Limit native launch customization to simple static backgrounds that reduce white-flash risk without adding startup packages or extra platform logic.

## Memory and lifecycle

- Dispose owned resources.
- Avoid retaining large collections or widget contexts unnecessarily.
- Cancel unused subscriptions and requests when supported.
- Review image and cache limits.
- Dispose video and WebView-owned route resources when media/document routes are removed.

## Validation

For performance-sensitive changes:

1. Record the scenario.
2. Record the baseline.
3. Apply the focused change.
4. Re-measure in profile or release mode.
5. Report tradeoffs and device conditions.

Do not claim performance improvement without evidence when measurement is practical.
