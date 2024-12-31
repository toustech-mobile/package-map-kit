import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/models/marker_model.dart';

abstract class NeshanMethods {
  static const MethodChannel _channel = MethodChannel('com.golrang.map_kit/method_channel');

  static addMarker(MarkerModel model) async {
    final String value = await _channel.invokeMethod(
      'addMarker', model.toNeshanMarker()
    );
  }
}

abstract class NeshanCallbackInterface {
  void onMapTap(LatLng point);

  void onMarkerTap(dynamic data);
}
