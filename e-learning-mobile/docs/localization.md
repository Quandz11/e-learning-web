# Localization

## Current setup

- Localization package or Flutter generation: TODO
- ARB or source location: TODO
- Generated access class: TODO
- Supported locales: TODO
- Fallback behavior: TODO

## Rules

- Do not hard-code user-facing strings when localization is configured.
- Reuse existing message keys where meaning is identical.
- Add new keys with clear semantic names.
- Keep placeholders typed and documented.
- Avoid building sentences by concatenating translated fragments.
- Support pluralization and gender where required.
- Preserve right-to-left layout support when applicable.

## Formatting

Use locale-aware formatting for:

- Dates and times
- Numbers
- Currency
- Percentages
- Relative time

Do not assume English word order or formatting.

## Error messages

- Map technical failures to localized user-safe messages.
- Keep actionable recovery guidance.
- Do not display raw server or exception text.

## Testing

Localization tests should cover:

- New keys exist for supported locales
- Placeholder rendering
- Important layouts with longer strings
- Right-to-left behavior where supported
- Locale switching if supported
