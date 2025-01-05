import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/models/marker_model.dart';

abstract class NeshanMethods {
  static const MethodChannel _channel = MethodChannel('com.golrang.map_kit/method_channel');

  static addMarkers(List<MarkerModel> markers) async {
    await _channel.invokeMethod('addMarkers', markers.map((flutterModel) => flutterModel.toNeshanMarker()).toList());
  }

  static removeMarkers(List<MarkerModel> markers) async {
    await _channel.invokeMethod('removeMarkers', markers.map((flutterModel) => flutterModel.toNeshanMarker()).toList());
  }

  static addCircles(List<CircleModel> circles) async {
    await _channel.invokeMethod('addCircles', circles.map((flutterModel) => flutterModel.toNeshanCircle()).toList());
  }

  static removeCircles(List<CircleModel> circles) async {
    await _channel.invokeMethod('removeCircles', circles.map((flutterModel) => flutterModel.toNeshanCircle()).toList());
  }
}

abstract class NeshanCallbackInterface {
  void onMapTap(LatLng point);

  void onMarkerTap(dynamic data);
}
