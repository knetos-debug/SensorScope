# SensorScope

SensorScope is a Flutter dashboard for Pixel-class Android devices that surfaces the complete sensor and radio stack in a cockpit-style experience. Live charts, Wi-Fi/BLE scanning, GPS readouts, and CSV logging give engineers and researchers quick insight into how the device is behaving in the field.

## Features

### Dashboard
- Real-time readings (1–5 Hz) for accelerometer, gyroscope, magnetometer, compass, ambient light, barometer, battery, and GPS.
- Consistent sensor cards with tabular figures and 10-second sparklines.
- Global live indicator and per-sensor enable/disable toggles.
- CSV logging with timestamped output in `Documents/SensorScope/`.

### Network Scanners
- **Wi-Fi** – on-demand scanning with RSSI, channel, and frequency details. Handles Android throttling gracefully.
- **Bluetooth Low Energy** – live advertiser discovery with device ID, name, and RSSI.

### GPS
- High-accuracy stream with latitude, longitude, speed, altitude, and accuracy display plus status messaging for permissions/services.

### Settings
- Placeholder copy describing the phase-two roadmap.

## Project Structure
```
lib/
  core/               # Theme, permissions, CSV logger
  features/
    dashboard/        # Sensor controllers + UI widgets
    wifi/             # Wi-Fi scanner state + UI
    ble/              # BLE scanner state + UI
    gps/              # GPS tracker state + UI
    settings/         # Settings placeholder page
  widgets/            # Shared widgets (live indicator, sparkline, etc.)
```

State management uses **Riverpod**, routing relies on **go_router**, and charts are rendered via **fl_chart**.

## Getting Started

### Prerequisites
- Flutter 3.16 or newer (`flutter doctor` should report a clean Android toolchain). If you're using this development container and
  the SDK is missing, run the helper below to download and install it locally.

#### Install Flutter inside the container

```bash
./scripts/install_flutter.sh
export PATH="$PWD/.flutter-sdk/bin:$PATH"
flutter --version
```

The script downloads the stable Linux archive (configurable via environment variables) and unpacks it to `.flutter-sdk/` inside
the repository. Re-run it any time you need to update the SDK.
- Android 12+ device (Pixel 6/7/8 recommended) with developer options enabled.

### Setup
1. Fetch dependencies:
   ```bash
   flutter pub get
   ```
2. Run on a connected device:
   ```bash
   flutter run
   ```

Alternatively, execute the bootstrap helper (which also regenerates missing platform folders such as `android/` if you cloned a bare repository):
```bash
./scripts/bootstrap.sh
```

### Permissions
The app requests runtime permissions for:
- Location (required for GPS, Wi-Fi, and BLE scanning)
- Activity recognition / sensors
- Bluetooth scan/connect

If a permission is denied, the corresponding feature shows a status message and remains disabled.

### CSV Logging
- Tap **Start Logging** to create a file under `Documents/SensorScope/<timestamp>.csv`.
- Logging writes a header row with all active sensor channels and appends new samples as they arrive.
- Use **Stop Logging** to flush and close the file.

## Testing
When Flutter is available locally you can run:
```bash
flutter analyze
flutter test
```

Both commands are wired to the default lints and widget tests.

## Roadmap
Future phases will add adjustable sampling rates, dark/light themes, GNSS satellite views, wardrive automation, session replay, and export/import pipelines.
