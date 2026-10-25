import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_camera.dart';
import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/models/map_bounds_model.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/models/move_model.dart';
import 'package:map_kit/models/poly_line_model.dart';
import 'package:map_kit/models/user_marker.dart';
import 'package:map_kit/widgets/neshan/neshan_marker_codec.dart';
import 'package:map_kit/widgets/neshan/neshan_ios_renderer.dart';

abstract class NeshanMethods {
  static const MethodChannel _channel =
      MethodChannel('com.example.example/method_channel');

  /// Check merged package metadata before AndroidView creation, where an exception would
  /// otherwise escape Flutter's asynchronous platform-view initialization.
  static Future<void> validateAndroidConfiguration() async {
    try {
      await _channel.invokeMethod<void>('validateConfiguration');
    } on MissingPluginException {
      throw PlatformException(
        code: 'NESHAN_ANDROID_PLUGIN_MISMATCH',
        message: 'The installed Android plugin cannot validate Neshan setup. '
            'Stop the app and perform a full Android rebuild with the current '
            'map_kit dependency. Hot reload and hot restart do not update '
            'native plugin code.',
      );
    }
  }

  static Future<T?> _invoke<T>(String method, [dynamic arguments]) async {
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    // Controller calls can arrive before the widget's renderer check finishes.
    // Check the compiled plugin independently instead of relying on view creation.
    if (isIOS) await NeshanIosRenderer.ensureAvailable();
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      if (isIOS) throw NeshanIosRenderer.commandChannelUnavailable();
      rethrow;
    }
  }

  static addMarkers(List<MarkerModel> markers) async {
    await _invoke('addMarkers', await NeshanMarkerCodec.encode(markers));
  }

  static removeMarkers(List<MarkerModel> markers) async {
    await _invoke('removeMarkers',
        markers.map((flutterModel) => flutterModel.toNeshanMarker()).toList());
  }

  static removeAllMarkers() async {
    await _invoke('removeAllMarkers', '');
  }

  static addCircles(List<CircleModel> circles) async {
    await _invoke('addCircles',
        circles.map((flutterModel) => flutterModel.toNeshanCircle()).toList());
  }

  static removeCircles(List<CircleModel> circles) async {
    await _invoke('removeCircles',
        circles.map((flutterModel) => flutterModel.toNeshanCircle()).toList());
  }

  static removeAllCircles() async {
    await _invoke('removeAllCircles', '');
  }

  static addPolylines(List<PolyLineModel> polyLines) async {
    await _invoke(
        'addPolyLines',
        polyLines
            .map((flutterModel) => flutterModel.toNeshanPolyLines())
            .toList());
  }

  static removePolyLines(List<PolyLineModel> polyLines) async {
    await _invoke(
        'removePolyLines',
        polyLines
            .map((flutterModel) => flutterModel.toNeshanPolyLines())
            .toList());
  }

  static removeAllPolyLines() async {
    await _invoke('removeAllPolyLines', '');
  }

  static setUserMarker(UserMarkerModel userMarker) async {
    await _invoke('setUserMarker', userMarker.toNeshanUserMarker());
  }

  static moveCamera(MoveModel moveMarker) async {
    await _invoke('moveCamera', moveMarker.toNeshanMoveModel());
  }

  static Future<void> fitBounds(MapBoundsModel bounds) async {
    await _invoke('fitBounds', {
      'points': bounds.points
          .map((point) => {
                'latitude': point.latitude,
                'longitude': point.longitude,
              })
          .toList(),
      'padding': bounds.padding,
    });
  }

  static setDarkMode(bool isDarkMode) async {
    await _invoke('setMapStyle', {'isDarkMode': isDarkMode});
  }

  static Future<UiMapCamera> getCamera() async {
    final Map<dynamic, dynamic> result = await _invoke('getCamera');
    return UiMapCamera(
      (result['zoom'] as num).toDouble(),
      LatLng((result['latitude'] as num).toDouble(),
          (result['longitude'] as num).toDouble()),
    );
  }
}
