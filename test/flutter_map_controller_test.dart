import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/enums/map_provider.dart';
import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/widgets/flutter/flutter_map_widget.dart';
import 'package:map_kit/models/vector_map_style.dart';
import 'package:map_kit/widgets/flutter/vector_map_layer.dart';
import 'package:map_kit/ui_map.dart';

void main() {
  testWidgets('Flutter map supports omitted overlay lists', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: FlutterMapWidget(
      mapProvider: MapProvider.flutter,
      vectorStyle: null,
    )));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('parent theme rebuild keeps the default center valid',
      (tester) async {
    final controller = UiMapController();
    Widget map(bool dark) => MaterialApp(
            home: UiMap(
          mapProvider: MapProvider.flutter,
          vectorStyle: null,
          controller: controller,
          isDarkMode: dark,
        ));
    await tester.pumpWidget(map(false));
    await tester.pumpWidget(map(true));
    expect(tester.takeException(), isNull);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect((await controller.camera).center, const LatLng(35.6892, 51.3890));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Flutter controller changes theme while retaining overlays',
      (tester) async {
    final controller = UiMapController();
    await tester.pumpWidget(MaterialApp(
        home: FlutterMapWidget(
      mapProvider: MapProvider.flutter,
      userAgentPackageName: 'com.golrang.map_kit_example',
      uiMapController: controller,
      initialCenter: const LatLng(36.3, 59.5),
      markers: [],
      polyLines: [],
      circles: [
        CircleModel(
          latitude: 36.3,
          longitude: 59.5,
          radius: 100,
          color: Colors.blue,
          borderColor: Colors.blue,
        )
      ],
    )));
    controller.setDarkMode(true);
    await tester.pump();
    final darkLayer =
        tester.widget<VectorMapLayer>(find.byType(VectorMapLayer));
    expect(darkLayer.dark, isTrue);
    expect(darkLayer.style, VectorMapStyle.googleLike);
    expect(
        darkLayer.style.uriFor(darkLayer.dark), endsWith('google-dark.json'));
    expect(find.byType(TileLayer), findsNothing);
    expect(tester.widget<CircleLayer>(find.byType(CircleLayer)).circles,
        hasLength(1));
    controller.setDarkMode(false);
    await tester.pump();
    final lightLayer =
        tester.widget<VectorMapLayer>(find.byType(VectorMapLayer));
    expect(lightLayer.dark, isFalse);
    expect(lightLayer.style.uriFor(lightLayer.dark),
        endsWith('google-light.json'));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('cleared circles do not leave invisible popup hit targets',
      (tester) async {
    final controller = UiMapController();
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
        home: FlutterMapWidget(
      vectorStyle: null,
      mapProvider: MapProvider.flutter,
      uiMapController: controller,
      initialCenter: const LatLng(36.3, 59.5),
      markers: [],
      polyLines: [],
      circles: [
        CircleModel(
          latitude: 36.3,
          longitude: 59.5,
          radius: 100,
          color: Colors.blue,
          borderColor: Colors.blue,
          snippetTitle: 'Zone',
        )
      ],
      onTap: (_) => taps++,
    )));
    controller.removeAllCircles();
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.byType(FlutterMapWidget)));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(taps, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('map.ir ignores custom themes and stays on its own tiles',
      (tester) async {
    final controller = UiMapController();
    await tester.pumpWidget(MaterialApp(
        home: UiMap(
      mapProvider: MapProvider.mapIr,
      controller: controller,
      vectorStyle: const VectorMapStyle(uri: 'must-not-load'),
    )));
    final original =
        tester.widget<TileLayer>(find.byType(TileLayer)).urlTemplate;
    expect(Uri.parse(original!).host, 'map.ir');
    expect(find.byType(VectorMapLayer), findsNothing);
    controller.setDarkMode(true);
    await tester.pump();
    expect(
        tester.widget<TileLayer>(find.byType(TileLayer)).urlTemplate, original);
    expect(find.text('© OpenStreetMap contributors, map.ir'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
