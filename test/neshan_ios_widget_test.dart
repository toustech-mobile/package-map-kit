import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/enums/map_provider.dart';
import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/models/move_model.dart';
import 'package:map_kit/models/poly_line_model.dart';
import 'package:map_kit/models/poly_line_point_model.dart';
import 'package:map_kit/ui_map.dart';
import 'package:map_kit/widgets/neshan/neshan_marker_codec.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const commands = MethodChannel('com.example.example/method_channel');
  const events = MethodChannel('com.yourapp/event_channel');
  final views = <MethodCall>[];
  final calls = <MethodCall>[];
  final subscriptions = <String>[];

  setUp(() {
    views.clear();
    calls.clear();
    subscriptions.clear();
    messenger.setMockMethodCallHandler(SystemChannels.platform_views,
        (call) async {
      views.add(call);
      return null;
    });
    messenger.setMockMethodCallHandler(commands, (call) async {
      calls.add(call);
      if (call.method == 'getCamera') {
        return {'latitude': 35, 'longitude': 51, 'zoom': 14};
      }
      return null;
    });
    messenger.setMockMethodCallHandler(events, (call) async {
      subscriptions.add(call.method);
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
    messenger.setMockMethodCallHandler(commands, null);
    messenger.setMockMethodCallHandler(events, null);
  });

  Future<void> emit(String name, Map<String, dynamic> data) async {
    final ByteData bytes = const StandardMethodCodec()
        .encodeSuccessEnvelope({'event': name, 'data': data});
    await messenger.handlePlatformMessage(events.name, bytes, (_) {});
  }

  testWidgets(
      'iOS rasterizes shared SVG marker assets and keeps a native fallback',
      (tester) async {
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      if (const StringCodec().decodeMessage(message) ==
          'assets/icons/ios-test.svg') {
        return const StringCodec().encodeMessage(
          '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="10">'
          '<rect width="20" height="10" fill="#ff0000"/></svg>',
        );
      }
      return null;
    });
    try {
      await tester.runAsync(() async {
        final specs = await NeshanMarkerCodec.encode([
          MarkerModel(
              latitude: 35,
              longitude: 51,
              icon: 'ios-test.svg',
              iconSize: 40,
              markerContent: 'ios-test.svg'),
          MarkerModel(latitude: 35, longitude: 51, icon: 'missing.svg'),
        ]);
        expect(specs.first['iconBytes'], isA<Uint8List>());
        expect(specs.first['markerContentBytes'], isA<Uint8List>());
        final codec = await ui
            .instantiateImageCodec(specs.first['iconBytes'] as Uint8List);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 80);
        expect(frame.image.height, 80);
        frame.image.dispose();
        codec.dispose();
        expect(specs.last['icon'], 'missing.svg');
        expect(specs.last.containsKey('iconBytes'), false);
      });
    } finally {
      messenger.setMockMessageHandler('flutter/assets', null);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('iOS forwards initial camera, theme and every overlay to UIKit',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: UiMap(
      mapProvider: MapProvider.neshan,
      initialCenter: const LatLng(36.3, 59.5),
      zoom: 16,
      isDarkMode: true,
      markers: [
        MarkerModel(latitude: 36.3, longitude: 59.5, icon: '', data: 'office')
      ],
      circles: [
        CircleModel(
            latitude: 36.3,
            longitude: 59.5,
            radius: 100,
            color: Colors.blue,
            borderColor: Colors.red)
      ],
      polyLines: [
        PolyLineModel(points: [
          PolyLinePointModel(36.3, 59.5, 0),
          PolyLinePointModel(36.4, 59.6, 0)
        ], color: Colors.green, strokeWidth: 4)
      ],
    )));
    await tester.pumpAndSettle();
    expect(find.byType(UiKitView), findsOneWidget);
    expect(find.byType(AndroidView), findsNothing);
    final create = views.singleWhere((call) => call.method == 'create');
    expect(create.arguments['viewType'], 'map_kit_view');
    final params = const StandardMessageCodec().decodeMessage(
        ByteData.sublistView(create.arguments['params'] as Uint8List)) as Map;
    expect(params['initialCenter'], {'latitude': 36.3, 'longitude': 59.5});
    expect(params['zoom'], 16.0);
    expect(params['isDarkMode'], true);
    expect((params['markers'] as List).single['data'], 'office');
    expect(params['circles'], hasLength(1));
    expect(params['polyLines'], hasLength(1));
    expect(subscriptions, ['listen']);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(subscriptions, ['listen', 'cancel']);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets(
      'iOS shares commands and callbacks and cancels events on disposal',
      (tester) async {
    final controller = UiMapController();
    final received = <String>[];
    Widget buildMap() => MaterialApp(
            home: UiMap(
          mapProvider: MapProvider.neshan,
          controller: controller,
          onTap: (point) => received.add('tap:${point.latitude}'),
          onLongPress: (_) => received.add('long'),
          onMarkerTap: (data, _) => received.add('marker:$data'),
          onCircleTap: (data, _) => received.add('circle:$data'),
          onPolylineTap: (data, point) => received.add('line:$data:$point'),
        ));
    await tester.pumpWidget(buildMap());
    await tester.pumpAndSettle();
    await controller
        .moveCamera(MoveModel(latitude: 35, longitude: 51, zoom: 14));
    await controller.setDarkMode(true);
    expect((await controller.camera).center, const LatLng(35, 51));
    expect(calls.map((call) => call.method),
        ['moveCamera', 'setMapStyle', 'getCamera']);
    await emit('onMapTap', {'latitude': 35.0, 'longitude': 51.0});
    await emit('onMapLongPress', {'latitude': 35.0, 'longitude': 51.0});
    await emit(
        'onMarkerTap', {'latitude': 35.0, 'longitude': 51.0, 'data': 'office'});
    // StandardMessageCodec can deliver integers as well as doubles.
    await emit(
        'onCircleTap', {'latitude': 35, 'longitude': 51, 'data': 'area'});
    await emit('onPolylineTap',
        {'latitude': null, 'longitude': null, 'data': 'route'});
    await tester.pump();
    expect(received, [
      'tap:35.0',
      'long',
      'marker:office',
      'circle:area',
      'line:route:null'
    ]);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(subscriptions, ['listen', 'cancel']);
    await tester.pumpWidget(buildMap());
    await tester.pumpAndSettle();
    received.clear();
    await emit('onMapTap', {'latitude': 35.0, 'longitude': 51.0});
    await tester.pump();
    expect(received, ['tap:35.0']);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(subscriptions, ['listen', 'cancel', 'listen', 'cancel']);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
