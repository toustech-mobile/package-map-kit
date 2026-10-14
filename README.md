# Map Kit

A Flutter map widget with OpenStreetMap, map.ir, and native Android Neshan providers.

## Android Neshan SDK migration

The Android provider uses `org.neshan.maplibre:android-sdk-opengl:13.4.1`,
following [Neshan's installation guide](https://platform.neshan.org/docs/sdk/android/installation/).
It replaces the older Carto-based SDK; an old `neshan.license` does not configure
the new renderer.

Requirements:

- Android API 23 or later.
- Java/JVM 17. The example uses Kotlin 2.2.20, AGP 8.11.1, and Gradle 8.14.
- A Neshan API key configured in the consuming Android application's manifest.
- Maven Central and Google Maven repositories; no Neshan-specific Maven repository.

### Configure the example

Provide the key in the ignored `example/android/local.properties` file:

```properties
neshan.apiKey=YOUR_NESHAN_API_KEY
```

Alternatively, set `NESHAN_API_KEY` in the environment before building:

```powershell
$env:NESHAN_API_KEY = 'YOUR_NESHAN_API_KEY'
Set-Location example
flutter pub get
flutter run
```

Both example Gradle variants resolve the local property first, then the
environment variable, into the manifest placeholder `neshanApiKey`. The manifest
contains:

```xml
<meta-data
    android:name="org.maplibre.android.API_KEY"
    android:value="${neshanApiKey}" />
```

### Configure another host application

Set `minSdk = 23` or higher in the app module. Supply the same metadata inside
your host's `<application>`, using your own resource or manifest placeholder.
For example, in Kotlin DSL:

```kotlin
android {
    defaultConfig {
        minSdk = 23
        manifestPlaceholders["neshanApiKey"] =
            System.getenv("NESHAN_API_KEY") ?: ""
    }
}
```

The plugin supplies the SDK dependency and Internet permission. Do not add the
old `mobile-sdk`, `services-sdk`, or `common-sdk` artifacts alongside it. The key must allow your application ID in its Android bundle restrictions
(the example is `com.golrang.map_kit_example`); HTTP 484 indicates a scope mismatch. An
empty/missing API key is rejected when creating the native view. A real key and
network connectivity are needed to load Neshan styles and tiles.

## Usage

Import the shared widget and controller directly; `map_kit.dart` is a separate
iOS prototype rather than a shared export file.

```dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/enums/map_provider.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/models/move_model.dart';
import 'package:map_kit/ui_map.dart';

final controller = UiMapController();

Widget buildMap() => UiMap(
  mapProvider: MapProvider.neshan,
  controller: controller,
  initialCenter: const LatLng(35.6892, 51.3890),
  zoom: 13,
  markers: [
    MarkerModel(
      latitude: 35.6892,
      longitude: 51.3890,
      icon: 'end_point.svg',
      iconSize: 32,
      data: 'office',
      snippetTitle: 'Office',
    ),
  ],
  onMarkerTap: (data, point) {
    // Flutter providers return MarkerModel; Android returns string data.
    debugPrint('$data at $point');
  },
);

// Call after the map widget has attached. Commands received by Android while
// its initial style is loading wait for readiness.
Future<void> moveToOffice() async {
  await controller.moveCamera(
    MoveModel(latitude: 35.7, longitude: 51.4, zoom: 15),
  );
}
```

Neshan marker names refer to plugin Android drawables. Flutter/map.ir marker names
refer to SVG files declared by the host under `assets/icons/`; supply matching
assets if switching providers.

## Controller and overlays

`UiMap` accepts marker, circle, and polyline lists plus map tap, long press, and
overlay tap callbacks. Overlay models are in `lib/models/`.

| Controller member | Purpose |
| --- | --- |
| `addMarkers`, `removeMarkers`, `removeAllMarkers` | Marker operations |
| `addCircles`, `removeCircles`, `removeAllCircles` | Filled circles with meter radii |
| `addPolyline`, `removePolyLines`, `removeAllPolyLines` | Outlined polylines |
| `moveCamera`, `fitBounds` | Camera movement and fitting geographic points |
| `setUserLocation` | Supply a position and accuracy overlay; does not acquire GPS |
| `setDarkMode` | Change the Neshan or Flutter map theme |
| `camera` | Future containing center and zoom |

Android shapes use MapLibre annotations. Filled circles and location accuracy
are approximated by closed geodesic polygons; polylines have separate outline
and main annotations. The renderer forwards host lifecycle events and disposes
native resources. Light/dark changes restore the current overlays after loading
the new style.

## Platform status

- **Flutter / map.ir:** use `flutter_map`; dark mode selects CARTO raster tiles.
  Set `UiMap.userAgentPackageName` to your host application ID for raster
  tile requests. Raster attribution is displayed on the map. map.ir still
  has a hard-coded credential requiring separate cleanup.
- **Android Neshan:** migrated to MapLibre. Existing global channel names remain;
  commands target the most recently created map. Independent multiple-map
  control is not supported by this protocol.
- **iOS Neshan:** remains an Apple MapKit demo without the shared overlay and
  controller implementation.
- **Web:** plugin registration/platform selection are unfinished.

## Development and validation

See [DEVICE_TEST_REPORT.md](DEVICE_TEST_REPORT.md) for the Samsung SM-A325F run.

```powershell
flutter pub get
flutter analyze
flutter test

Set-Location example/android
.\gradlew.bat :map_kit:compileDebugKotlin :map_kit:testDebugUnitTest
```

See [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) for architecture, limitations,
migration verification, and reusable prompt context. See
[CHANGELOG.md](CHANGELOG.md) for breaking setup changes.
