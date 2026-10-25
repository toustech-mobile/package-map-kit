import 'package:flutter/services.dart';

/// Checks the compiled iOS plugin before opening its platform view. Native
/// binaries are not replaced by hot reload/restart when a dependency changes.
abstract final class NeshanIosRenderer {
  static const viewType = 'com.golrang.map_kit/neshan_map_view';
  static const _channel = MethodChannel('map_kit');

  static PlatformException commandChannelUnavailable() => _mismatch();

  static Future<void> ensureAvailable() async {
    Object? info;
    try {
      info = await _channel.invokeMethod<Object?>('getRendererInfo');
    } on MissingPluginException {
      throw _mismatch();
    }
    if (info is! Map ||
        info['renderer'] != 'neshan-maplibre' ||
        info['protocolVersion'] != 1 ||
        info['viewType'] != viewType) {
      throw _mismatch();
    }
  }

  static PlatformException _mismatch() => PlatformException(
        code: 'NESHAN_IOS_PLUGIN_MISMATCH',
        message: 'The installed iOS plugin is not the current Neshan renderer. '
            'Update the consuming app\'s map_kit dependency, stop the app, '
            'then run flutter clean, flutter pub get and a full iOS build. '
            'Hot reload and hot restart cannot update native plugin code.',
      );
}
