// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'map_kit_platform_interface.dart';

/// A web implementation of the MapKitPlatform of the MapKit plugin.
class MapKitWeb extends MapKitPlatform {
  /// Constructs a MapKitWeb
  MapKitWeb();

  // static void registerWith(Registrar registrar) {
  //   MapKitPlatform.instance = MapKitWeb();
  // }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    // final version = web.window.navigator.userAgent;
    // return version;
    return null;
  }
}
