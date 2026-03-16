# Pasahe — Flutter Dev Environment Setup Script
# Run this ONCE after Flutter SDK is extracted and Android Studio is installed.
# Usage: powershell -ExecutionPolicy Bypass -File setup.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== Pasahe Setup ===" -ForegroundColor Cyan

# 1. Extract Flutter SDK if not already done
$flutterDest = "C:\flutter"
$flutterZip  = "$env:USERPROFILE\Downloads\flutter_windows_3.29.3-stable.zip"

if (-not (Test-Path "$flutterDest\bin\flutter.bat")) {
    if (Test-Path $flutterZip) {
        Write-Host "Extracting Flutter SDK to C:\flutter ..." -ForegroundColor Yellow
        Expand-Archive -Path $flutterZip -Destination "C:\" -Force
        Write-Host "Extraction complete." -ForegroundColor Green
    } else {
        Write-Host "Flutter zip not found at $flutterZip. Download it first." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Flutter SDK already extracted at $flutterDest." -ForegroundColor Green
}

# 2. Add Flutter to user PATH permanently
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*C:\flutter\bin*") {
    Write-Host "Adding C:\flutter\bin to user PATH..." -ForegroundColor Yellow
    [Environment]::SetEnvironmentVariable("Path", "$userPath;C:\flutter\bin", "User")
    $env:Path += ";C:\flutter\bin"
    Write-Host "PATH updated. Restart your terminal for it to take effect everywhere." -ForegroundColor Green
} else {
    Write-Host "Flutter already in PATH." -ForegroundColor Green
}

# 3. Accept Android licenses
Write-Host "`nAccepting Android SDK licenses..." -ForegroundColor Yellow
flutter doctor --android-licenses 2>&1 | Select-String -NotMatch "^$"

# 4. Install dependencies
Write-Host "`nRunning flutter pub get..." -ForegroundColor Yellow
Set-Location $PSScriptRoot
flutter pub get

# 5. Run code generation (Hive + Injectable)
Write-Host "`nRunning build_runner..." -ForegroundColor Yellow
dart run build_runner build --delete-conflicting-outputs

# 6. Final doctor check
Write-Host "`nRunning flutter doctor..." -ForegroundColor Yellow
flutter doctor -v

Write-Host "`n=== Setup complete! ===" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Open Android Studio -> AVD Manager -> Create a Pixel 9 (API 35) emulator"
Write-Host "  2. Start the emulator"
Write-Host "  3. In VS Code: press F5 or run 'flutter run' in terminal"
