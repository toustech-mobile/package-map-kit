import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_kit/models/vector_map_style.dart';
import 'package:map_kit_example/main.dart';

void main() {
  testWidgets('Flutter themes are bundled as package assets', (tester) async {
    for (final dark in [false, true]) {
      final uri = VectorMapStyle.googleLike.uriFor(dark);
      final document = jsonDecode(await rootBundle.loadString(
        uri.substring('asset://'.length),
      )) as Map<String, dynamic>;
      expect(document['layers'], isNotEmpty);
      expect(document['name'], contains(dark ? 'Dark' : 'Light'));
    }
  });

  testWidgets('map demo exposes its provider and control panel',
      (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Map Kit'), findsOneWidget);
    expect(find.text('NESHAN'), findsOneWidget);
    expect(find.text('Controls'), findsOneWidget);

    await tester.tap(find.text('Controls'));
    await tester.pumpAndSettle();
    expect(find.text('Map Controllers'), findsOneWidget);
    expect(find.text('+ Markers'), findsOneWidget);
    expect(find.text('+ Circles'), findsOneWidget);
    expect(find.text('+ Polyline'), findsOneWidget);
    expect(find.text('Fit Bounds'), findsOneWidget);
    expect(find.text('Get Camera Info'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
