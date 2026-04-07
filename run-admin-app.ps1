# Quick Start - Run Admin App in Emulator
# This script auto-detects Android SDK and launches the admin app

$ANDROID_HOME = $env:ANDROID_HOME

# Auto-detect if not set
if (-not $ANDROID_HOME) {
    $possiblePaths = @(
        "$env:USERPROFILE\AppData\Local\Android\Sdk",
        "C:\Android\sdk"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $ANDROID_HOME = $path
            Write-Host "✓ Found Android SDK at: $path" -ForegroundColor Green
            break
        }
    }
}

if (-not $ANDROID_HOME) {
    Write-Host "✗ Android SDK not found" -ForegroundColor Red
    exit 1
}

$env:ANDROID_HOME = $ANDROID_HOME

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Swift Admin App - Emulator Launcher" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# List available emulators
Write-Host "Available emulators:" -ForegroundColor Yellow
$emulators = & "$ANDROID_HOME\emulator\emulator.exe" -list-avds 2>&1
if ($emulators.Count -eq 0) {
    Write-Host "No emulators found. Creating one..." -ForegroundColor Yellow
    Write-Host "Please create an emulator using Android Studio." -ForegroundColor Red
    exit 1
}

$emulators | ForEach-Object { Write-Host "  - $_" }
Write-Host ""

$emuName = $emulators[0]
Write-Host "Using emulator: $emuName" -ForegroundColor Green
Write-Host ""

# Start emulator
Write-Host "Starting emulator..." -ForegroundColor Cyan
& "$ANDROID_HOME\emulator\emulator.exe" -avd $emuName -no-window -no-snapshot-load &

Write-Host "Waiting for emulator to boot..." -ForegroundColor Cyan
Write-Host "This may take 60-90 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# Verify device is ready
Write-Host ""
Write-Host "Checking devices..." -ForegroundColor Cyan
& "$ANDROID_HOME\platform-tools\adb.exe" devices
Write-Host ""

# Launch admin app
$adminDir = "C:\project\swift\admin_app"
if (-not (Test-Path $adminDir)) {
    Write-Host "✗ Admin app not found at $adminDir" -ForegroundColor Red
    exit 1
}

Write-Host "Starting Admin App..." -ForegroundColor Green
Write-Host ""

Push-Location $adminDir
& flutter pub get
& flutter run -d emulator-5554
Pop-Location
