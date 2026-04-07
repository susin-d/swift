# Running Swift Apps on Emulators

## Quick Start

### Option 1: Simple Single Emulator (Easiest)
```powershell
.\launch-apps.ps1
```
This will:
- Show you connected devices
- Let you select which app to run (user_app, vendor_app, or admin_app)
- Run the app on an existing emulator (emulator-5554 by default)

### Option 2: Multiple Emulators (Professional)
```powershell
.\launch-emulators.ps1 -RunApps
```
This will:
- Create 3 Android Virtual Devices (AVDs) if they don't exist
- Launch all 3 emulators in parallel
- Run each app on its own emulator
- Keep all 3 apps running simultaneously for testing

### Option 3: Setup Emulators Only
```powershell
.\launch-emulators.ps1 -CreateOnly
```
This will:
- Create 3 emulators but not launch them
- Useful if you want to launch them manually later

## Emulator Names & Ports

| App | Emulator Name | Port |
|-----|--------------|------|
| User App | swift-user-emulator | 5554 |
| Vendor App | swift-vendor-emulator | 5556 |
| Admin App | swift-admin-emulator | 5558 |

## Manual Emulator Commands

If you prefer to run emulators manually:

```powershell
# List all available emulators
$ANDROID_HOME/emulator/emulator -list-avds

# Start a specific emulator
$ANDROID_HOME/emulator/emulator -avd swift-user-emulator -port 5554

# In another terminal, run the app
cd c:\project\swift\user_app
flutter run -d emulator-5554
```

## Viewing Connected Devices
```powershell
$env:ANDROID_HOME/platform-tools/adb devices
```

## Stopping Emulators

- Close the emulator windows, or
- Run: `adb emu kill` (from any terminal)

## Troubleshooting

### Emulators Won't Start
- Make sure you have the Android NDK and system images installed
- Check that `ANDROID_HOME` is set correctly:
  ```powershell
  $env:ANDROID_HOME
  ```
- If not set, add to your PowerShell profile or environment variables

### Apps Won't Install
- Make sure your device is ready: `adb devices`
- Try: `flutter clean` before running again
- Check that the app's `android/app/build.gradle` is valid

### Port Already in Use
- Check running emulators: `adb devices`
- Kill port: `adb -s emulator-5554 emu kill`

## Folder Structure
```
c:\project\swift\
├── launch-emulators.ps1    # Multi-emulator launcher
├── launch-apps.ps1         # Simple app launcher
├── user_app/
├── vendor_app/
└── admin_app/
```

## PowerShell Execution Policy

If you get an execution policy error, run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Then try again:
```powershell
.\launch-emulators.ps1 -RunApps
```
