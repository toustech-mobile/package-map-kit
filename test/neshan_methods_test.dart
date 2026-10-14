import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/models/map_bounds_model.dart';
import 'package:map_kit/widgets/neshan/neshan_methods.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.example.example/method_channel');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'getCamera') {
        return {'zoom': 15, 'latitude': 36, 'longitude': 59};
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('bounds are delegated to native MapLibre with points and padding',
      () async {
    await NeshanMethods.fitBounds(MapBoundsModel(
      points: [const LatLng(36.3, 59.5), const LatLng(36.4, 59.6)],
      padding: 50,
    ));
    expect(calls.single.method, 'fitBounds');
    expect(calls.single.arguments, {
      'points': [
        {'latitude': 36.3, 'longitude': 59.5},
        {'latitude': 36.4, 'longitude': 59.6},
      ],
      'padding': 50.0,
    });
  });

  test('camera decoding accepts integer codec values', () async {
    final camera = await NeshanMethods.getCamera();
    expect(camera.zoom, 15.0);
    expect(camera.center, const LatLng(36, 59));
  });

  test('circles serialize default width and translucent native color',
      () async {
    await NeshanMethods.addCircles([
      CircleModel(
          latitude: 36,
          longitude: 59,
          radius: 700,
          color: const Color(0x800000FF),
          borderColor: Colors.blue),
    ]);
    final circle = (calls.single.arguments as List).single as Map;
    expect(circle['borderStroke'], isA<double>());
    expect(circle['borderStroke'], 2.0);
    expect(circle['color'], '#800000FF');
  });

  test('style command keeps the existing channel contract', () async {
    await NeshanMethods.setDarkMode(true);
    expect(calls.single.method, 'setMapStyle');
    expect(calls.single.arguments, {'isDarkMode': true});
  });
}
