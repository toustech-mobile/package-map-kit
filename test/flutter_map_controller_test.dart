import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/enums/map_provider.dart';
import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/widgets/flutter/flutter_map_widget.dart';

void main() {
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
    expect(tester.widget<TileLayer>(find.byType(TileLayer)).urlTemplate,
        contains('dark_all'));
    expect(tester.widget<TileLayer>(find.byType(TileLayer))
        .tileProvider.headers['User-Agent'], contains('com.golrang.map_kit_example'));
    expect(find.text('© OpenStreetMap contributors, CARTO'), findsOneWidget);
    expect(tester.widget<CircleLayer>(find.byType(CircleLayer)).circles,
        hasLength(1));
    controller.setDarkMode(false);
    await tester.pump();
    expect(tester.widget<TileLayer>(find.byType(TileLayer)).urlTemplate,
        contains('tile.openstreetmap.org'));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('cleared circles do not leave invisible popup hit targets',
      (tester) async {
    final controller = UiMapController();
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
        home: FlutterMapWidget(
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
}
