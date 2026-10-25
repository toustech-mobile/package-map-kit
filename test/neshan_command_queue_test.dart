import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_kit/widgets/neshan/neshan_command_queue.dart';

void main() {
  Matcher errorCode(String code) =>
      isA<PlatformException>().having((error) => error.code, 'code', code);

  testWidgets('commands wait for attachment and execute in invocation order',
      (tester) async {
    final queue = NeshanCommandQueue();
    addTearDown(queue.dispose);
    final firstReply = Completer<void>();
    final events = <String>[];
    final first = queue.run(() async {
      events.add('first-start');
      await firstReply.future;
      events.add('first-end');
    });
    final second = queue.run(() async => events.add('second'));
    await tester.pump();
    expect(events, isEmpty);
    queue.attach();
    await tester.pump();
    expect(events, ['first-start']);
    firstReply.complete();
    await first;
    await second;
    expect(events, ['first-start', 'first-end', 'second']);
  });

  testWidgets('a rejected command does not block the next command',
      (tester) async {
    final queue = NeshanCommandQueue();
    addTearDown(queue.dispose);
    queue.attach();
    final first =
        queue.run<void>(() async => throw StateError('invalid command'));
    final second = queue.run(() async => 42);
    await expectLater(first, throwsStateError);
    expect(await second, 42);
  });

  testWidgets('disposal rejects queued calls without executing them',
      (tester) async {
    final queue = NeshanCommandQueue();
    var called = false;
    final pending = queue.run(() async => called = true);
    final rejected = expectLater(pending, throwsA(errorCode('MAP_DISPOSED')));
    queue.dispose();
    await rejected;
    expect(called, false);
  });

  testWidgets('disposal also completes an active native operation',
      (tester) async {
    final queue = NeshanCommandQueue();
    queue.attach();
    final nativeReply = Completer<void>();
    final active = queue.run(() => nativeReply.future);
    final rejected = expectLater(active, throwsA(errorCode('MAP_DISPOSED')));
    await tester.pump();
    queue.dispose();
    await rejected;
    nativeReply.completeError(StateError('late native error'));
    await tester.pump();
  });

  testWidgets('attachment failures and timeouts complete pending commands',
      (tester) async {
    final failed = NeshanCommandQueue();
    addTearDown(failed.dispose);
    failed
        .failAttachment(PlatformException(code: 'NESHAN_IOS_PLUGIN_MISMATCH'));
    await expectLater(failed.run(() async => 1),
        throwsA(errorCode('NESHAN_IOS_PLUGIN_MISMATCH')));
    final slow =
        NeshanCommandQueue(attachmentTimeout: const Duration(seconds: 2));
    addTearDown(slow.dispose);
    final rejected = expectLater(
        slow.run(() async => 1), throwsA(errorCode('MAP_ATTACH_TIMEOUT')));
    await tester.pump(const Duration(seconds: 2));
    await rejected;
  });
}
