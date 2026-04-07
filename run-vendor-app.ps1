# Quick Start - Run Vendor App in Emulator

$ANDROID_HOME = $env:ANDROID_HOME
if (-not $ANDROID_HOME) {
    $ANDROID_HOME = "$env:USERPROFILE\AppData\Local\Android\Sdk"
}
$env:ANDROID_HOME = $ANDROID_HOME

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Swift Vendor App - Emulator Launcher" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Start emulator if not running
$emulators = & "$ANDROID_HOME\emulator\emulator.exe" -list-avds 2>&1
$emuName = $emulators[0]

Write-Host "Using emulator: $emuName" -ForegroundColor Green
& "$ANDROID_HOME\emulator\emulator.exe" -avd $emuName -no-window -no-snapshot-load &

Write-Host "Waiting for emulator to boot (60 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

Write-Host ""
Write-Host "Starting Vendor App..." -ForegroundColor Green

$vendorDir = "C:\project\swift\vendor_app"
Push-Location $vendorDir
& flutter pub get
& flutter run -d emulator-5554
Pop-Location
