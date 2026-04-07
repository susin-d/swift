# Launch three emulator instances and run three Flutter apps (one app per emulator).
# Usage:
#   .\launch-emulators.ps1
#   .\launch-emulators.ps1 -AvdName "Medium_Phone_API_36.1"

param(
    [string]$AvdName,
    [switch]$Headless
)

function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warn { Write-Host $args -ForegroundColor Yellow }
function Write-Err { Write-Host $args -ForegroundColor Red }

function Resolve-AndroidHome {
    if ($env:ANDROID_HOME -and (Test-Path $env:ANDROID_HOME)) {
        return $env:ANDROID_HOME
    }
    if ($env:ANDROID_SDK_ROOT -and (Test-Path $env:ANDROID_SDK_ROOT)) {
        return $env:ANDROID_SDK_ROOT
    }

    $candidates = @(
        "$env:USERPROFILE\AppData\Local\Android\Sdk",
        "C:\Android\Sdk",
        "C:\Android\sdk"
    )

    foreach ($path in $candidates) {
        if (Test-Path $path) {
            return $path
        }
    }
    return $null
}

function Wait-ForBoot {
    param(
        [string]$AdbPath,
        [string]$DeviceId,
        [int]$TimeoutSeconds = 240
    )

    $elapsed = 0
    while ($elapsed -lt $TimeoutSeconds) {
        $state = (& $AdbPath -s $DeviceId get-state 2>$null).Trim()
        if ($state -eq "device") {
            $boot = (& $AdbPath -s $DeviceId shell getprop sys.boot_completed 2>$null).Trim()
            if ($boot -eq "1") {
                return $true
            }
        }
        Start-Sleep -Seconds 3
        $elapsed += 3
    }
    return $false
}

$androidHome = Resolve-AndroidHome
if (-not $androidHome) {
    Write-Err "Android SDK not found. Set ANDROID_HOME or ANDROID_SDK_ROOT."
    exit 1
}

$emulatorExe = Join-Path $androidHome "emulator\emulator.exe"
$adbExe = Join-Path $androidHome "platform-tools\adb.exe"

if (-not (Test-Path $emulatorExe)) {
    Write-Err "Emulator executable not found: $emulatorExe"
    exit 1
}
if (-not (Test-Path $adbExe)) {
    Write-Err "ADB executable not found: $adbExe"
    exit 1
}

$availableAvds = & $emulatorExe -list-avds
if (-not $availableAvds -or $availableAvds.Count -eq 0) {
    Write-Err "No AVD found. Create one in Android Studio Device Manager first."
    exit 1
}

if (-not $AvdName) {
    $AvdName = $availableAvds[0]
}

if ($availableAvds -notcontains $AvdName) {
    Write-Err "AVD '$AvdName' not found. Available: $($availableAvds -join ', ')"
    exit 1
}

$workspaceRoot = "C:\project\swift"
$appRuns = @(
    @{ Name = "User App"; Dir = "user_app"; Port = 5554; DeviceId = "emulator-5554" },
    @{ Name = "Vendor App"; Dir = "vendor_app"; Port = 5556; DeviceId = "emulator-5556" },
    @{ Name = "Admin App"; Dir = "admin_app"; Port = 5558; DeviceId = "emulator-5558" }
)

Write-Info "========================================="
Write-Info "Swift 3x Emulator + 3x App Launcher"
Write-Info "========================================="
Write-Info "SDK: $androidHome"
Write-Info "AVD: $AvdName"
Write-Info ""

Write-Info "Starting 3 emulator instances..."
foreach ($run in $appRuns) {
    $args = @("-avd", $AvdName, "-port", $run.Port, "-read-only", "-no-snapshot-load")
    if ($Headless) {
        $args += @("-no-window", "-gpu", "swiftshader_indirect")
    }

    $proc = Start-Process -FilePath $emulatorExe -ArgumentList $args -PassThru
    Write-Success "Started $($run.DeviceId) [PID $($proc.Id)]"
}

Write-Info ""
Write-Info "Waiting for emulators to finish booting..."
foreach ($run in $appRuns) {
    $ready = Wait-ForBoot -AdbPath $adbExe -DeviceId $run.DeviceId
    if ($ready) {
        Write-Success "$($run.DeviceId) is ready"
    } else {
        Write-Err "Timed out waiting for $($run.DeviceId)"
        exit 1
    }
}

Write-Info ""
Write-Info "Launching apps in separate PowerShell windows..."
foreach ($run in $appRuns) {
    $appDir = Join-Path $workspaceRoot $run.Dir
    if (-not (Test-Path $appDir)) {
        Write-Err "Missing app directory: $appDir"
        exit 1
    }

    $cmd = "Set-Location '$appDir'; flutter pub get; flutter run -d $($run.DeviceId)"
    Start-Process -FilePath "powershell.exe" -ArgumentList @("-NoExit", "-Command", $cmd) | Out-Null
    Write-Success "Launched $($run.Name) on $($run.DeviceId)"
}

Write-Info ""
Write-Success "Done. Three emulators and three apps are launching now."
Write-Info "Tip: To stop an emulator: `adb -s emulator-5554 emu kill` (change device id as needed)."
