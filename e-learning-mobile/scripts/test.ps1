param(
    [string]$Path,
    [switch]$Coverage,
    [switch]$Integration
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path "pubspec.yaml")) {
    throw "Run this script from the Flutter project root."
}

$arguments = @("test")

if ($Integration) {
    $arguments += "integration_test"
} elseif ($Path) {
    $arguments += $Path
}

if ($Coverage) {
    $arguments += "--coverage"
}

Write-Host "Running: flutter $($arguments -join ' ')" -ForegroundColor Cyan
& flutter @arguments

if ($LASTEXITCODE -ne 0) {
    throw "Tests failed with exit code $LASTEXITCODE"
}

Write-Host "Tests passed." -ForegroundColor Green
