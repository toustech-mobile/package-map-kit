import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'map_kit_method_channel.dart';

abstract class MapKitPlatform extends PlatformInterface {
  /// Constructs a MapKitPlatform.
  MapKitPlatform() : super(token: _token);

  static final Object _token = Object();

  static MapKitPlatform _instance = MethodChannelMapKit();

  /// The default instance of [MapKitPlatform] to use.
  ///
  /// Defaults to [MethodChannelMapKit].
  static MapKitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MapKitPlatform] when
  /// they register themselves.
  static set instance(MapKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
