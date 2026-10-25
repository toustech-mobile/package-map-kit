import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/enums/map_provider.dart';
import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/models/map_bounds_model.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/models/move_model.dart';
import 'package:map_kit/models/poly_line_model.dart';
import 'package:map_kit/models/poly_line_point_model.dart';
import 'package:map_kit/models/user_marker.dart';
import 'package:map_kit/ui_map.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const center = LatLng(36.3156692, 59.5405541);

  Future<void> nativeTap(WidgetTester tester, Offset point) async {
    // Android's GestureDetector compares input timestamps to system uptime.
    // WidgetTester.tapAt uses zero timestamps, which can be classified as an
    // already-expired long press by a real Android platform view.
    await tester.pump();
    final gesture = await tester.createGesture();
    await gesture.down(point,
        timeStamp: tester.binding.currentSystemFrameTimeStamp);
    await tester.pump(const Duration(milliseconds: 40));
    await gesture.up(timeStamp: tester.binding.currentSystemFrameTimeStamp);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  }

  testWidgets(
      'Neshan real-device overlays, callbacks, camera and style reloads',
      (tester) async {
    final controller = UiMapController();
    final events = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: UiMap(
        mapProvider: MapProvider.neshan,
        controller: controller,
        initialCenter: center,
        zoom: 16,
        onTap: (_) => events.add('tap'),
        onLongPress: (_) => events.add('longPress'),
        onMarkerTap: (data, _) => events.add('marker:$data'),
        onCircleTap: (data, _) => events.add('circle:$data'),
        onPolylineTap: (data, _) => events.add('line:$data'),
      ),
    ));
    await tester.pumpAndSettle();
    final initial =
        await controller.camera.timeout(const Duration(seconds: 60));
    expect(initial.center.latitude, closeTo(center.latitude, 0.0001));
    expect(initial.zoom, closeTo(16, 0.1));
    debugPrint('DEVICE_CHECK: native map and initial style ready');

    Future<void> tapMap({Offset offset = Offset.zero}) async {
      final point = tester.getCenter(find.byType(UiMap)) + offset;
      await nativeTap(tester, point);
    }

    await tapMap();
    expect(events, contains('tap'));
    events.clear();
    await tester.longPressAt(tester.getCenter(find.byType(UiMap)));
    await tester.pump(const Duration(milliseconds: 700));
    expect(events, contains('longPress'));
    debugPrint('DEVICE_CHECK: map tap and long press received');

    final marker = MarkerModel(
      latitude: center.latitude,
      longitude: center.longitude,
      icon: 'end_point.svg',
      iconSize: 40,
      data: 'device-marker',
      snippetTitle: 'Device marker',
    );
    await controller.addMarkers([marker]);
    await tester.pump(const Duration(milliseconds: 500));
    events.clear();
    await tapMap(offset: const Offset(0, -10));
    expect(events, contains('marker:device-marker'));
    debugPrint('DEVICE_CHECK: marker callback received');
    await controller.removeMarkers([marker]);
    events.clear();
    await tapMap();
    expect(events, contains('tap'));

    final circle = CircleModel(
        latitude: center.latitude,
        longitude: center.longitude,
        radius: 150,
        color: Colors.blue.withAlpha(90),
        borderColor: Colors.blue,
        data: 'device-circle');
    await controller.addCircles([circle]);
    events.clear();
    await tapMap();
    expect(events, contains('circle:device-circle'));
    debugPrint('DEVICE_CHECK: circle callback received');
    await controller.removeCircles([circle]);
    events.clear();
    await tapMap();
    expect(events, contains('tap'));

    final line = PolyLineModel(
        points: [
          PolyLinePointModel(center.latitude - 0.002, center.longitude, 0),
          PolyLinePointModel(center.latitude + 0.002, center.longitude, 0),
        ],
        color: Colors.blue,
        strokeWidth: 5,
        strokeColor: Colors.red,
        data: 'device-line');
    await controller.addPolyline([line]);
    events.clear();
    await tapMap();
    expect(events, contains('line:device-line'));
    debugPrint('DEVICE_CHECK: polyline callback received');
    await controller.removePolyLines([line]);
    events.clear();
    await tapMap();
    expect(events, contains('tap'));

    await controller.addMarkers([marker]);
    await controller.addCircles([circle]);
    await controller.addPolyline([line]);
    await controller.setUserLocation!(UserMarkerModel(
        latitude: center.latitude + 0.001,
        longitude: center.longitude + 0.001,
        accuracy: 30));
    for (final dark in [true, false, true, false]) {
      await controller.setDarkMode(dark);
      final camera = await controller.camera;
      expect(camera.center.latitude, closeTo(center.latitude, 0.0001));
      events.clear();
      await tapMap(offset: const Offset(0, -10));
      expect(events, contains('marker:device-marker'));
    }

    await controller.removeAllMarkers();
    debugPrint('DEVICE_CHECK: four theme reloads retained overlays');
    await controller.removeAllCircles();
    await controller.removeAllPolyLines();
    events.clear();
    await tapMap();
    expect(events, contains('tap'));

    await controller
        .moveCamera(MoveModel(latitude: 36.32, longitude: 59.55, zoom: 15));
    await tester.pump(const Duration(milliseconds: 800));
    final moved = await controller.camera;
    expect(moved.center.latitude, closeTo(36.32, 0.0001));
    expect(moved.center.longitude, closeTo(59.55, 0.0001));
    expect(moved.zoom, closeTo(15, 0.1));
    await controller.fitBounds(MapBoundsModel(
        points: [const LatLng(36.31, 59.53), const LatLng(36.33, 59.56)],
        padding: 32));
    await tester.pump(const Duration(milliseconds: 800));
    final fitted = await controller.camera;
    expect(fitted.center.latitude, inInclusiveRange(36.31, 36.33));
    expect(fitted.center.longitude, inInclusiveRange(59.53, 59.56));
    expect(fitted.zoom, inInclusiveRange(10, 18));
    await controller.fitBounds(MapBoundsModel(points: []));
    await controller.fitBounds(MapBoundsModel(points: [center]));
    await tester.pump(const Duration(milliseconds: 800));
    expect((await controller.camera).center.latitude,
        closeTo(center.latitude, 0.0001));
    expect(tester.takeException(), isNull);
    debugPrint('DEVICE_CHECK: camera and bounds commands passed');
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets(
      'native map can be disposed and recreated without duplicate events',
      (tester) async {
    for (var round = 0; round < 3; round++) {
      final controller = UiMapController();
      var tapCount = 0;
      await tester.pumpWidget(MaterialApp(
          home: UiMap(
        key: ValueKey(round),
        mapProvider: MapProvider.neshan,
        controller: controller,
        initialCenter: center,
        onTap: (_) => tapCount++,
      )));
      await tester.pumpAndSettle();
      await controller.camera.timeout(const Duration(seconds: 60));
      await nativeTap(tester, tester.getCenter(find.byType(UiMap)));
      expect(tapCount, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  }, timeout: const Timeout(Duration(minutes: 4)));

  testWidgets('native pan, pinch zoom and invalid command recovery',
      (tester) async {
    final controller = UiMapController();
    await tester.pumpWidget(MaterialApp(
        home: UiMap(
      mapProvider: MapProvider.neshan,
      controller: controller,
      initialCenter: center,
      zoom: 15,
    )));
    await tester.pumpAndSettle();
    final before = await controller.camera.timeout(const Duration(seconds: 60));
    final middle = tester.getCenter(find.byType(UiMap));
    final pan = await tester.createGesture();
    await tester.pump();
    await pan.down(middle,
        timeStamp: tester.binding.currentSystemFrameTimeStamp);
    for (var step = 1; step <= 8; step++) {
      await tester.pump(const Duration(milliseconds: 40));
      await pan.moveTo(middle + Offset(step * 15, 0),
          timeStamp: tester.binding.currentSystemFrameTimeStamp);
    }
    await pan.up(timeStamp: tester.binding.currentSystemFrameTimeStamp);
    await tester.pump(const Duration(seconds: 1));
    final panned = await controller.camera;
    expect((panned.center.longitude - before.center.longitude).abs(),
        greaterThan(0.0001));

    final left = await tester.createGesture();
    final right = await tester.createGesture();
    await tester.pump();
    await left.down(middle - const Offset(40, 0),
        timeStamp: tester.binding.currentSystemFrameTimeStamp);
    await right.down(middle + const Offset(40, 0),
        timeStamp: tester.binding.currentSystemFrameTimeStamp);
    // MapLibre filters scale initiation below 0.6 dp/ms. Start with a brisk
    // separation instead of a slow synthetic gesture below that threshold.
    for (final distance in [120.0, 140.0, 160.0]) {
      await tester.pump(const Duration(milliseconds: 16));
      final spread = Offset(distance, 0);
      await left.moveTo(middle - spread,
          timeStamp: tester.binding.currentSystemFrameTimeStamp);
      await right.moveTo(middle + spread,
          timeStamp: tester.binding.currentSystemFrameTimeStamp);
    }
    await left.up(timeStamp: tester.binding.currentSystemFrameTimeStamp);
    await right.up(timeStamp: tester.binding.currentSystemFrameTimeStamp);
    await tester.pump(const Duration(seconds: 1));
    // Amount depends on delivered frames and the SDK's velocity filter; require
    // an observable zoom change without an arbitrary exact gesture magnitude.
    expect((await controller.camera).zoom, greaterThan(panned.zoom + 0.1));

    await expectLater(
        controller.moveCamera(
            MoveModel(latitude: double.nan, longitude: center.longitude)),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'INVALID_ARGUMENT')));
    expect((await controller.camera).zoom.isFinite, isTrue);
    expect(tester.takeException(), isNull);
    debugPrint('DEVICE_CHECK: pan, pinch and invalid-command recovery passed');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
