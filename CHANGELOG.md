## Unreleased

* Center iOS marker numbers and content images inside the circular head of
  portrait pin artwork, preserving the SVG content position during rasterization.

* Queue native controller calls until the platform view is attached and execute
  them in order. Bound attachment waits and reject queued/in-flight calls when
  their map is disposed, fixing early `MAP_NOT_ATTACHED` errors on iOS.
* Authenticate Neshan HTTPS tile requests using the package key and actual iOS
  bundle. The SDK's `nsh://` resource loader bypasses `MLNSettings.apiKey` and
  reads the host Info.plist; a network delegate preserves package-owned setup.
  Log HTTP failure status/resource paths without exposing credentials.

* Give the iOS Neshan renderer a namespaced platform-view identifier and verify
  its compiled native identity before opening it. Mixed/old native builds now
  report `NESHAN_IOS_PLUGIN_MISMATCH` instead of silently opening the former
  Apple Maps view. Keep the original native identifier as a Neshan alias.
* Cover provider switching, incompatible native renderer identities, and the
  legacy `MapKitView` entry point in Flutter regression tests.

* Replace the iOS Apple Maps demo with Neshan's official MapLibre Native
  6.28.0 SDK. Forward initial settings and implement the shared overlay,
  user-position, camera, bounds, theme, and event protocol.
* **Breaking iOS setup:** minimum iOS is now 13. The private package supplies
  its iOS key through `NeshanConfiguration.swift` and `MLNSettings.apiKey`;
  no host Info.plist key is required. Remove legacy NeshanMobileSDK/Carto and license-file setup.
  SwiftPM and CocoaPods use the checksum-pinned official Neshan archive.
* Rasterize host SVG marker assets for iOS and retain native image/pin fallbacks.
  Remove unused duplicate Swift sources and add Flutter iOS channel regression
  tests plus native XCTest coverage for execution on macOS.

* Fix missing vector style configuration and stale style tests. Keep loading
  indicators from consuming map taps, and handle omitted overlays/default center
  safely when Flutter maps are created or rebuilt during theme changes.

* Apply a bundled Google Maps-inspired light/dark vector theme to Flutter maps
  only. Keep Map.ir on its own raster tiles and preserve Neshan's native styles.
  Optional `UiMap.vectorStyle` affects only Flutter; null selects legacy raster
  tiles. The vector renderer requires Flutter 3.27+ / Dart 3.6+.

* Migrate Android maps from the legacy Neshan/Carto SDK to
  `org.neshan.maplibre:android-sdk-opengl:13.4.1` from Maven Central.
* **Breaking Android setup:** minimum Android API is now 23. Configure
  `org.maplibre.android.API_KEY` in the host manifest; `neshan.license` is no
  longer used. See README.md for the example's environment/local-property setup.
* Preserve Flutter map/controller APIs while replacing native markers, filled
  circles, outlined polylines, user location, camera commands, and light/dark styles.
* Delegate Neshan bounds fitting to MapLibre; handle async style readiness and
  forward Android lifecycle events. Cancel Dart event subscriptions on disposal.
* Accept integer and floating-point channel numbers, synchronize clear-all
  registries, and avoid re-adding existing polylines on each insertion.
* Align the example with AGP 8.11.1, Gradle 8.14, Kotlin 2.2.20, and JVM 17.

* Validate on Samsung SM-A325F with Android integration, controller regression,
  native unit and example widget tests. Enable native TextureView rendering for
  Flutter viewport resizing during rotation.
* Bind Flutter theme changes and remove stale circle popup hit targets after
  clearing overlays. Align shared example marker assets and preserve overlays
  when changing themes.
* Add configurable raster application identity and visible map attribution after
  the example exposed blocked OpenStreetMap tiles with a generic User-Agent.
* Refresh example dependencies and disable Kotlin incremental caching for
  Windows workspaces whose Flutter dependencies are on a different drive.

## 0.0.1

* TODO: Describe initial release.
