# iOS Neshan implementation and validation

Updated 2026-10-25. Implemented on Windows; iOS compilation and device
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
| Native identity | `getRendererInfo` handshake verifies Neshan/protocol/view before opening `com.golrang.map_kit/neshan_map_view`; incompatible builds fail clearly |
| Authentication | Package-owned key through `MLNSettings.apiKey` and a Neshan-only HTTPS network delegate supplying `key` plus the actual iOS `bundle` header |
| Creation | Initial center, zoom, theme, markers, circles and polylines forwarded through `UiKitView` |
| Controller | Marker/circle/polyline add, remove and clear; supplied user position and accuracy; camera read/move, bounds, theme |
| Events | Map tap/long press, marker/circle/polyline taps using the existing shared event channel |
| Markers | Host SVGs rasterized to PNG at display scale; native asset image/pin fallback; SVG or text content and marker callouts |
| Shapes | Closed 96-segment geodesic circles, separate borders, outlined polylines and projected hit testing |
| Theme | Neshan light/dark URLs; camera retained and annotations restored after loading |
| Readiness | Ordered Dart command queue waits up to 30 seconds for native attachment; native style/layout wait has a 45-second timeout; disposal rejects pending/in-flight calls |
| Lifecycle | Weak native-view registry; dispose queued replies and renderer on view/engine release; cancel Dart event subscriptions |

Existing compatibility limits remain: commands target the newest live native
map, overlay removal matches coordinates (or a line's first point), and native
overlay callback metadata is a string. Independent multi-map routing and
general declarative updates after creation are outside this change. Overlay
mutations currently rebuild the owned annotation collection; large overlay
sets should be profiled on device.

`setUserLocation` draws supplied data without acquiring GPS or requesting
permission. The example's explicit location-service action has a purpose string.

The user reported seeing Apple branding in another consuming application.
The supplied runtime logs also show `MissingPluginException` for `addMarkers`,
`removeAllMarkers`, and `setUserMarker` on the shared method channel. This
establishes that their Neshan command handlers are absent in the running engine;
the current registered plugin would handle them even before view creation,
returning `MAP_NOT_ATTACHED` until a view exists. The exact installed native
binary and host engine/widget code are not available here, so the underlying
registration/build cause remains unverified. Current package sources contain
no `MKMapView` implementation. A dedicated view ID and identity check
now distinguish old/mixed native code from this renderer; the original view ID
is kept only as a native alias to Neshan. A full consuming-app rebuild is
required for this change. See the README troubleshooting steps.

Controller methods perform the same identity check independently, including
calls arriving before widget initialization completes. A missing native command
handler is translated into `NESHAN_IOS_PLUGIN_MISMATCH` rather than a raw
`MissingPluginException`. Tests cover the three methods from the supplied logs.

## Packaging and SDK evidence

### Attachment and tile authentication correction — 2026-10-25

The user's updated device run opened Neshan but reported `MAP_NOT_ATTACHED`
from a controller call and showed no tiles. Two concrete issues were found:

1. The widget bound controller callbacks before asynchronous iOS preparation
   and native view creation completed. All widget-bound controller operations
   now wait for `onPlatformViewCreated`, run in invocation order, propagate
   initialization failures, and fail on timeout/disposal. Native style readiness
   remains a separate queue. Direct low-level `NeshanMethods` calls still
   require an attached view.
2. Inspection of the official arm64 binary's `mbgl::resourceURL` implementation
   showed that its `nsh://` loader reads `MLNApiKey` from `Bundle.main` and
   appends `key` to HTTPS tile URLs. The general SDK header supports
   `MLNSettings.apiKey`, but the Neshan-specific loader bypasses that property.
   The earlier assumption that this setter alone authenticated private tiles
   was incorrect. The package now also uses the SDK's request delegate to add
   the package key and actual iOS bundle header only to Neshan HTTPS requests.
   It retains and forwards existing delegate hooks and logs safe HTTP error
   metadata. This hook is part of the inspected SDK but is marked experimental
   in its header; recheck its selectors when upgrading the SDK.

The user's actual bundle identifier is `com.golrang.sfapp`. A direct request to
Neshan's protected basemap tile endpoint, with the package key as `key` and
that identifier in the `bundle` header, returned **HTTP 200** (68,504 bytes).
The same request using the known Android example bundle also returned 200.
No credential value or response body was logged. This verifies service access
for those supplied request parameters; it does not replace an authenticated
rendering test on the iPhone or validate device connectivity.

Native tests cover request authentication, preserving existing query/header
values, host/TLS restrictions and delegate selectors. They require Xcode and
have not executed here. Flutter regressions cover delayed platform creation,
command order, disposal, late replies, failed commands and attachment timeout.
The full Flutter package suite after these fixes passed **28 tests**.

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

This private package embeds the existing key in
`ios/map_kit/Sources/map_kit/NeshanConfiguration.swift`. It configures the SDK
setter plus `NeshanNetworkDelegate` before creating any native map, as described
above. Both package integrations
compile this source automatically. The example's old key file, includes and
Info.plist key entry were removed. No consuming-app key setup is required;
authorize each consuming bundle ID in Neshan's panel. Publishing is disabled
with `publish_to: none`. See [README.md](README.md).

## Checks completed on Windows

- Original shared Flutter suite: 13 tests passed before implementation.
- Three new iOS Flutter regression tests pass: SVG/display-scale conversion
  and missing-asset fallback; all initial creation payloads; shared commands,
  all callback kinds, cancellation and remount without duplicate events.
- Initial implementation full package suite: **16 passed**. Example widget suite: **2 passed**.
- Renderer-registration follow-up (2026-10-25): **22 package tests passed**,
  including provider switching, old/incompatible renderer identities, legacy
  wrapper creation, early controller calls, and missing command handlers.
- Follow-up full analysis found no errors, with 3 pre-existing warnings and
  14 informational diagnostics after removing the legacy initialization print.
- Final Flutter analysis: no errors, 3 existing warnings and 15 informational
  diagnostics; the analyzer exits nonzero because of the existing warnings.
- `git diff --check` passed.
- These tests mock the native platform-view and channel boundary. They do not
  compile or render the Swift implementation.
- Native XCTest cases were added for the registered plugin, unattached/disposed
  errors, numeric and overlay validation, geodesic circles and segment distance.
  They have not run here.
- A native test also checks that the package configuration sets the SDK key;
  its assertions avoid printing credentials. This still requires Xcode to run.
- The SDK archive checksum, root layout, slices and referenced headers were
  inspected. The CocoaPods helper and SwiftPM dependency resolution still need
  to execute on macOS.

## Required macOS and iOS validation

1. Authorize the example bundle ID for the package key. Build with CocoaPods and
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
