# HOOPS Visualize Flutter Plugin

A Flutter plugin for rendering CAD files (DWG, etc.) using HOOPS Visualize SDK on macOS.

## Features

- Load and display CAD files (DWG, STEP, IGES, etc.)
- 3D navigation (orbit, pan, zoom)
- High-performance Metal rendering
- Texture-based integration with Flutter

## Requirements

- macOS 10.14+
- HOOPS Visualize SDK 2025.9.0+
- Valid HOOPS license

## Installation

1. Add the plugin to your `pubspec.yaml`:

```yaml
dependencies:
  hoops_visualize:
    path: ./hoops_visualize
```

2. Configure HOOPS SDK path in `macos/hoops_visualize.podspec`

3. Add your HOOPS license in the initialization code

## Usage

### Initialize the engine

```dart
import 'package:hoops_visualize/hoops_visualize.dart';

// Initialize with your license
await HoopsVisualizer.initialize(license: 'YOUR_HOOPS_LICENSE');
```

### Display CAD files

```dart
import 'package:hoops_visualize/hoops_visualize_view.dart';

HoopsVisualizeView(
  filePath: '/path/to/your/file.dwg',
  onLoaded: () {
    print('File loaded successfully');
  },
  onError: (error) {
    print('Error: $error');
  },
)
```

### Control the view

```dart
// Fit view to model
await HoopsVisualizer.fitView();

// Reset view
await HoopsVisualizer.resetView();

// Set view operation mode
await HoopsVisualizer.setViewOperation('orbit'); // or 'pan', 'zoom'
```

## License

This plugin is MIT licensed. HOOPS Visualize SDK requires a separate commercial license from Tech Soft 3D.
