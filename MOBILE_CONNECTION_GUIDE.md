# Mobile Connection Guide

## Overview
To run the Boda Mapato mobile app and connect it to your local Laravel backend, you need to configure the API base URL in the configuration file.

**Target File:** `boda_mapato/lib/config/api_config.dart`

---

## API Configuration Steps

The `api_config.dart` file manages connection types via the `Environment` mixin.

### 1. Identify your PC's LAN IP address
Run this command in your computer's terminal (PowerShell):
```powershell
Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} | Select-Object IPAddress
```
*Look for an IP like `192.168.137.XXX` or `192.168.1.XXX`.*

### 2. Update `api_config.dart`
In `boda_mapato/lib/config/api_config.dart`, update these lines:

1.  Set the environment to **network**:
    ```dart
    static const String _environment = Environment.network;
    ```
2.  Update the **network** case with your IP from Step 1:
    ```dart
    case Environment.network:
      return "http://192.168.137.226:8000/api"; // <-- Update this IP
    ```

---

## Running on Physical Device

### Prerequisites
1.  **Same Network**: Your phone and computer MUST be on the same Wi-Fi.
2.  **Developer Mode**: Enable "Developer Mode" and "USB Debugging" on your phone.
3.  **Backend Host**: Start your Laravel server with the `--host` flag:
    ```powershell
    php artisan serve --host=0.0.0.0
    ```

### Execution
Run the app targeting your device:
```powershell
flutter run
```
*If multiple devices are connected, use `flutter run -d <DEVICE_ID>`.*

---

## ⚠️ Troubleshooting Build Errors (Windows)

If you encounter errors during `assembleDebug` on Windows:

1.  **Application Control / Smart App Control**:
    If you see "An Application Control policy has blocked this file," it means Windows is blocking unsigned binaries (`dartaotruntime.exe`).
    - **Fix**: Run the terminal as **Administrator** or ensure you are on a stable Flutter version (run `flutter upgrade`).

2.  **Developer Mode (Windows Settings)**:
    If you see "Building with plugins requires symlink support":
    - **Fix**: Go to **Windows Settings > System > For developers** and turn **Developer Mode** on.

3.  **Flutter Startup Lock**:
    - **Fix**: Run `Remove-Item -Force C:\flutter\bin\cache\lockfile` if the process hangs.
