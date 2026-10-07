# MPS School Management System - Release APK Build Script
# Usage: powershell -ExecutionPolicy Bypass -File scripts/build_apk.ps1

$ErrorActionPreference = "Stop"

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " MPS School Management System - Android APK Build" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# 1. Check Flutter installation
Write-Host "`n[1/4] Verifying Flutter environment..." -ForegroundColor Yellow
flutter --version

# 2. Get dependencies
Write-Host "`n[2/4] Resolving dependencies..." -ForegroundColor Yellow
flutter pub get

# 3. Analyze code
Write-Host "`n[3/4] Running static analyzer..." -ForegroundColor Yellow
flutter analyze

# 4. Build release APK
Write-Host "`n[4/4] Building Release APK..." -ForegroundColor Yellow
flutter build apk --release

$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    $apkItem = Get-Item $apkPath
    $sizeMb = [math]::Round($apkItem.Length / 1MB, 2)
    Write-Host "`n=================================================" -ForegroundColor Green
    Write-Host " BUILD SUCCESSFUL!" -ForegroundColor Green
    Write-Host " APK Path: $apkPath" -ForegroundColor Green
    Write-Host " Size: $sizeMb MB" -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor Green
} else {
    Write-Error "APK file not found at expected path: $apkPath"
}
