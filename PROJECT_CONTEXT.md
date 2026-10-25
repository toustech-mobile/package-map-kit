# Map Kit — project analysis and reusable prompt context

## Android package configuration update — 2026-10-25

The private package now supplies the Android key from
`android/src/main/res/values/neshan_configuration.xml` via library manifest
metadata. Android merges this into each host; consuming apps need no key setup.
The example no longer supplies metadata or a Gradle placeholder. Keep the key's
Android application-ID restrictions current for every consuming app. Missing
merged keys fail the widget and queued commands before platform-view creation.

## iOS implementation update — 2026-10-24

The historical iOS findings below are superseded by the implementation in
`ios/map_kit/Sources/map_kit` and [IOS_SUPPORT_REVIEW.md](IOS_SUPPORT_REVIEW.md).
Neshan now distributes a MapLibre-based iOS SDK; the current official guide
supersedes the old Carto/NTMapView starters. The plugin pins version 6.28.0,
uses a package-owned key through `MLNSettings.apiKey`, and supports SwiftPM and
CocoaPods. The private key configuration is `NeshanConfiguration.swift`; no
example/host key entry is needed. Publishing is disabled with `publish_to: none`.
The SDK's `nsh://` tile loader reads `Bundle.main` directly, so setting
`MLNSettings.apiKey` alone is insufficient: `NeshanNetworkDelegate` adds the
package key and iOS bundle header to Neshan HTTPS requests. Controller calls
also wait for native attachment and run serially through `NeshanCommandQueue`.
The shared widget forwards creation settings and receives native events on
iOS; Swift handles controller commands, overlays, bounds and theme reloads.
The prototype button and duplicate `ios/Classes` tree were removed.
This was implemented on Windows. Flutter regression tests and source/header
checks are separate from the still-required Xcode/SDK/device validation.

Updated: 2026-10-14. Original analyzed commit: `e4edd83e2ffdeb74893dc7d2cfc10d53cfdce5bf`.
This reference includes the uncommitted Android migration and Samsung device validation.
See DEVICE_TEST_REPORT.md for the current test evidence and remaining limits.
Recheck relevant source when making changes.

Flutter theme update (2026-10-17): `MapProvider.flutter` now defaults to bundled
Google Maps-inspired vector styles (`assets/maps/google-light.json` and
`google-dark.json`) rendered inside the existing flutter_map camera/overlays.
`UiMap.vectorStyle` customizes Flutter only; null keeps its raster fallback.
Map.ir ignores this input and stays on its original tiles, including in dark
mode. Neshan's native styling is unchanged. The vector dependency requires
Dart 3.6 / Flutter 3.27. Older raster-only details below predate this update.

## 1. Copy-ready context for future prompts

```text
Project: package-map-kit; Dart package map_kit, version 0.0.1.
Read PROJECT_CONTEXT.md and relevant source before editing.

Public shared API: UiMap in lib/ui_map.dart and UiMapController in
lib/core/ui_map_controller.dart. lib/map_kit.dart is an Apple-map prototype,
not a barrel export of the shared map API.

Providers:
- flutter: flutter_map with OpenStreetMap tiles.
- mapIr: same Flutter renderer with map.ir tiles.
- neshan on Android: org.neshan.maplibre:android-sdk-opengl:13.4.1.
  This is the NEW MapLibre renderer; do not reintroduce org.neshan.mapsdk,
  com.carto, old mobile/services/common-sdk artifacts, or neshan.license.
  Requires Android API 23+ and JVM 17. The private package owns the Android key
  in android/src/main/res/values/neshan_configuration.xml. Its library manifest
  merges org.maplibre.android.API_KEY into consuming apps; no host key setup.
- neshan on iOS: still an Apple MKMapView demo, without shared map controls.
- web: declared but unfinished registration/platform gating.

Dart models live in lib/models and serialize through toNeshan* methods.
Android plugin registration/lifecycle is in MapKitPlugin.kt. MapKitView.kt owns
async style readiness, map commands, overlay registries, camera and callbacks.
Native helpers build MapLibre markers, circle polygons, and outlined polylines.

Existing protocol names are preserved:
method channel com.example.example/method_channel;
event channel com.yourapp/event_channel;
Android platform view com.example.example/map_kit_view.
Native commands target the latest view, not independent per-view channels.

Controller callbacks are bound by provider initState; no public readiness or
detach contract exists. Await Neshan controller operation results when errors
matter. Android waits for style readiness once its platform view exists.
Android fitBounds is now native, and Dart event subscriptions cancel on dispose.
Flutter marker/circle callbacks return model objects; Android returns strings.
Android polyline tap coordinates remain null for compatibility.

Flutter theme binding and removed-circle popup cleanup now have regression tests.
Remaining concerns include overlay identity based on instances/coordinates,
mutable widget inputs, parent rebuild semantics, partial platform support,
hard-coded map.ir credentials, incomplete iOS/web support and placeholder license.
Preserve Android drawable keep rules; markers resolve icons through reflection.
The iOS podspec compiles ios/map_kit/Sources/map_kit, not ios/Classes.

Task: [describe requested change]
Acceptance criteria: [observable behavior and target platforms]
Keep scope focused, test changed provider paths, and report actual validation
separately from unverified runtime behavior.
```

No real API key or legacy license contents are included in this context document.

## 2. Purpose and repository structure

This Flutter plugin offers markers with text/icon content and snippets, circles,
outlined polylines, generated circle outlines, user-position/accuracy overlays,
camera commands, theme selection, taps, and long presses. Support varies by
provider. Assets suggest field/tour/branch mapping use cases; that is an inference,
not a separately specified business requirement.

There is no application backend, database, authentication system, route-service
client, geocoding implementation, or GPS tracking service in the package. Hosts
supply user positions; map rendering performs SDK/tile network requests.

| Path | Responsibility |
| --- | --- |
| `pubspec.yaml` | Package identity, dependencies, SDK constraints, plugin registration |
| `lib/ui_map.dart` | Shared map widget and provider routing |
| `lib/core/ui_map_controller.dart` | Callback-based imperative controller |
| `lib/core/ui_map_camera.dart` | Camera snapshot containing center and zoom |
| `lib/enums/map_provider.dart` | flutter, mapIr, neshan |
| `lib/models/` | Overlay models, serialization, geometry and conversions |
| `lib/extensions/hex_color.dart` | Hex color conversion, native `#AARRGGBB` output |
| `lib/widgets/flutter/flutter_map_widget.dart` | Raster tiles, Flutter overlays, hit testing and popups |
| `lib/widgets/neshan/neshan_map_widget.dart` | Native widget selection, controller bindings, subscription disposal |
| `lib/widgets/neshan/neshan_methods.dart` | Native commands including new native fitBounds |
| `lib/widgets/neshan/neshan_callback.dart` | Event decoding and returned stream subscription |
| `lib/map_kit.dart` | Separate Apple platform view prototype |
| `lib/map_kit_platform_interface.dart`, `lib/map_kit_method_channel.dart` | Template platform-version abstraction |
| `lib/map_kit_web.dart` | Incomplete web plugin |
| `android/src/main/kotlin/com/golrang/map_kit/MapKitPlugin.kt` | Channels, view factory, activity/engine lifecycle |
| `android/src/main/kotlin/com/golrang/map_kit/MapKitView.kt` | MapLibre rendering, readiness, commands, events and disposal |
| `android/src/main/kotlin/com/golrang/map_kit/helpers/` | Marker bitmaps, native overlays, payload validation and geometry |
| `android/src/main/kotlin/com/golrang/map_kit/models/` | Native overlay wrappers; old point model remains unused |
| `android/src/main/res/` | Layout, drawables, resource shrinker keep list |
| `android/proguard-rules.pro` | Consumer keep rules for reflectively resolved plugin resources |
| `ios/map_kit/Sources/map_kit/` | Swift tree selected by the podspec and Swift package |
| `ios/Classes/` | Duplicate Swift sources, not compiled by the current podspec |
| `example/lib/main.dart` | Interactive demonstration |
| `test/neshan_methods_test.dart` | Dart migration channel regression tests |
| `android/src/test/kotlin/com/golrang/map_kit/` | Plugin dispatch and geometry/payload tests |
| `README.md`, `CHANGELOG.md` | Current usage/migration setup and release notes |

No AGENTS.md or tracked GitHub Actions workflow was found in the original
inventory. Root .dart_tool/build, IDE files, and generated plugin metadata are
local tooling artifacts rather than source architecture.

## 3. Android migration and setup

The old `neshan-android-sdk:mobile-sdk:1.0.3`, services/common artifacts, Carto
classes, custom Maven repository, and direct old Play Services dependencies were
removed from the map integration. The example no longer packages its old
`res/raw/neshan.license`.

New SDK: `org.neshan.maplibre:android-sdk-opengl:13.4.1`, from Maven Central.
The published AAR was inspected: its minimum Android SDK is 23 and minimum compile
SDK is 34. Its POM declares Kotlin stdlib 2.2.10. The example uses Kotlin 2.2.20,
which also satisfies the installed Flutter 3.47.6 toolchain's enforced minimum.

The private package's library manifest supplies `org.maplibre.android.API_KEY`
inside `<application>`, referencing `map_kit_neshan_api_key` in
`android/src/main/res/values/neshan_configuration.xml`. Consuming apps inherit it
through Android manifest merging and need no key configuration. Remove previous
host metadata/placeholders when upgrading. An empty merged key fails validation
before the native view is created. Do not reuse the old raw-license setup or copy
keys into prompts.

Build configuration:

- Library: compile SDK 36, minimum SDK 23, Java/JVM 17; Android library and Kotlin
  Android plugins applied.
- Example: AGP 8.11.1, Kotlin 2.2.20, Gradle wrapper 8.14; compile SDK 36, minimum
  SDK 23, JVM 17 in both Groovy and Kotlin DSL app files.
- Groovy example pins NDK 29.0.13113456; Kotlin DSL retains Flutter's NDK default.
  Both variants still exist. The validation build reported the Groovy files.
- Library release shrinking is disabled; example release minification/resource
  shrinking are enabled in both variants. Example uses debug signing.
- Plugin manifest now contains Internet permission only; the unused exported
  MyActivity declaration and application template entries were removed.
- MapLibre's AAR supplies its JNI consumer rules. Keep plugin drawable reflection
  rules and `res/raw/keep.xml`; new reflected icons need entries in that list.
- Native appcompat/material/core/constraintlayout dependencies remain; migrating
  the map SDK did not remove every historical UI dependency.

Official references:
[Neshan overview](https://platform.neshan.org/docs/sdk/android/neshan-android-sdk-getting-started/),
[installation](https://platform.neshan.org/docs/sdk/android/installation/),
[styles](https://platform.neshan.org/docs/sdk/android/features/android-sdk-change-map-style/),
[markers](https://platform.neshan.org/docs/sdk/android/features/android-sdk-add-marker/),
[polylines](https://platform.neshan.org/docs/sdk/android/features/android-sdk-draw-line/).
API signatures were additionally checked against the actual published SDK classes,
rather than relying only on the latest upstream MapLibre documentation.

## 4. Architecture and ownership

```text
Host -> UiMap -> FlutterMapWidget (flutter / mapIr)
                -> flutter_map + tiles + overlay/popup layers

             -> NeshanMapWidget (neshan)
                -> AndroidView -> MapKitPlugin -> MapKitView -> MapLibre SDK
                -> iOS MapKitView -> UiKitView -> Apple MKMapView demo

UiMapController -> bound provider callbacks -> Dart renderer / native commands
Android interaction -> event sink -> Dart event decoder -> shared callback
```

UiMap returns a Scaffold, normalizes overlay lists to empty mutable lists, and
routes providers. Provider widgets and model objects still contain mutable fields;
the host can pass lists that providers mutate. Controller callbacks are assigned
in initState, without a general readiness, detach, notification, or command-stream
abstraction. Neither provider defines complete didUpdateWidget behavior.

Neshan controller closures now return/await native futures and update local lists
after native success, without scheduling setState for every native command.
The subscription is retained and canceled on disposal. Missing Neshan center
defaults to Tehran. The controller still needs an attached platform view before
commands can be accepted. Early calls before native view creation return
MAP_NOT_ATTACHED; accepted calls wait while the map/style initializes.

MapKitPlugin tracks view instances per plugin object, unregisters channel handlers
and application callbacks on engine detach, and forwards activity start/resume/
pause/stop/save-state/destroy plus memory events. View lifecycle methods guard
duplicate transitions. MapKitView destroys the renderer and fails outstanding
operations when disposed.

The legacy method channel remains global: commands target the most recently
created live native view and all views use one event stream. Multiple maps do not
have independent command/event routing.

## 5. API and models

UiMap inputs: required mapProvider; optional controller, initialCenter, isDarkMode,
zoom, markers, circles, polyLines, onTap, onLongPress, onMarkerTap, onCircleTap,
onPolylineTap. There is no isCurrentLocationEnable input.

| Controller member | Contract |
| --- | --- |
| addMarkers / removeMarkers / removeAllMarkers | Marker list operations |
| addCircles / removeCircles / removeAllCircles | Circle list operations |
| addPolyline / removePolyLines / removeAllPolyLines | Polyline list operations |
| moveCamera(MoveModel) | Move to a coordinate with optional zoom |
| fitBounds(MapBoundsModel) | Fit coordinate points and padding; Neshan now delegates to native MapLibre |
| setUserLocation(UserMarkerModel) | Nullable function; supplies an overlay, not GPS acquisition |
| setDarkMode(bool) | Bound by Neshan and FlutterMapWidget; native calls complete after style load |
| camera | Future of UiMapCamera, containing center and zoom only |

| Model | Relevant behavior |
| --- | --- |
| MarkerModel | Required latitude, longitude, icon; optional data, iconSize, snippets, markerContent, unused snippetWidget. No stable ID/custom equality. |
| CircleModel | Center, radius in meters, fill/border colors, optional borderStroke/data/snippets. Native default borderStroke is now double 2.0. |
| PolyLineModel | Color, nullable points/strokeWidth/strokeColor/data; points or encoded constructor. Flutter force-unwraps points/width. Native defaults missing width to 3 and requires two points. |
| PolyLinePointModel | Mutable latitude, longitude, heading; encoded polyline decoder at 1e5 precision, without malformed-input validation. |
| CirclePolylineModel | Generated closed spherical circle outline, automatic 36–360 segments; explicit count is unchecked. Point-inside helper uses geodesic distance. |
| MoveModel | Latitude, longitude, optional zoom. |
| MapBoundsModel | Points and padding, default 24 logical pixels. |
| UserMarkerModel | Position, accuracy, optional borderStroke; native payload omits borderStroke. |
| UiMapCamera | Immutable zoom and center; no bearing/tilt snapshot. |

PolyLineModel.copyWith loses strokeColor. The Flutter renderer compensates in its
outline-building call, but generic callers should not assume full-field copying.

Callback differences remain deliberate compatibility constraints:

| Callback | Flutter / map.ir | Android Neshan |
| --- | --- | --- |
| Map tap/long press | LatLng | LatLng |
| Marker tap | MarkerModel, point | Stringified metadata, marker position |
| Circle tap | CircleModel, hit/center point | Stringified data, circle center |
| Polyline tap | Original data, hit point | Stringified data, null point |

Data must be compatible with StandardMessageCodec when sent natively; arbitrary
Dart instances are not automatically serializable. No JSON round trip exists.

## 6. Native renderer behavior

MapLibre initializes before inflating the MapView. The map is obtained
asynchronously, then a Neshan style is loaded:
`https://static.neshan.org/sdk/maplibre/styles/light.json` or `dark.json`.

- Initial center defaults to Tehran; zoom defaults to 13. Restored native camera
  state takes precedence when a saved view bundle is available.
- Commands received before style readiness queue and execute in order. A style
  operation completes after style load and overlay restoration. Pending commands
  fail on disposal or initial style/overlay initialization failure.
- A style failure allows retry with setMapStyle after key/network correction.
  Native errors include MAP_NOT_ATTACHED, MAP_NOT_READY, MAP_DISPOSED,
  STYLE_LOAD_FAILED, MAP_INITIALIZATION_FAILED, INVALID_ARGUMENT,
  MAP_OPERATION_FAILED and BOUNDS_FAILED.
- Markers use MapLibre's built-in annotation API and custom bitmaps. Icons resolve
  plugin drawables by reflection, stripping .svg, with end_point fallback.
  Marker content tries another drawable first, otherwise draws text with
  fonts/iransans.ttf. iconSize is in logical pixels.
- Circles are approximated by closed 96-segment geodesic polygons, plus separate
  border polylines. Fill/border alpha is preserved separately from RGB.
- Each logical polyline owns main and outline annotations. Outline width is +4.
  Adding lines no longer re-adds the entire old collection.
- User position uses a current_location marker and geodesic accuracy polygon.
  No native location permission request or GPS subscription is performed.
- Style replacements recreate owned annotations from their stored specs.
- Clear-all methods clear native registries; ordinary marker clearing retains
  the separately managed user position.
- Marker/circle removal matches center coordinates; polyline removal matches
  first-point coordinates. No overlay IDs were introduced.
- Click handling checks circles by meter distance and polylines by projected
  segment distance (30 logical pixel tolerance). General onTap follows when no
  shape matches. Marker callbacks use the built-in marker-click listener.
- Native numeric decoding accepts Number and checks finiteness/ranges.
  Negative radius/width and invalid points produce argument errors.
- Bounds fitting waits for layout, converts logical padding to pixels, and uses
  MapLibre CameraUpdateFactory. Empty bounds do nothing; coincident/single points
  preserve the current zoom. Fit requests must have nonnegative padding.
- The SDK's standard annotations are deprecated upstream but are explicitly
  documented by Neshan for basic markers/lines. A future style-layer/annotation-
  plugin migration can be considered separately.

Authenticated styles, overlays, callbacks and lifecycle were exercised on the
Samsung device; see section 11 and DEVICE_TEST_REPORT.md for the tested scope.
The native map enables MapLibre TextureView rendering for Flutter viewport resizing.

## 7. Flutter renderer and other platforms

Flutter/map.ir behavior and device fixes:

- Center fallback Tehran, initial zoom 13, min/max 2/18.
- Raster tiles send UiMap.userAgentPackageName (default com.golrang.map_kit;
  the example supplies com.golrang.map_kit_example). Attribution is visible.
  OpenStreetMap blocked tiles were observed with the original generic client.
  The final identified release still displays blocked tiles on this connection;
  service access remains unresolved. map.ir day tiles rendered successfully.
- Day tiles use OpenStreetMap or map.ir Shiveh; the map.ir credential is still
  hard-coded. Dark tiles use CARTO regardless of raster provider.
- Layers: tiles, circles, outer/inner polylines, popup marker layer, user overlay.
- Flutter line outlines use width +5 and strokeColor or alpha-100 main color.
- Circle snippets rely on invisible center markers. Circle changes now rebuild
  that set and removals close popups; clearing circles no longer leaves stale hit targets.
- Popup selection/removal relies on coordinates or object identity. Colocated
  overlays are ambiguous.
- SVGs resolve from the host assets/icons directory without a package namespace.
  markerContent of <=2 characters is text; longer content is an SVG filename.
  Long content with missing iconSize can throw.
- Map tap priority is circle, polyline, general map. A longitude-zero sentinel
  incorrectly excludes circles centered on longitude zero.
- Overlay validation checks selected NaNs, but does not comprehensively validate
  infinity, bounds, radius, width or padding.
- Many controller mutations use post-frame callbacks; scheduling can delay updates.
- No explicit attribution widget appears in the Flutter map children.

iOS Neshan remains an Apple MKMapView prototype centered on San Francisco with a
Tap Me button. Shared creation settings, overlays, camera/theme commands and
native Android events are not implemented there. SwiftMapKitPlugin registers
map_kit_view and handles createMapView; a separate template MapKitPlugin class
handles getPlatformVersion. The podspec selects ios/map_kit/Sources/map_kit.
The three duplicate ios/Classes Swift files matched at initial inspection.

Podspec: Swift 5.0, iOS 12.0. Swift package: tools 5.9, iOS 13.0, absent sibling
../FlutterFramework dependency. Root ios/Podfile still declares old NeshanMobileSDK
~>0.9.5, separate from the active Apple-map code. Privacy manifests are placeholders
and do not independently validate SDK networking/data behavior.

Web is declared, but MapKitWeb.registerWith is commented out. UiMap also imports
the native widget, which uses dart:io/Platform.isIOS without conditional platform
gating. Web support needs implementation and verification. There is no declared
Windows/Linux/macOS plugin.

## 8. Channel protocol

| Role | Name |
| --- | --- |
| Android method channel | com.example.example/method_channel |
| Android event channel | com.yourapp/event_channel |
| Android platform view | com.example.example/map_kit_view |
| iOS prototype command channel | map_kit |
| iOS prototype view/button callback | map_kit_view |

Android methods, case-sensitive:
addMarkers, removeMarkers, removeAllMarkers, addCircles, removeCircles,
removeAllCircles, addPolyLines, removePolyLines, removeAllPolyLines, setUserMarker,
moveCamera, **fitBounds**, setMapStyle, getCamera. The dispatcher also handles
getPlatformVersion.

Payloads:

- Markers: latitude, longitude, data, icon, iconSize, snippetTitle,
  snippetDescription, markerContent.
- Circles: latitude, longitude, radius, borderStroke, color, borderColor, data,
  snippetTitle, snippetDescription (native circle snippets remain unrendered).
- Polylines: points containing latitude/longitude/heading, color, strokeWidth,
  strokeColor, stringified data. Heading is not rendered.
- User: latitude, longitude, accuracy.
- Move: latitude, longitude, nullable zoom. Theme: isDarkMode.
- Bounds: points containing latitude/longitude, and padding.
- Camera result: zoom, latitude, longitude. Dart accepts any numeric codec value.
- Events: {event: name, data: payload}. Names: onMapTap, onMapLongPress,
  onMarkerTap, onCircleTap, onPolylineTap. Payload contains latitude/longitude,
  and string data for overlay events.

Do not rename protocol strings without a deliberate native/Dart compatibility plan.

## 9. Example and remaining priorities

The demo defaults to Neshan near Mashhad (36.3156692, 59.5405541), zoom 15, and
provides provider switching, add/clear controls, camera actions, mock user
location, tap-dropped markers, and long-press circle outlines. The GPS action only
enables/checks the location service, without reading a real location.

The example uses ic_map_tour_icon.svg for initial and added markers. An Android
drawable alias maps that shared name to ic_map_tour_waiting_icon, and the alias
is protected by the resource keep list. The existing SVG has the same shape.

Provider switches remount UiMap with a key. Parent rebuilds pass a fresh initial
marker list and empty shape defaults; controller-added state is not a persistent
cross-provider store. Theme changes now use the controller without rebuilding the
whole demo, preserving its current overlays; the example awaits theme completion.

Remaining high-value work:

1. Define controller readiness/detach/reattachment and widget/list ownership.
2. Address remaining null assertions and coordinate-zero hit handling. Theme
   binding and removed-circle popup cleanup were fixed during device validation.
3. Introduce a deliberate overlay identity and callback normalization contract.
4. Complete or gate iOS/web support; reconcile duplicate build/source trees.
5. Configure map.ir credentials and tile attribution explicitly.
6. Verify actual SDK minimums and finish release metadata. The example widget
   test now verifies its real provider/control-panel UI. LICENSE still contains a placeholder with no usable license grant.

## 10. Dependencies outside the native migration

Root manifest: Dart >=3.4.4 <4.0.0, Flutter >=3.3.0. Runtime dependencies:
flutter_map ^8.3.1, flutter_map_marker_popup ^8.1.0, plugin_platform_interface
^2.0.2, unconstrained latlong2/flutter_svg. Dev dependencies: flutter_test,
flutter_lints ^3.0.0, build_runner ^2.4.8. No code generation workflow was found.

Example additionally declares location ^8.0.1, Cupertino icons and integration_test.
The original example lock resolves flutter_map 8.3.0, below the current manifest
constraint. Its SDK floor is Dart >=3.10.3 and Flutter >=3.38.4; old manifest
minimums are not verified compatibility. Device validation ran normal pub get and refreshed the example lockfile to
flutter_map 8.3.2 and SDK-compatible test dependency versions. Manifest constraints
are unchanged. Root pubspec.lock is ignored.

## 11. Validation and test status

Validated on Samsung SM-A325F, Android 13, ADB serial RZ8TA0AXTPA, on 2026-10-14.
The final native suite passed three scenarios together: overlays/callbacks/camera/
themes; repeated disposal/recreation; pan/pinch and invalid-input recovery.

- Root Flutter tests: 6 passed (native method payloads and Flutter renderer behavior).
- Android Gradle unit task: 5 passed (geometry, numeric payloads, dispatcher behavior).
- Example widget test: 1 passed (actual provider and control-panel UI).
- Android on-device integration tests: 3 passed.
- Debug and minified arm64 release APKs built successfully.
- Neshan styles, sprites and authenticated basemap rendering were observed on device.
  Initial HTTP 484 was diagnosed as a bundle-scope mismatch. After the user allowed
  com.golrang.map_kit_example, a matching-bundle tile probe returned HTTP 200.
- Complete-project analysis found no errors; existing mutable-widget/deprecation
  diagnostics remain. Do not interpret this as a clean-lint claim.

Device gesture tests use monotonic input timestamps: WidgetTester's default zero
input time can appear as an expired long press to Android. Pinch initiation must
also exceed MapLibre's 0.6 dp/ms scale-speed threshold. Slow injected pinches are
ignored by the SDK. View-composition experiments were reverted after diagnosing
that threshold; AndroidView/PanGestureRecognizer is retained. Native rendering
uses MapLibre TextureView to address a SurfaceView viewport issue found when
returning from landscape to portrait; release rotation checks cover this change.

The earlier pub.dev authorization and Gradle dependency problems were resolved
for this run. Normal project dependency/configuration files were used, not the
previous temporary validation harness. A missing official Google bundletool
artifact was downloaded and its Gradle cache lookup refreshed. Windows builds
also disable Kotlin incremental compilation in the example because dependencies
on C: and this workspace on D: cannot be relativized by that cache.

See DEVICE_TEST_REPORT.md for release UI checks, lifecycle results, evidence paths,
and remaining scope limits. iOS/web and broad performance/device compatibility
are outside this Samsung Android validation.

Reproduce:

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

## 12. Guidance for future edits

Change Dart serialization and native decoding together. Preserve asynchronous
readiness and result completion when touching styles/commands. Do not claim
multiple-map isolation with the current global protocol. Keep bitmap drawable
names and resource keep lists aligned. GPS acquisition belongs to the host unless
a task explicitly changes that responsibility.

For iOS, edit the packaged Swift tree intentionally. For Flutter overlays, check
both controller-driven mutations and parent rebuilds. Keep credentials out of
generated prompts and logs. Distinguish source analysis, compile checks, mock/
geometry tests and actual authenticated device behavior in every completion report.
