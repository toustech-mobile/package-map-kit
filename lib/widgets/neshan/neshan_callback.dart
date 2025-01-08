import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

abstract class NeshanCallback {
  static const EventChannel _eventChannel = EventChannel('com.yourapp/event_channel');

  static Future<void> setNeshanCallback(NeshanCallbackInterface callbacks) async {
    _eventChannel.receiveBroadcastStream().listen((streamData) {
      switch (streamData["event"]) {
        case 'onMapTap':
          callbacks.onMapTap(LatLng((streamData['data'] as Map)['latitude'], (streamData['data'] as Map)['longitude']));
          break;

        case 'onMapLongPress':
          callbacks.onMapLongPress(
              LatLng((streamData['data'] as Map)['latitude'], (streamData['data'] as Map)['longitude']));
          break;

        case 'onMarkerTap':
          callbacks.onMarkerTap((streamData['data']['data'] as String));
          break;

        case 'onCircleTap':
          callbacks.onCircleTap((streamData['data']['data'] as String));
          break;
      }
    }, onError: (error) {
      print('Error: $error');
    });
    //
  }
}

abstract class NeshanCallbackInterface {
  void onMapTap(LatLng point);

  void onMapLongPress(LatLng point);

  void onMarkerTap(dynamic data);

  void onCircleTap(dynamic data);
}
