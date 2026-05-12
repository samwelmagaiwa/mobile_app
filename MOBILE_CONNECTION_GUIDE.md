# Mobile Connection Guide

## Overview
To run the Boda Mapato mobile app and connect it to your local Laravel backend, you need to configure the API base URL in `lib/config/api_config.dart`.

## API Configuration (`api_config.dart`)

The `api_config.dart` file uses an `Environment` mixin to manage different connection types.

### 1. Running on Android Emulator
When running on an Android emulator, the emulator sees the host machine (your computer) at a special IP address: `10.0.2.2`.

**Configuration:**
- Set `_environment = Environment.emulator;` in `ApiConfig`.
- The `baseUrl` will automatically resolve to `http://10.0.2.2:8000/api`.

### 2. Running on Physical Device (Phone)
When running on a real phone, the phone and your computer must be on the **same Wi-Fi network**. You need to use your computer's Local IP address.

**Steps:**
1. Find your computer's IP address (e.g., `192.168.1.XX` or `172.16.X.X`).
2. Update the `Environment.network` case in `ApiConfig` with your IP.
3. Set `_environment = Environment.network;` in `ApiConfig`.

**Configuration in `api_config.dart`:**
```dart
case Environment.network:
  // Update this IP to your machine's LAN IP
  return "http://192.168.1.XX:8000/api";
```

### 3. Local/Web/Desktop
Use `Environment.local` for web or desktop builds running on the same machine as the backend.

---

## Emulator Integration with VS Code / IDE

To run your Flutter app on an Android emulator from VS Code, follow these steps:

### 1. Set Up Android Emulator (AVD)
If you haven't created an emulator yet:
1. Open **Android Studio**.
2. Go to **Device Manager** (usually a phone icon on the right toolbar or under `Tools > Device Manager`).
3. Click **Create Device**.
4. Select a hardware profile (e.g., Pixel 7) and click **Next**.
5. Select a system image (e.g., API 34) and click **Next**.
6. Give it a name and click **Finish**.

### 2. Start the Emulator
You can start the emulator directly from Android Studio's Device Manager by clicking the **Play** button.

### 3. Connect VS Code to the Emulator
1. Open your project in **VS Code**.
2. Look at the **Status Bar** (the blue/purple bar at the very bottom of the window).
3. On the right side, you will see the name of the current device (e.g., "Windows (windows-x64)" or "No Device").
4. **Click on the device name**.
5. A list of available devices will appear at the top. Select your **Android Emulator**.
6. Once selected, the status bar will update to show your emulator name.

### 4. Run the Application
1. Open `lib/main.dart`.
2. Press **F5** (or go to `Run > Start Debugging`).
3. The app will build and launch on your emulator.

---

## Backend Preparation
Ensure your Laravel backend is running and accessible on your network:
`php artisan serve --host=0.0.0.0`
Using `--host=0.0.0.0` allows connections from other devices on your network.
