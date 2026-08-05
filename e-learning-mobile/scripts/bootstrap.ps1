$ErrorActionPreference = "Stop"

if (-not (Test-Path "pubspec.yaml")) {
    throw "Run this script from the Flutter project root."
}

Write-Host "Resolving Flutter dependencies..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed" }

if (Test-Path ".agents/skills") {
    Write-Host "Flutter agent skills found under .agents/skills." -ForegroundColor Green
} else {
    Write-Warning "No .agents/skills directory found. Install the Flutter agent skills if required."
}

Write-Host "Running initial analyzer check..." -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Analyzer reported existing issues. Review them before agent-assisted development."
}

Write-Host "Bootstrap complete." -ForegroundColor Green
