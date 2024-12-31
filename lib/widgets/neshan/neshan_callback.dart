import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

abstract class NeshanCallback {
  static const MethodChannel _channel = MethodChannel('com.golrang.map_kit/callback_channel');

  static Future<void> setNeshanCallback(NeshanCallbackInterface callbacks) async {

    // final String value = await _channel.invokeMethod('getNativeValue');
    // print(value);   // این مقادیر برای کال کردن متد از فلاتر به اندروید و گرفتن مقدار از اندروید می باشد

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onMapTap':
          callbacks.onMapTap(LatLng((call.arguments as Map)['latitude'], (call.arguments as Map)['longitude']));
          break;

        case 'onMarkerTap':
          callbacks.onMarkerTap(call.arguments as String);
          break;
      }
    });
  }
}

abstract class NeshanCallbackInterface {
  void onMapTap(LatLng point);

  void onMarkerTap(dynamic data);
}
