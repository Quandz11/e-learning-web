param(
    [switch]$SkipTests,
    [switch]$RunIntegration,
    [switch]$RunCodegen
)

$ErrorActionPreference = "Stop"

function Invoke-Step {
    param(
        [string]$Name,
        [scriptblock]$Command
    )

    Write-Host "`n==> $Name" -ForegroundColor Cyan
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE"
    }
}

if (-not (Test-Path "pubspec.yaml")) {
    throw "Run this script from the Flutter project root."
}

Invoke-Step "Flutter environment" { flutter --version }
Invoke-Step "Dependency resolution" { flutter pub get }

if ($RunCodegen) {
    Invoke-Step "Code generation" {
        dart run build_runner build --delete-conflicting-outputs
    }
}

Invoke-Step "Formatting check" {
    dart format --output=none --set-exit-if-changed .
}

Invoke-Step "Static analysis" { flutter analyze }

if (-not $SkipTests) {
    Invoke-Step "Unit and widget tests" { flutter test }
}

if ($RunIntegration) {
    if (-not (Test-Path "integration_test")) {
        throw "integration_test directory does not exist."
    }
    Invoke-Step "Integration tests" { flutter test integration_test }
}

Write-Host "`nAll requested checks passed." -ForegroundColor Green
