# iOS Neshan implementation and validation

Updated 2026-10-24. Implemented on Windows; iOS compilation and device
validation remain outstanding.

## SDK choice and correction to the original review

The user selected Neshan's native iOS SDK and supplied the
[current getting-started guide](https://platform.neshan.org/docs/sdk/ios/neshan-ios-sdk-getting-started/).
That guide describes a modern MapLibre-based SDK. The original review relied
on obsolete Carto/NTMapView examples; its conclusion that only the legacy SDK
was available was incorrect.

The implementation follows the current
[installation guide](https://platform.neshan.org/docs/sdk/ios/installation/),
[marker guide](https://platform.neshan.org/docs/sdk/ios/features/ios-native-sdk-add-marker/),
[line guide](https://platform.neshan.org/docs/sdk/ios/features/ios-native-sdk-draw-line/), and
[style guide](https://platform.neshan.org/docs/sdk/ios/features/ios-native-sdk-change-map-style/).

## Implemented behavior

| Area | Implementation |
| --- | --- |
| Renderer | Official Neshan MapLibre 6.28.0, imported as `MapLibre`; no Apple MapKit demo |
| Authentication | Host `MLNApiKey` in Info.plist; no legacy license file |
| Creation | Initial center, zoom, theme, markers, circles and polylines forwarded through `UiKitView` |
| Controller | Marker/circle/polyline add, remove and clear; supplied user position and accuracy; camera read/move, bounds, theme |
| Events | Map tap/long press, marker/circle/polyline taps using the existing shared event channel |
| Markers | Host SVGs rasterized to PNG at display scale; native asset image/pin fallback; SVG or text content and marker callouts |
| Shapes | Closed 96-segment geodesic circles, separate borders, outlined polylines and projected hit testing |
| Theme | Neshan light/dark URLs; camera retained and annotations restored after loading |
| Readiness | Commands queue while style/layout initializes; 45-second timeout, failure and disposal completion paths |
| Lifecycle | Weak native-view registry; dispose queued replies and renderer on view/engine release; cancel Dart event subscriptions |

Existing compatibility limits remain: commands target the newest live native
map, overlay removal matches coordinates (or a line's first point), and native
overlay callback metadata is a string. Independent multi-map routing and
general declarative updates after creation are outside this change. Overlay
mutations currently rebuild the owned annotation collection; large overlay
sets should be profiled on device.

`setUserLocation` draws supplied data without acquiring GPS or requesting
permission. The example's explicit location-service action has a purpose string.

## Packaging and SDK evidence

The official archive was downloaded from:

`https://static.neshan.org/sdk/maplibre/ios/MapLibre-6.28.0.zip`

Its inspected contents include `Package.swift` and `MapLibre.xcframework` at
the archive root. The measured SHA-256 is pinned in both integrations:

`d93047723546fa76a8936095dda76b5b405ae8262c8cb7eb4d7b339ca9617845`

The XCFramework metadata declares these slices:

- iOS device: arm64.
- iOS simulator: arm64 and x86_64.

Swift call signatures were checked against the actual downloaded framework's
headers, including annotation delegates and coordinate bounds fitting. This
does not replace Swift compilation or prove compatibility with a particular
Xcode version.

SwiftPM uses a remote binary target with the pinned checksum. CocoaPods invokes
`ios/prepare_sdk.rb` during podspec evaluation to download/check/extract the
same archive, then links the vendored framework. Evaluating the podspec is
intentional: Flutter installs local plugin pods, where `prepare_command` is
skipped. The helper caches the SDK under ignored `ios/Frameworks`, checks the
archive checksum and serializes concurrent downloads with a file lock.

The plugin podspec, Swift package and example require iOS 13. The canonical
Swift source tree is `ios/map_kit/Sources/map_kit`; duplicate `ios/Classes`
sources and the old template plugin class were removed. Do not add a separate
MapLibre or legacy Neshan SDK alongside the plugin.

The example reads the key from ignored `example/ios/Flutter/Neshan.xcconfig`.
Copy its `.example` file and authorize `com.golrang.mapKitExample` in Neshan's
panel. See [README.md](README.md) for host setup.

## Checks completed on Windows

- Original shared Flutter suite: 13 tests passed before implementation.
- Three new iOS Flutter regression tests pass: SVG/display-scale conversion
  and missing-asset fallback; all initial creation payloads; shared commands,
  all callback kinds, cancellation and remount without duplicate events.
- Final full package suite: **16 passed**. Example widget suite: **2 passed**.
- Final Flutter analysis: no errors, 3 existing warnings and 15 informational
  diagnostics; the analyzer exits nonzero because of the existing warnings.
- `git diff --check` passed.
- These tests mock the native platform-view and channel boundary. They do not
  compile or render the Swift implementation.
- Native XCTest cases were added for the registered plugin, unattached/disposed
  errors, numeric and overlay validation, geodesic circles and segment distance.
  They have not run here.
- The SDK archive checksum, root layout, slices and referenced headers were
  inspected. The CocoaPods helper and SwiftPM dependency resolution still need
  to execute on macOS.

## Required macOS and iOS validation

1. Configure an iOS-authorized key in the example. Build with CocoaPods and
   with Flutter's SwiftPM integration in separate clean build configurations;
   confirm there is one Neshan MapLibre framework and no upstream duplicate.
2. Run `RunnerTests` using Xcode. Check both an Apple Silicon simulator and an
   iPhone; include Intel simulator coverage if it is a supported host.
3. Run `flutter test integration_test/neshan_device_test.dart -d DEVICE_ID`
   from `example`. It now selects the iOS native view on iOS. Its existing
   Android gesture/timing expectations may need adjustment based on measured
   iOS delivery; do not count this as a passed iOS test until run.
4. Verify authenticated tiles, Persian labels, marker rasterization/content,
   callouts, translucent circles/borders and polyline outlines visually.
5. Exercise each controller operation, empty/single/date-line bounds,
   invalid inputs, repeated marker taps, pan/pinch, rotation and background /
   foreground transitions. Check theme changes retain camera and overlays.
6. Test missing/wrong key, offline/slow style loading, recovery through a theme
   command, commands queued during initialization and disposal while loading.
7. Build an archive/release configuration and check SDK privacy manifests,
   signing, attribution and the consuming application's privacy declarations
   against actual deployed behavior.

No iPhone, iOS simulator, CocoaPods or Xcode is available in this Windows
workspace. Authenticated iOS rendering and release compatibility are not yet
verified.
