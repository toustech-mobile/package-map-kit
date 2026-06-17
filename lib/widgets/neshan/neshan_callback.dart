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
          callbacks.onMarkerTap((streamData['data']['data'] as String),
              LatLng((streamData['data'] as Map)['latitude'], (streamData['data'] as Map)['longitude']));
          break;

        case 'onCircleTap':
          final mapData = streamData['data'] as Map;
          final lat = mapData['latitude'] as double?;
          final lng = mapData['longitude'] as double?;

          callbacks.onCircleTap(
            mapData['data'] as String,
            (lat != null && lng != null) ? LatLng(lat, lng) : null,
          );
          break;

        case 'onPolylineTap':
          final mapData = streamData['data'] as Map;
          final lat = mapData['latitude'] as double?;
          final lng = mapData['longitude'] as double?;

          callbacks.onPolylineTap(
            mapData['data'] as String,
            (lat != null && lng != null) ? LatLng(lat, lng) : null,
          );
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

  void onMarkerTap(dynamic data, LatLng point);

  void onCircleTap(dynamic data, LatLng? point);

  void onPolylineTap(dynamic data, LatLng? point);
}
