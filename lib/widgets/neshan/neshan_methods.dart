import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/models/move_model.dart';
import 'package:map_kit/models/poly_line_model.dart';
import 'package:map_kit/models/user_marker.dart';

abstract class NeshanMethods {
  static const MethodChannel _channel =
      MethodChannel('com.example.example/method_channel');

  static addMarkers(List<MarkerModel> markers) async {
    await _channel.invokeMethod('addMarkers',
        markers.map((flutterModel) => flutterModel.toNeshanMarker()).toList());
  }

  static removeMarkers(List<MarkerModel> markers) async {
    await _channel.invokeMethod('removeMarkers',
        markers.map((flutterModel) => flutterModel.toNeshanMarker()).toList());
  }

  static removeAllMarkers() async {
    await _channel.invokeMethod('removeAllMarkers', '');
  }

  static addCircles(List<CircleModel> circles) async {
    await _channel.invokeMethod('addCircles',
        circles.map((flutterModel) => flutterModel.toNeshanCircle()).toList());
  }

  static removeCircles(List<CircleModel> circles) async {
    await _channel.invokeMethod('removeCircles',
        circles.map((flutterModel) => flutterModel.toNeshanCircle()).toList());
  }

  static removeAllCircles() async {
    await _channel.invokeMethod('removeAllCircles', '');
  }

  static addPolylines(List<PolyLineModel> polyLines) async {
    await _channel.invokeMethod(
        'addPolyLines',
        polyLines
            .map((flutterModel) => flutterModel.toNeshanPolyLines())
            .toList());
  }

  static removePolyLines(List<PolyLineModel> polyLines) async {
    await _channel.invokeMethod(
        'removePolyLines',
        polyLines
            .map((flutterModel) => flutterModel.toNeshanPolyLines())
            .toList());
  }

  static removeAllPolyLines() async {
    await _channel.invokeMethod('removeAllPolyLines', '');
  }

  static setUserMarker(UserMarkerModel userMarker) async {
    await _channel.invokeMethod(
        'setUserMarker', userMarker.toNeshanUserMarker());
  }

  static moveCamera(MoveModel moveMarker) async {
    await _channel.invokeMethod('moveCamera', moveMarker.toNeshanMoveModel());
  }

  static setDarkMode(bool isDarkMode) async {
    await _channel.invokeMethod('setMapStyle', {'isDarkMode': isDarkMode});
  }
}

abstract class NeshanCallbackInterface {
  void onMapTap(LatLng point);

  void onMarkerTap(dynamic data);
}
