import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:map_kit/models/marker_model.dart';

/// Android resolves drawable names. iOS receives PNGs made from the same host
/// SVG assets used by the Flutter renderer, with a native pin as fallback.
abstract final class NeshanMarkerCodec {
  static Future<List<Map<String, dynamic>>> encode(
      List<MarkerModel> markers) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return markers.map((marker) => marker.toNeshanMarker()).toList();
    }
    return Future.wait(markers.map((marker) async {
      final spec = marker.toNeshanMarker();
      final size = marker.iconSize ?? 32;
      // Leave invalid values for the native argument validator.
      if (size <= 0 || size > 512) return spec;
      final views = WidgetsBinding.instance.platformDispatcher.views;
      final ratio = views.isEmpty ? 2.0 : views.first.devicePixelRatio;
      final pixels = (size * ratio).round().clamp(1, 2048);
      final icon = await _rasterize(marker.icon, pixels);
      if (icon != null) {
        spec['iconBytes'] = icon.bytes;
        spec['contentCenterY'] = icon.contentCenterY;
      }
      final content = marker.markerContent;
      if (content != null && content.length > 2) {
        final image = await _rasterize(content, pixels);
        if (image != null) spec['markerContentBytes'] = image.bytes;
      }
      return spec;
    }));
  }

  static Future<({Uint8List bytes, double contentCenterY})?> _rasterize(
      String name, int pixels) async {
    if (name.isEmpty) return null;
    PictureInfo? source;
    ui.Picture? picture;
    ui.Image? image;
    try {
      final path = name.startsWith('assets/') ? name : 'assets/icons/$name';
      // Resolve missing host assets before entering flutter_svg's shared cache,
      // whose pending-loader errors can otherwise escape as unhandled futures.
      final xml = await rootBundle.loadString(path);
      source = await vg.loadPicture(SvgStringLoader(xml), null);
      if (source.size.isEmpty) return null;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final scale = pixels / source.size.longestSide;
      canvas.translate((pixels - source.size.width * scale) / 2,
          (pixels - source.size.height * scale) / 2);
      canvas.scale(scale);
      canvas.drawPicture(source.picture);
      picture = recorder.endRecording();
      image = await picture.toImage(pixels, pixels);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;
      // Portrait pins have a circular head above their stem. Preserve its
      // center before aspect-fit rasterization turns the image into a square.
      final contentCenterY = source.size.height > source.size.width
          ? source.size.width / (2 * source.size.height)
          : 0.5;
      return (
        bytes: bytes.buffer.asUint8List(),
        contentCenterY: contentCenterY,
      );
    } catch (_) {
      // A host can supply an iOS asset-catalog image instead of a Flutter SVG.
      return null;
    } finally {
      image?.dispose();
      picture?.dispose();
      source?.picture.dispose();
    }
  }
}
