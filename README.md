# Map Kit

A Flutter map widget with OpenStreetMap, map.ir, and native Android/iOS Neshan providers.

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

## iOS Neshan setup

The iOS provider uses Neshan's official MapLibre Native **6.28.0** binary,
following the [current iOS guide](https://platform.neshan.org/docs/sdk/ios/neshan-ios-sdk-getting-started/)
and [installation instructions](https://platform.neshan.org/docs/sdk/ios/installation/).
It replaces the Apple Maps prototype. The old `NeshanMobileSDK` / Carto pods
and `neshan.license` are not used.

Requirements:

- iOS 13 or later and a macOS/Xcode build environment.
- A Neshan API key authorized for your iOS application's bundle identifier.
- Network access to download the SDK and load Neshan styles/tiles.

This is a private package (`publish_to: none`). Its iOS API key lives in
`ios/map_kit/Sources/map_kit/NeshanConfiguration.swift`, which is compiled by
both CocoaPods and SwiftPM. The plugin sets `MLNSettings.apiKey` before creating
the native map. Consuming apps and the example do not need an API key in their
Info.plist or an extra Xcode configuration file.

Update the key in that package configuration when rotating it. The configured
key must authorize each consuming application's bundle identifier. The example's
iOS identifier is `com.golrang.mapKitExample` (different from its Android ID).

**Swift Package Manager:** the plugin manifest downloads the official Neshan
archive automatically using a pinned SHA-256 checksum. Do not separately add
upstream MapLibre or the local MapLibre package to the same target; the plugin
already supplies the Neshan build and its authentication support.

**CocoaPods:** set `platform :ios, '13.0'` in your host Podfile. The plugin's
podspec downloads and verifies the same SDK using `ios/prepare_sdk.rb` before
resolving the vendored framework. This also handles Flutter's local plugin
pods, for which CocoaPods skips `prepare_command`. The extracted framework is
cached in the plugin's ignored `ios/Frameworks/` directory; no extra map pod
declaration is needed. The first install requires `curl`, `unzip`, and access
to `static.neshan.org`; later installs reuse the cached version.

Then, on a Mac:

```sh
cd example
flutter pub get
flutter build ios --simulator
flutter run -d YOUR_IOS_DEVICE_ID
```

The shared `UiMap` and `UiMapController` APIs work on both native providers.
iOS receives the initial camera, theme and overlays and uses the same method
and event protocol as Android. Commands accepted during style loading wait
for readiness, and style changes restore overlays. A style load that fails or
times out returns `STYLE_LOAD_FAILED`; use `setDarkMode` to retry after
correcting network/key configuration. Missing keys or invalid creation inputs
return `MAP_INITIALIZATION_FAILED` on controller calls.

On iOS, marker SVGs are read from the same host `assets/icons/` directory used
by Flutter maps and converted to PNGs at the display scale. Missing files fall
back to a matching iOS asset-catalog image, then a native pin. Marker content
supports an SVG asset or text. Overlay callback metadata is a string, matching
Android. Circles use geodesic polygons; polylines include their outline.

`setUserLocation` only draws a supplied position and accuracy circle. The
plugin does not request GPS or location permission. Hosts that acquire a real
location must configure their own permission flow and purpose string.

The Swift implementation and packaging still require an Xcode build and real
iOS validation. See [IOS_SUPPORT_REVIEW.md](IOS_SUPPORT_REVIEW.md) for the exact
checks completed here and the remaining device checklist.

### Apple Maps appears after selecting Neshan

The current native plugin creates only `MLNMapView`; it has no Apple Maps
renderer or fallback. An Apple logo means the consuming app is displaying
another native implementation or another map widget, even if its Dart package
revision is current.

The iOS view now uses `com.golrang.map_kit/neshan_map_view`. Before creating it,
the Dart widget checks the compiled plugin's `getRendererInfo` response for
`neshan-maplibre` and the matching view/protocol. Older or incompatible native
builds produce `NESHAN_IOS_PLUGIN_MISMATCH` instead of opening the former
`map_kit_view` Apple Maps demo. The native plugin retains the old identifier
as an alias to Neshan for older Dart callers.

`MissingPluginException` on `com.example.example/method_channel` means its
native handlers are absent in the running Flutter engine. The current plugin
registers that channel before map creation. Controller calls now verify native
identity too, so even calls made early report the registration mismatch clearly.

After updating this package, **stop the consuming app completely** and rebuild
it on the Mac. Hot reload and hot restart do not replace compiled Swift code.
Run these commands from the consuming application's directory:

```sh
flutter clean
flutter pub get
```

For CocoaPods builds, also run `pod install` from that app's `ios` directory;
then run `flutter run -d YOUR_IOS_DEVICE_ID` from the app directory. SwiftPM
builds resolve packages through Xcode/Flutter and do not need `pod install`.

If Apple Maps still appears with the rebuilt plugin, inspect the consuming
app's provider-switch widget. It should actually build
`UiMap(mapProvider: MapProvider.neshan, ...)`, rather than an app-owned Apple
Maps widget or a copied `UiKitView` pointing at `map_kit_view`.
If the command channel remains missing, check that the app calls
`GeneratedPluginRegistrant.register(with: ...)` for the Flutter engine that
displays the map, including any custom or additional engines.

## Usage

Import the shared widget and controller directly.

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
    // Flutter providers return MarkerModel; native providers return string data.
    debugPrint('$data at $point');
  },
);

// Call after the map widget has attached. Commands received by native maps while
// its initial style is loading wait for readiness.
Future<void> moveToOffice() async {
  await controller.moveCamera(
    MoveModel(latitude: 35.7, longitude: 51.4, zoom: 15),
  );
}
```

Android Neshan marker names refer to plugin drawables. iOS Neshan and
Flutter/map.ir use SVG files declared by the host under `assets/icons/`;
supply matching assets if switching providers.

## Flutter map theme

`MapProvider.flutter` uses a bundled Google Maps-inspired vector theme by
default: light gray land, green parks, blue water, white streets, yellow main
roads and gray labels. `isDarkMode` / `controller.setDarkMode` selects the
matching dark theme while preserving the camera and overlays. This uses
OpenFreeMap / OpenMapTiles data; it is not the Google Maps service.

Map.ir does not receive this theme and keeps its own raster tiles in either
mode. Neshan retains its existing native styles and theme controls.

No extra style setup is needed in the consuming app. Colors are defined in
`assets/maps/google-light.json` and `assets/maps/google-dark.json`. Optional
`UiMap.vectorStyle` accepts `VectorMapStyle(uri: ..., darkUri: ...)` for a custom
MapLibre JSON document (HTTPS or `asset://...`); it only applies to Flutter.
Set `vectorStyle: null` to retain the original Flutter OSM/CARTO raster tiles.
The vector renderer requires Flutter 3.27+ / Dart 3.6+ and uses Flutter fonts
for labels. Its remote source needs network access.

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

- **Flutter:** uses `flutter_map` with a Google Maps-inspired vector theme.
  The optional raster fallback uses OSM/CARTO tiles.
- **map.ir:** uses `flutter_map` with its original map.ir raster tiles.
  Set `UiMap.userAgentPackageName` to your host application ID for raster
  tile requests. Raster attribution is displayed on the map. map.ir still
  has a hard-coded credential requiring separate cleanup.
- **Android Neshan:** migrated to MapLibre. Existing global channel names remain;
  commands target the most recently created map. Independent multiple-map
  control is not supported by this protocol.
- **iOS Neshan:** implemented with Neshan's MapLibre SDK, shared controller,
  overlays, theme switching and callbacks. SDK checksum and framework slices
  inspected; Flutter iOS channel tests pass. Swift compilation and real-device
  validation remain outstanding. Global commands target the newest live map.
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
