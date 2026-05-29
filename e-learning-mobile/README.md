# SKVI Mobile

Flutter mobile app for SKVI e-learning platform (Android + iOS) using shared .NET backend.

## Environment

The app loads environment settings from:

- `assets/env/.env.dev`
- `assets/env/.env.staging`
- `assets/env/.env.prod`

Payment callback URLs are configured by:

- `PAYMENT_RETURN_URL`
- `PAYMENT_CANCEL_URL`

Supported custom URL schemes:

- `skvi`
- `skvi-dev`
- `skvi-staging`

Supported universal/app-link domains:

- `nhinanchualanh.vn`
- `www.nhinanchualanh.vn`

## Deep Link

Payment callback deep links are normalized into internal route:

- `/payment-result`

Supported inbound URI patterns:

- `skvi://payment/result?orderId=...&orderCode=...`
- `skvi://payment-result?orderId=...`
- `skvi:///payment-result?orderCode=...`
- `https://nhinanchualanh.vn/payment/result?orderCode=...`
- `https://www.nhinanchualanh.vn/payment-result?orderCode=...`

## Server Domain Association Files

For App Links / Universal Links verification, host the following files from backend static content:

- `/.well-known/assetlinks.json`
- `/.well-known/apple-app-site-association`

Templates are provided at:

- `e-learning-server/e-learning-server/wwwroot/.well-known/assetlinks.json.template`
- `e-learning-server/e-learning-server/wwwroot/.well-known/apple-app-site-association.template`

## Run Quality Checks

```bash
flutter analyze
flutter test
```

## Manual Deep Link Test

Android:

```bash
adb shell am start -W -a android.intent.action.VIEW -d "skvi://payment/result?orderId=test-order&orderCode=123" vn.nhinanchualanh.e_learning_mobile
```

```bash
adb shell am start -W -a android.intent.action.VIEW -d "https://nhinanchualanh.vn/payment/result?orderCode=123" vn.nhinanchualanh.e_learning_mobile
```

iOS simulator:

```bash
xcrun simctl openurl booted "skvi://payment/result?orderId=test-order&orderCode=123"
```

```bash
xcrun simctl openurl booted "https://nhinanchualanh.vn/payment/result?orderCode=123"
```
