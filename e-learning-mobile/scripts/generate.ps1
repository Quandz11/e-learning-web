param(
    [switch]$Watch
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path "pubspec.yaml")) {
    throw "Run this script from the Flutter project root."
}

if ($Watch) {
    dart run build_runner watch --delete-conflicting-outputs
} else {
    dart run build_runner build --delete-conflicting-outputs
}

if ($LASTEXITCODE -ne 0) {
    throw "Code generation failed with exit code $LASTEXITCODE"
}
