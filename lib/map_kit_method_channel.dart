import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'map_kit_platform_interface.dart';

/// An implementation of [MapKitPlatform] that uses method channels.
class MethodChannelMapKit extends MapKitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('map_kit');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
