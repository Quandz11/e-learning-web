# Release Process

## Release targets

- Android: TODO
- iOS: TODO
- Other platforms: TODO

## Versioning

- Version source: `pubspec.yaml`
- Version policy: TODO
- Build number policy: TODO
- Tagging convention: TODO

## Pre-release checks

1. Confirm clean working tree or reviewed intended changes.
2. Run formatter.
3. Run analyzer.
4. Run unit and widget tests.
5. Run relevant integration tests.
6. Regenerate code and localization output where applicable.
7. Review dependency and platform configuration changes.
8. Verify environment selection.
9. Verify no secrets or debug endpoints are included.
10. Review release notes.

## Standard validation

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

## Android

Document:

- Application ID: TODO
- Signing source: TODO
- Build command: TODO
- Flavor commands: TODO
- Play Console process: TODO
- Required permission review: TODO

Never commit private keystores or signing passwords.

## iOS

Document:

- Bundle identifier: TODO
- Team and signing approach: TODO
- Build command: TODO
- Flavor or scheme mapping: TODO
- App Store Connect process: TODO
- Entitlement review: TODO

Never commit private certificates, profiles containing sensitive data, or signing credentials.

## Rollback

- Rollback owner: TODO
- Feature flag strategy: TODO
- Previous release restoration process: TODO
- Data migration compatibility requirements: TODO

## Release evidence

Record:

- Commit and tag
- Build number
- Environment
- Validation results
- Known limitations
- Migration or rollout notes
