## Unreleased

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
