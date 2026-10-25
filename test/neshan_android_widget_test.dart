import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/widgets/neshan/neshan_map_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('com.example.example/method_channel');
  const events = MethodChannel('com.yourapp/event_channel');

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(events, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
  });

  testWidgets(
      'missing Android key rejects queued commands before view creation',
      (tester) async {
    final configured = Completer<void>();
    final calls = <String>[];
    final platformCalls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      await configured.future;
      throw PlatformException(
        code: 'NESHAN_API_KEY_MISSING',
        message: 'Set map_kit_neshan_api_key in the package configuration.',
      );
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform_views,
        (call) async {
      platformCalls.add(call.method);
      return null;
    });
    final controller = UiMapController();
    await tester.pumpWidget(MaterialApp(
      home: NeshanMapWidget(uiMapController: controller),
    ));
    final missingKey = throwsA(isA<PlatformException>()
        .having((error) => error.code, 'code', 'NESHAN_API_KEY_MISSING'));
    final clearing = expectLater(controller.removeAllMarkers(), missingKey);
    final adding = expectLater(
        controller.addMarkers([
          MarkerModel(latitude: 35, longitude: 51, icon: ''),
        ]),
        missingKey);
    configured.complete();
    await tester.pumpAndSettle();
    await clearing;
    await adding;
    expect(calls, ['validateConfiguration']);
    expect(platformCalls, isEmpty);
    expect(find.byType(AndroidView), findsNothing);
    expect(tester.widget<ErrorWidget>(find.byType(ErrorWidget)).message,
        contains('NESHAN_API_KEY_MISSING'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('valid Android setup waits for view attachment before commands',
      (tester) async {
    final created = Completer<void>();
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });
    messenger.setMockMethodCallHandler(events, (call) async => null);
    messenger.setMockMethodCallHandler(SystemChannels.platform_views,
        (call) async {
      if (call.method == 'create') {
        await created.future;
        return 1;
      }
      return null;
    });
    final controller = UiMapController();
    await tester.pumpWidget(MaterialApp(
      home: NeshanMapWidget(uiMapController: controller),
    ));
    await tester.pump();
    final clearing = controller.removeAllMarkers();
    final adding = controller.addMarkers([
      MarkerModel(latitude: 35, longitude: 51, icon: ''),
    ]);
    await tester.pump();
    expect(calls, ['validateConfiguration']);
    expect(find.byType(AndroidView), findsOneWidget);
    created.complete();
    await tester.pumpAndSettle();
    await clearing;
    await adding;
    expect(calls, ['validateConfiguration', 'removeAllMarkers', 'addMarkers']);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
