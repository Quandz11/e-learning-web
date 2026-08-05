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

## Images

- Request appropriately sized images.
- Avoid decoding very large images for small display areas.
- Use project caching policy.
- Handle placeholders and errors.
- Avoid bundling unnecessary high-resolution assets.

## Data and networking

- Paginate or stream large datasets.
- Avoid duplicate requests.
- Cache only where correctness and invalidation are understood.
- Move expensive parsing or computation off the UI isolate when justified by measurement.

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

## Validation

For performance-sensitive changes:

1. Record the scenario.
2. Record the baseline.
3. Apply the focused change.
4. Re-measure in profile or release mode.
5. Report tradeoffs and device conditions.

Do not claim performance improvement without evidence when measurement is practical.
