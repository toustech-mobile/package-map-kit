import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/models/vector_map_style.dart';
import 'package:map_kit/widgets/flutter/vector_map_layer.dart';

class _TrackedStyle extends vt.Style {
  bool disposed = false;

  _TrackedStyle(String id)
      : super(
          theme: vt.Theme(id: id, layers: const []),
          providers: const vt.TileProviders({}),
          attributions: [vt.StyleAttribution.parse('Test source')],
        );

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

void main() {
  test('bundled themes compile road, land and label colors', () {
    for (final mode in ['light', 'dark']) {
      final json = jsonDecode(File(
        'assets/maps/google-$mode.json',
      ).readAsStringSync()) as Map<String, dynamic>;
      final theme = const vt.ThemeReader().read(json);
      const context = vt.EvalContext(zoom: 14);
      expect(theme.backgroundColor(14),
          mode == 'light' ? const Color(0xfff1f3f4) : const Color(0xff202124));
      final roads = theme.layers
          .whereType<vt.LineThemeLayer>()
          .singleWhere((layer) => layer.id == 'roads');
      expect(roads.color.eval(context),
          mode == 'light' ? const Color(0xffffffff) : const Color(0xff454a50));
      final labels = theme.layers.whereType<vt.SymbolThemeLayer>();
      expect(labels, isNotEmpty);
      for (final label in labels.where((layer) => layer.id == 'road-labels')) {
        expect(
            label.textColor.eval(context),
            mode == 'light'
                ? const Color(0xff5f6368)
                : const Color(0xffbdc1c6));
      }
      expect(theme.layers.length, (json['layers'] as List).length,
          reason: 'Every example layer must be supported by the renderer');
    }
  });

  testWidgets('latest style wins and late results are disposed',
      (tester) async {
    final requests = <String, Completer<vt.Style>>{};
    final headersSeen = <Map<String, String>>[];
    final camera = MapController();
    Future<vt.Style> loader(String uri, Map<String, String> headers) {
      headersSeen.add(headers);
      return (requests[uri] = Completer<vt.Style>()).future;
    }

    Widget map(bool dark) => MaterialApp(
          home: FlutterMap(mapController: camera, children: [
            VectorMapLayer(
              style: const VectorMapStyle(
                uri: 'light',
                darkUri: 'dark',
                headers: {'X-Test': 'host-header'},
              ),
              dark: dark,
              loader: loader,
            ),
            const CircleLayer(circles: [
              CircleMarker(point: LatLng(35.7, 51.4), radius: 100),
            ]),
          ]),
        );

    await tester.pumpWidget(map(false));
    camera.move(const LatLng(35.7, 51.4), 14);
    await tester.pumpWidget(map(true));
    expect(headersSeen.last, {'X-Test': 'host-header'});
    final dark = _TrackedStyle('dark');
    requests['dark']!.complete(dark);
    await tester.pump();
    final light = _TrackedStyle('light');
    requests['light']!.complete(light);
    await tester.pump();
    expect(light.disposed, isTrue);
    expect(
        tester
            .widget<vt.VectorTileLayer>(find.byType(vt.VectorTileLayer))
            .theme
            .id,
        'dark');
    expect(find.text('Test source'), findsOneWidget);
    expect(camera.camera.center, const LatLng(35.7, 51.4));
    expect(camera.camera.zoom, 14);
    expect(tester.widget<CircleLayer>(find.byType(CircleLayer)).circles,
        hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(dark.disposed, isTrue);
  });

  testWidgets('failed style can retry and release a result after unmount',
      (tester) async {
    final requests = <Completer<vt.Style>>[];
    await tester.pumpWidget(MaterialApp(
      home: FlutterMap(children: [
        VectorMapLayer(
          style: const VectorMapStyle(uri: 'style'),
          loader: (_, __) {
            final request = Completer<vt.Style>();
            requests.add(request);
            return request.future;
          },
        ),
      ]),
    ));
    requests.single.completeError(StateError('unavailable'));
    await tester.pump();
    expect(find.text('Could not load map style.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(requests, hasLength(2));
    await tester.pumpWidget(const SizedBox.shrink());
    final lateStyle = _TrackedStyle('late');
    requests.last.complete(lateStyle);
    await tester.pump();
    expect(lateStyle.disposed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading theme does not intercept map taps', (tester) async {
    var taps = 0;
    final pending = Completer<vt.Style>();
    await tester.pumpWidget(MaterialApp(
      home: FlutterMap(
        options: MapOptions(onTap: (_, __) => taps++),
        children: [
          VectorMapLayer(
            style: VectorMapStyle.googleLike,
            loader: (_, __) => pending.future,
          ),
        ],
      ),
    ));
    await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(taps, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(_TrackedStyle('unmounted'));
    await tester.pump();
  });
}
