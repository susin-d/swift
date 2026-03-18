# PowerShell Script to Build Flutter APK and Move/Rename
# Build vendor_app, admin_app, or user_app - verify build, move to apps folder and rename to app folder name

param(
    [Parameter(Mandatory=$false)]
    [string]$AppName = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("release", "debug")]
    [string]$BuildType = "release",
    
    [Parameter(Mandatory=$false)]
    [switch]$All
)

$ErrorActionPreference = "Stop"

$ProjectRoot = "C:\project\food"
$AppsFolder = Join-Path $ProjectRoot "apps"

# Function to build and move a single app
function Build-App {
    param(
        [string]$Name
    )
    
    $AppDir = Join-Path $ProjectRoot $Name
    $OutputDir = Join-Path $AppDir "build\app\outputs\flutter-apk"
    $SourceAPK = Join-Path $OutputDir "app-$BuildType.apk"
    $DestinationAPK = Join-Path $AppsFolder "$Name.apk"
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Building $Name Flutter App" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    # Step 1: Build the Flutter APK
    Write-Host "`n[1/3] Building Flutter APK..." -ForegroundColor Yellow
    Write-Host "Running: flutter build apk --$BuildType" -ForegroundColor Gray
    
    Push-Location $AppDir
    try {
        $buildResult = & flutter build apk --$BuildType 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Build FAILED for $Name!" -ForegroundColor Red
            Write-Host $buildResult
            return $false
        }
        
        Write-Host "Build completed successfully!" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
    
    # Step 2: Verify the APK exists
    Write-Host "`n[2/3] Verifying APK build..." -ForegroundColor Yellow
    
    if (-not (Test-Path $SourceAPK)) {
        Write-Host "ERROR: APK not found at $SourceAPK" -ForegroundColor Red
        return $false
    }
    
    $apkInfo = Get-Item $SourceAPK
    $apkSizeMB = [math]::Round($apkInfo.Length / 1MB, 1)
    Write-Host "APK found: $SourceAPK ($apkSizeMB MB)" -ForegroundColor Green
    
    # Step 3: Move and rename APK to apps folder
    Write-Host "`n[3/3] Moving APK to apps folder..." -ForegroundColor Yellow
    
    # Create apps folder if it doesn't exist
    if (-not (Test-Path $AppsFolder)) {
        New-Item -ItemType Directory -Path $AppsFolder -Force | Out-Null
        Write-Host "Created apps folder" -ForegroundColor Green
    }
    
    # Remove existing APK with same name if exists
    if (Test-Path $DestinationAPK) {
        Remove-Item $DestinationAPK -Force
        Write-Host "Removed existing $Name.apk" -ForegroundColor Yellow
    }
    
    # Move and rename the APK
    Move-Item -Path $SourceAPK -Destination $DestinationAPK -Force
    Write-Host "APK moved to: $DestinationAPK" -ForegroundColor Green
    
    # Verify final APK
    $finalAPK = Get-Item $DestinationAPK
    $finalSizeMB = [math]::Round($finalAPK.Length / 1MB, 1)
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "SUCCESS: $Name built!" -ForegroundColor Green
    Write-Host "APK Size: $finalSizeMB MB" -ForegroundColor Cyan
    Write-Host "Location: $DestinationAPK" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Green
    
    return $true
}

# Main execution
if ($All) {
    # Build all apps
    $apps = @("vendor_app", "admin_app", "user_app")
    $results = @{}
    
    foreach ($app in $apps) {
        $results[$app] = Build-App -Name $app
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "BUILD SUMMARY - ALL APPS" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    foreach ($app in $apps) {
        $status = if ($results[$app]) { "SUCCESS" } else { "FAILED" }
        $color = if ($results[$app]) { "Green" } else { "Red" }
        Write-Host "$app.apk : $status" -ForegroundColor $color
    }
}
elseif ($AppName -ne "") {
    # Build specific app
    $result = Build-App -Name $AppName
    
    if (-not $result) {
        exit 1
    }
}
else {
    # No app specified, show usage
    Write-Host "Usage: .\build-vendor-app.ps1 [-AppName <name>] [-BuildType <release|debug>] [-All]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\build-vendor-app.ps1 -All              # Build all apps (vendor_app, admin_app, user_app)" -ForegroundColor White
    Write-Host "  .\build-vendor-app.ps1 -AppName vendor_app    # Build only vendor_app" -ForegroundColor White
    Write-Host "  .\build-vendor-app.ps1 -AppName admin_app -BuildType debug  # Build debug version" -ForegroundColor White
    Write-Host ""
    Write-Host "Available apps: vendor_app, admin_app, user_app" -ForegroundColor Cyan
}
