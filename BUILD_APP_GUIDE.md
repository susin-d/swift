# Flutter App Build Script Guide

## Overview

The `build-app.ps1` PowerShell script automates building Flutter APK files for the Campus Food project. It builds the app, verifies the build, and moves the APK to the `apps` folder with the folder name as the filename.

When `-All` is used, the script builds `vendor_app`, `admin_app`, and `user_app` in parallel using background jobs.

## Prerequisites

- Flutter SDK installed and configured
- Android SDK configured
- PowerShell 5.0 or later (Windows)
- Windows symlink support enabled (Developer Mode recommended)
- Run from project root: `C:\project\food`

## Quick Start

```powershell
# Build all apps at once
.\build-app.ps1 -All

# Build a specific app
.\build-app.ps1 -AppName vendor_app
```

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-AppName` | string | No | Name of the app to build: `vendor_app`, `admin_app`, or `user_app` |
| `-BuildType` | string | No | Build type: `release` (default) or `debug` |
| `-All` | switch | No | Build all three apps sequentially |

## Examples

### Build All Apps

```powershell
.\build-app.ps1 -All
```

This builds:
1. vendor_app → `apps/vendor_app.apk`
2. admin_app → `apps/admin_app.apk`
3. user_app → `apps/user_app.apk`

Note: The three builds are started in parallel to reduce total build time.

### Build Single App (Release)

```powershell
.\build-app.ps1 -AppName vendor_app
.\build-app.ps1 -AppName admin_app
.\build-app.ps1 -AppName user_app
```

### Build Single App (Debug)

```powershell
.\build-app.ps1 -AppName vendor_app -BuildType debug
```

### View Usage Help

```powershell
.\build-app.ps1
```

## Output

The script:
1. **Runs** `flutter build apk --release` or `flutter build apk --debug`
2. **Verifies** the APK exists at `build\app\outputs\flutter-apk\app-<type>.apk`
3. **Moves** the APK to the `apps` folder
4. **Renames** it using the app folder name (e.g., `vendor_app.apk`)

## Output Locations

| App | APK Location |
|-----|--------------|
| vendor_app | `apps/vendor_app.apk` |
| admin_app | `apps/admin_app.apk` |
| user_app | `apps/user_app.apk` |

## Troubleshooting

### Flutter not found
Ensure Flutter is in your PATH:
```powershell
# Verify Flutter is installed
flutter --version
```

### Build fails
Check Android SDK configuration:
```powershell
flutter doctor -v
```

### Building with plugins requires symlink support
If Flutter fails with `Building with plugins requires symlink support`, enable symlink capability on Windows:
```text
Settings -> Privacy & security -> For developers -> Developer Mode
```

Then restart PowerShell and rerun:
```powershell
.\build-app.ps1 -All
```

If Developer Mode is not available in your environment, run PowerShell as Administrator.

### Permission error
If you get a permission error, run PowerShell as Administrator or enable script execution:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Script Location

```
C:\project\food\build-app.ps1
```
