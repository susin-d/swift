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

    function Test-SymlinkCapability {
        $tempRoot = Join-Path $env:TEMP ("flutter-symlink-check-" + [guid]::NewGuid().ToString("N"))
        $targetFile = Join-Path $tempRoot "target.txt"
        $linkFile = Join-Path $tempRoot "link.txt"

        try {
            New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
            Set-Content -Path $targetFile -Value "symlink check"
            New-Item -ItemType SymbolicLink -Path $linkFile -Target $targetFile -ErrorAction Stop | Out-Null
            return $true
        }
        catch {
            return $false
        }
        finally {
            if (Test-Path $tempRoot) {
                Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    function Show-SymlinkFixSteps {
        param(
            [string]$Name
        )

        Write-Host "Build FAILED for $Name!" -ForegroundColor Red
        Write-Host "Flutter plugin builds on Windows require symlink support." -ForegroundColor Red
        Write-Host "" 
        Write-Host "Fix options:" -ForegroundColor Yellow
        Write-Host "  1. Enable Windows Developer Mode: Settings -> Privacy & security -> For developers -> Developer Mode" -ForegroundColor White
        Write-Host "  2. Restart PowerShell and rerun this script" -ForegroundColor White
        Write-Host "  3. If needed, run PowerShell as Administrator" -ForegroundColor White
    }

    function Build-AppJob {
        param(
            [string]$Name,
            [string]$BuildType,
            [string]$ProjectRoot,
            [string]$AppsFolder
        )

        $AppDir = Join-Path $ProjectRoot $Name
        $OutputDir = Join-Path $AppDir "build\app\outputs\flutter-apk"
        $SourceAPK = Join-Path $OutputDir "app-$BuildType.apk"
        $DestinationAPK = Join-Path $AppsFolder "$Name.apk"
        $logLines = New-Object System.Collections.Generic.List[string]

        $logLines.Add("========================================")
        $logLines.Add("Building $Name Flutter App")
        $logLines.Add("========================================")
        $logLines.Add("[1/3] Building Flutter APK...")
        $logLines.Add("Running: flutter build apk --$BuildType")

        Push-Location $AppDir
        try {
            $buildResult = & flutter build apk --$BuildType 2>&1
            $buildExitCode = $LASTEXITCODE
        }
        finally {
            Pop-Location
        }

        if ($buildExitCode -ne 0) {
            $logLines.Add("Build FAILED for $Name!")
            if ($buildResult) {
                foreach ($line in ($buildResult | ForEach-Object { $_.ToString() })) {
                    $logLines.Add($line)
                }
            }

            return [PSCustomObject]@{
                App = $Name
                Success = $false
                ApkPath = $null
                ApkSizeMB = $null
                Log = $logLines
            }
        }

        $logLines.Add("Build completed successfully!")
        $logLines.Add("[2/3] Verifying APK build...")

        if (-not (Test-Path $SourceAPK)) {
            $logLines.Add("ERROR: APK not found at $SourceAPK")
            return [PSCustomObject]@{
                App = $Name
                Success = $false
                ApkPath = $null
                ApkSizeMB = $null
                Log = $logLines
            }
        }

        if (-not (Test-Path $AppsFolder)) {
            New-Item -ItemType Directory -Path $AppsFolder -Force | Out-Null
        }

        $logLines.Add("[3/3] Moving APK to apps folder...")

        if (Test-Path $DestinationAPK) {
            Remove-Item $DestinationAPK -Force
            $logLines.Add("Removed existing $Name.apk")
        }

        Move-Item -Path $SourceAPK -Destination $DestinationAPK -Force
        $finalAPK = Get-Item $DestinationAPK
        $finalSizeMB = [math]::Round($finalAPK.Length / 1MB, 1)
        $logLines.Add("APK moved to: $DestinationAPK")

        return [PSCustomObject]@{
            App = $Name
            Success = $true
            ApkPath = $DestinationAPK
            ApkSizeMB = $finalSizeMB
            Log = $logLines
        }
    }

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

        if (-not (Test-SymlinkCapability)) {
            Show-SymlinkFixSteps -Name $Name
            return $false
        }
        
        Push-Location $AppDir
        try {
            $nativeErrorPrefExists = Test-Path Variable:PSNativeCommandUseErrorActionPreference
            if ($nativeErrorPrefExists) {
                $nativeErrorPrefOriginal = $PSNativeCommandUseErrorActionPreference
                $PSNativeCommandUseErrorActionPreference = $false
            }

            try {
                $buildResult = & flutter build apk --$BuildType 2>&1
                $buildExitCode = $LASTEXITCODE
            }
            finally {
                if ($nativeErrorPrefExists) {
                    $PSNativeCommandUseErrorActionPreference = $nativeErrorPrefOriginal
                }
            }
            
            if ($buildExitCode -ne 0) {
                Write-Host "Build FAILED for $Name!" -ForegroundColor Red
                Write-Host $buildResult

                if (("$buildResult" -match "symlink support")) {
                    Write-Host "" 
                    Write-Host "Detected symlink-related Flutter failure." -ForegroundColor Yellow
                    Show-SymlinkFixSteps -Name $Name
                }

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
        # Build all apps in parallel
        $apps = @("vendor_app", "admin_app", "user_app")

        if (-not (Test-SymlinkCapability)) {
            Show-SymlinkFixSteps -Name "all apps"
            exit 1
        }

        $jobs = @()
        foreach ($app in $apps) {
            $jobs += Start-Job -Name $app -ScriptBlock {
                param($Name, $BuildType, $ProjectRoot, $AppsFolder)

                $ErrorActionPreference = "Stop"

                function Build-AppJob {
                    param(
                        [string]$Name,
                        [string]$BuildType,
                        [string]$ProjectRoot,
                        [string]$AppsFolder
                    )

                    $AppDir = Join-Path $ProjectRoot $Name
                    $OutputDir = Join-Path $AppDir "build\app\outputs\flutter-apk"
                    $SourceAPK = Join-Path $OutputDir "app-$BuildType.apk"
                    $DestinationAPK = Join-Path $AppsFolder "$Name.apk"
                    $logLines = New-Object System.Collections.Generic.List[string]

                    $logLines.Add("========================================")
                    $logLines.Add("Building $Name Flutter App")
                    $logLines.Add("========================================")
                    $logLines.Add("[1/3] Building Flutter APK...")
                    $logLines.Add("Running: flutter build apk --$BuildType")

                    Push-Location $AppDir
                    try {
                        $buildResult = & flutter build apk --$BuildType 2>&1
                        $buildExitCode = $LASTEXITCODE
                    }
                    finally {
                        Pop-Location
                    }

                    if ($buildExitCode -ne 0) {
                        $logLines.Add("Build FAILED for $Name!")
                        if ($buildResult) {
                            foreach ($line in ($buildResult | ForEach-Object { $_.ToString() })) {
                                $logLines.Add($line)
                            }
                        }

                        return [PSCustomObject]@{
                            App = $Name
                            Success = $false
                            ApkPath = $null
                            ApkSizeMB = $null
                            Log = $logLines
                        }
                    }

                    $logLines.Add("Build completed successfully!")
                    $logLines.Add("[2/3] Verifying APK build...")

                    if (-not (Test-Path $SourceAPK)) {
                        $logLines.Add("ERROR: APK not found at $SourceAPK")
                        return [PSCustomObject]@{
                            App = $Name
                            Success = $false
                            ApkPath = $null
                            ApkSizeMB = $null
                            Log = $logLines
                        }
                    }

                    if (-not (Test-Path $AppsFolder)) {
                        New-Item -ItemType Directory -Path $AppsFolder -Force | Out-Null
                    }

                    $logLines.Add("[3/3] Moving APK to apps folder...")

                    if (Test-Path $DestinationAPK) {
                        Remove-Item $DestinationAPK -Force
                        $logLines.Add("Removed existing $Name.apk")
                    }

                    Move-Item -Path $SourceAPK -Destination $DestinationAPK -Force
                    $finalAPK = Get-Item $DestinationAPK
                    $finalSizeMB = [math]::Round($finalAPK.Length / 1MB, 1)
                    $logLines.Add("APK moved to: $DestinationAPK")

                    return [PSCustomObject]@{
                        App = $Name
                        Success = $true
                        ApkPath = $DestinationAPK
                        ApkSizeMB = $finalSizeMB
                        Log = $logLines
                    }
                }

                Build-AppJob -Name $Name -BuildType $BuildType -ProjectRoot $ProjectRoot -AppsFolder $AppsFolder
            } -ArgumentList $app, $BuildType, $ProjectRoot, $AppsFolder
        }

        Wait-Job -Job $jobs | Out-Null

        $results = @{}
        foreach ($job in $jobs) {
            $jobResult = Receive-Job -Job $job
            Remove-Job -Job $job -Force | Out-Null

            if ($null -eq $jobResult) {
                $results[$job.Name] = [PSCustomObject]@{
                    App = $job.Name
                    Success = $false
                    ApkPath = $null
                    ApkSizeMB = $null
                    Log = @("Build FAILED for $($job.Name)!", "No result returned from background job.")
                }
                continue
            }

            $results[$jobResult.App] = $jobResult
        }

        foreach ($app in $apps) {
            if ($results.ContainsKey($app)) {
                $logLines = $results[$app].Log
                if ($logLines) {
                    Write-Host ""
                    foreach ($line in $logLines) {
                        Write-Host $line
                    }
                }
            }
        }
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "BUILD SUMMARY - ALL APPS" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        
        foreach ($app in $apps) {
            $appSuccess = $false
            if ($results.ContainsKey($app)) {
                $appSuccess = [bool]$results[$app].Success
            }

            $status = if ($appSuccess) { "SUCCESS" } else { "FAILED" }
            $color = if ($appSuccess) { "Green" } else { "Red" }
            Write-Host "$app.apk : $status" -ForegroundColor $color
        }

        if (($apps | Where-Object { -not ($results.ContainsKey($_) -and [bool]$results[$_].Success) }).Count -gt 0) {
            exit 1
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
        Write-Host "Usage: .\build-app.ps1 [-AppName <name>] [-BuildType <release|debug>] [-All]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Cyan
        Write-Host "  .\build-app.ps1 -All              # Build all apps (vendor_app, admin_app, user_app)" -ForegroundColor White
        Write-Host "  .\build-app.ps1 -AppName vendor_app    # Build only vendor_app" -ForegroundColor White
        Write-Host "  .\build-app.ps1 -AppName admin_app -BuildType debug  # Build debug version" -ForegroundColor White
        Write-Host ""
        Write-Host "Available apps: vendor_app, admin_app, user_app" -ForegroundColor Cyan
    }
