---
name: build-and-install
description: >-
  Builds the Android APK and installs/launches it on a connected mobile device
  via wireless ADB or USB. Use whenever the user asks to build and install, deploy,
  run on phone, or test the app on their mobile device.
---

# Build and Install Skill

This skill guides the process of compiling the Conduit Android application and deploying it directly to a connected mobile device (via Wireless ADB or USB).

## Workflow

### 1. Automated One-Step Deploy

Run the project script, which handles APK compilation, device discovery, installation, and app launch:

```bash
./scripts/build_and_install.sh
```

### 2. Manual Step-by-Step Procedure

If running steps manually or debugging connection issues:

#### A. Verify Device Connection
Check that the phone is visible in ADB:
```bash
adb devices
```

If using Wireless ADB and the device is not listed:
```bash
# Discover active wireless ADB services
adb mdns services

# Connect to the discovered _adb-tls-connect endpoint (e.g., 192.168.1.29:<port>)
adb connect <ip>:<port>
```

#### B. Build the Signed APK
Build the release APK:
```bash
flutter build apk
```
*Note: The project configuration in `android/app/build.gradle.kts` automatically falls back to debug signing when `key.properties` is absent, allowing local installs on developer devices.*

#### C. Install the APK
Install or update the APK on the device:
```bash
# If one device is connected:
adb install -r build/app/outputs/flutter-apk/app-release.apk

# If multiple devices or wireless endpoint:
adb -s <device_id_or_ip:port> install -r build/app/outputs/flutter-apk/app-release.apk
```

#### D. Launch the Application
Start Conduit on the phone:
```bash
adb shell am start -n app.cogwheel.conduit/.MainActivity
```

---

## Troubleshooting Wireless ADB

1. **Port Changed**:
   - In Android Developer Options, the Wireless Debugging port changes when Wi-Fi reconnects or is toggled.
   - Run `adb mdns services` to see the current active `_adb-tls-connect` port.

2. **First-Time Pairing**:
   - If pairing a new device or if authentication was revoked:
     ```bash
     adb pair <ip>:<pairing_port> <6_digit_code>
     ```
   - Note: The pairing port (from the "Pair device" popup) is different from the connection port.
