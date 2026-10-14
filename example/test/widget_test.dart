import 'package:flutter_test/flutter_test.dart';
import 'package:map_kit_example/main.dart';

void main() {
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
