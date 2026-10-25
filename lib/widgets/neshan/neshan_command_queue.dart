import 'dart:async';

import 'package:flutter/services.dart';

/// Owns the lifetime of one native map's controller commands. Attachment is
/// distinct from style readiness, which is handled by the native renderer.
class NeshanCommandQueue {
  NeshanCommandQueue(
      {Duration attachmentTimeout = const Duration(seconds: 30)}) {
    _timer = Timer(attachmentTimeout, () {
      failAttachment(PlatformException(
        code: 'MAP_ATTACH_TIMEOUT',
        message: 'Timed out waiting for the native Neshan map to attach.',
      ));
    });
  }

  final _attached = Completer<void>();
  final _disposedSignal = Completer<void>();
  Future<void> _tail = Future<void>.value();
  Timer? _timer;
  Object? _attachmentError;
  StackTrace? _attachmentStack;
  bool _disposed = false;

  void attach() {
    if (_disposed || _attached.isCompleted) return;
    _timer?.cancel();
    _attached.complete();
  }

  void failAttachment(Object error, [StackTrace? stack]) {
    if (_attached.isCompleted) return;
    _timer?.cancel();
    _attachmentError = error;
    _attachmentStack = stack;
    // Store errors as state, rather than an unobserved failed gate future.
    _attached.complete();
  }

  Future<T> run<T>(Future<T> Function() action) {
    final operation = _tail.then<T>((_) async {
      await _attached.future;
      if (_disposed) throw _disposedError();
      if (_attachmentError != null) {
        Error.throwWithStackTrace(
            _attachmentError!, _attachmentStack ?? StackTrace.current);
      }
      return Future.any<T>([
        Future<T>.sync(action),
        _disposedSignal.future.then<T>((_) => throw _disposedError()),
      ]);
    });
    // One rejected command must not prevent later commands from running.
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    if (!_attached.isCompleted) _attached.complete();
    _disposedSignal.complete();
  }

  static PlatformException _disposedError() => PlatformException(
        code: 'MAP_DISPOSED',
        message: 'This Neshan map has been disposed.',
      );
}
