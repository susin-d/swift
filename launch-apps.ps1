# Quick launcher for all three apps (simpler version)
# Usage: .\launch-apps.ps1

param(
    [string]$Device = "emulator-5554"  # Default to first emulator
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Swift Apps Launcher" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$apps = @(
    @{ dir = "user_app"; name = "User App"; port = "1" },
    @{ dir = "vendor_app"; name = "Vendor App"; port = "2" },
    @{ dir = "admin_app"; name = "Admin App"; port = "3" }
)

# Check if ANDROID_HOME is set
$ANDROID_HOME = $env:ANDROID_HOME
if (-not $ANDROID_HOME) {
    Write-Host "ERROR: ANDROID_HOME is not set." -ForegroundColor Red
    Write-Host "Please set ANDROID_HOME to your Android SDK location." -ForegroundColor Red
    exit 1
}

# Check connected devices
Write-Host "Checking connected devices..."
& "$ANDROID_HOME\platform-tools\adb.exe" devices
Write-Host ""

$choice = Read-Host "Enter app choice (1=User, 2=Vendor, 3=Admin, or press Enter to run all)"

if ([string]::IsNullOrEmpty($choice)) {
    # Run all three on default device
    Write-Host ""
    Write-Host "Note: Running all three requires one emulator per app OR sequential testing." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 1: Run on same device (sequential, Ctrl+C to switch apps)"
    Write-Host "Option 2: Create 3 emulators and run in parallel (use launch-emulators.ps1)"
    Write-Host ""
    $choice = Read-Host "Select option (1 or 2)"
    
    if ($choice -eq "2") {
        Write-Host "Running multi-emulator setup..." -ForegroundColor Cyan
        & .\launch-emulators.ps1 -RunApps
        exit 0
    }
    
    # Run all sequentially
    Write-Host ""
    foreach ($app in $apps) {
        Write-Host ""
        Write-Host "Starting $($app.name)..." -ForegroundColor Green
        Write-Host "Press Ctrl+C to stop and move to next app, or close the emulator window." -ForegroundColor Yellow
        Write-Host ""
        
        $appDir = "c:\project\swift\$($app.dir)"
        if (-not (Test-Path $appDir)) {
            Write-Host "ERROR: $appDir not found" -ForegroundColor Red
            continue
        }
        
        Push-Location $appDir
        & flutter run -d $Device
        Pop-Location
    }
} else {
    if ($choice -lt 1 -or $choice -gt 3) {
        Write-Host "Invalid choice" -ForegroundColor Red
        exit 1
    }
    
    $app = $apps[$choice - 1]
    $appDir = "c:\project\swift\$($app.dir)"
    
    if (-not (Test-Path $appDir)) {
        Write-Host "ERROR: $appDir not found" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Starting $($app.name)..." -ForegroundColor Green
    Write-Host ""
    
    Push-Location $appDir
    & flutter pub get
    & flutter run -d $Device
    Pop-Location
}
