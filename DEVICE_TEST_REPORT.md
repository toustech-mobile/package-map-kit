# Samsung Android validation — 2026-10-14

Neshan Android functional checks passed on the specified Samsung, including
rotation and background/resume after fixes. All 15 automated tests passed.
OpenStreetMap raster access remains blocked on this connection; map.ir tiles render.

## Environment

- Device: Samsung SM-A325F, Android 13; ADB serial `RZ8TA0AXTPA`.
- Application: `com.golrang.map_kit_example`.
- Flutter 3.47.6 / Dart 3.13.5, JVM 17, AGP 8.11.1, Gradle 8.14,
  Kotlin 2.2.20; Neshan MapLibre OpenGL SDK 13.4.1.
- Normal project dependency resolution and builds were used.
- Debug APK and minified arm64 release APK built and installed successfully.
  Final release size reported by Flutter: 47.6 MB.

## Automated results

| Suite | Passed | Coverage |
| --- | ---: | --- |
| Root Flutter tests | 6 | Native method payloads/errors; Flutter theme changes; clearing circle popup hit targets |
| Android Gradle unit tests | 5 | Geometry/numeric decoding and plugin dispatch/error behavior |
| Example widget test | 1 | Actual provider selector and control panel |
| Samsung integration tests | 3 | Native rendering readiness, overlays/events, camera/themes, disposal, gestures and invalid-input recovery |
| **Total** | **15** | All listed tests passed |

The three integration scenarios passed together again after the TextureView fix:

1. Initial style readiness; map tap/long press; marker, circle and polyline
   insertion/removal and callbacks; mock user position; four light/dark reloads
   retaining overlays; clear-all; camera movement/readback; empty, single and
   multiple point bounds.
2. Three native map disposal/recreation cycles, with exactly one tap callback per
   cycle and no stale Dart subscription callbacks.
3. Pan and pinch zoom; a nonfinite camera coordinate returns `INVALID_ARGUMENT`,
   and the next camera request still succeeds.

Native input tests use current monotonic timestamps. Pinch initiation must exceed
MapLibre's scale-speed threshold; very slow synthetic pinches are ignored by the
SDK. A brisk two-finger OS-level injected pinch was also checked in release.

## Release checks and fixes

- Authenticated Neshan basemap, Persian labels, sprites and marker resources render.
- Initial key requests returned HTTP 484 (bundle-scope mismatch). After the user
  updated the restrictions for the example bundle, the same key returned HTTP 200
  and the real basemap loaded. Keys remain in ignored local properties.
- Visually checked marker assets after release resource shrinking, filled circles,
  outlined polylines, mock user location, bounds/camera controls and dark style.
- Final captured application logs contained no `FATAL EXCEPTION`,
  `Unhandled Exception` or `E/flutter` entries. Android exit history contained
  installer/force-stop exits and no recorded crash in the inspected history.
- Final release returned from a sustained background interval with its Neshan
  viewport intact; an OS-level pinch changed zoom from 15 to 16.3.
- Found a native viewport failure after landscape-to-portrait rotation using
  SurfaceView. Enabled MapLibre's TextureView mode; checked the final release in
  settled landscape and portrait, with the map filling both viewports.
- Fixed Flutter controller theme binding and stale invisible circle popup targets.
- Fixed the example's shared marker resource name and marker callback label.
  Theme changes now await completion without rebuilding away current overlays.
- Provider switching to map.ir day tiles was visually checked successfully.
- Flutter/OpenStreetMap initially displayed blocked tiles with a generic client
  identity. Added configurable `UiMap.userAgentPackageName`, set the actual
  example application ID, and display raster provider/data attribution.
  The identified final release still receives/displays the blocked tile image;
  OpenStreetMap raster access remains unresolved on this connection. No cache
  bypass, proxy, alternate identity rotation or service substitution was used.
  The application identity change follows the provider requirement:
  https://operations.osmfoundation.org/policies/tiles/
- Replaced the stale example template assertion with its actual UI smoke test.
- Disabled example Kotlin incremental compilation for the observed Windows C:/D:
  cross-drive cache failure. No dependency-repository workaround is committed.

## Reproduce

From the repository root:

```powershell
flutter pub get
flutter test
Set-Location example
flutter pub get
flutter test test/widget_test.dart
flutter test integration_test/neshan_device_test.dart -d RZ8TA0AXTPA
flutter build apk --release --target-platform android-arm64
Set-Location android
.\gradlew.bat :map_kit:testDebugUnitTest
```

The example reads `neshan.apiKey` from `example/android/local.properties`, or
`NESHAN_API_KEY` from the environment. The key must authorize the application ID.
No actual key should be pasted into reports, prompts or tracked source.

## Scope and remaining work

- `flutter analyze --no-pub`: no errors; 3 mutable-widget warnings and 17 info
  notices, including deprecations, print usage and mutable test-list literals.
  The analyzer exits nonzero; this is not a clean-lint result.
- The installed Flutter warns that the chosen Gradle/AGP/Kotlin versions will
  lose support in a future Flutter release. Current debug/release builds pass.
- Vendor dark-style color warnings and expected tile cancellation messages were
  observed without preventing rendering.
- map.ir day tiles render, but its existing hard-coded credential still needs
  host-owned configuration before distribution.
- The public method/event channels still target the latest native map. Independent
  simultaneous native maps are not covered or supported by this protocol.
- Controller overlay ownership across parent rebuilds/provider switches remains
  limited. Native snippets, polyline headings, real GPS acquisition, iOS and web
  support are not established by these Android results.
- This is functional validation on one physical phone, not a broad device matrix,
  exhaustive performance benchmark, offline/network-loss or process-death test.

## Device cleanup

Original stay-awake and rotation settings were restored and verified. The
temporary shell touch helper and UI hierarchy dump were removed. The final
release remains installed and running with Neshan selected in light mode.

## Local evidence

Generated evidence is under ignored `build/device-validation/`; it is local test
output, not a committed credential-bearing artifact. Relevant images include:

- `release-final-initial.png`, `release-final-polyline.png`, `release-final-dark.png`
- `release-texture-landscape.png`, `release-texture-portrait.png`
- `release-final-resume-verified.png`, `release-final-texture-pinch.png`
- `release-final-mapir-day.png`, `release-final-flutter-identified.png`

Sanitized logs redact the configured Neshan key and API-key query parameters.
The release APK is `example/build/app/outputs/flutter-apk/app-release.apk`.
Use PROJECT_CONTEXT.md as reusable architecture and migration context.
