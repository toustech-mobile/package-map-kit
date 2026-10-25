import 'package:flutter/foundation.dart';

/// A MapLibre style JSON document for `MapProvider.flutter` only.
///
/// Use an HTTPS URL or `asset://assets/maps/style.json`. Declare asset styles
/// in the host's pubspec. Source layers must match the vector tile service.
@immutable
class VectorMapStyle {
  /// Google Maps-inspired colors rendered with OpenFreeMap vector data.
  static const googleLike = VectorMapStyle(
    uri: 'asset://packages/map_kit/assets/maps/google-light.json',
    darkUri: 'asset://packages/map_kit/assets/maps/google-dark.json',
    attribution: '© OpenStreetMap contributors, OpenMapTiles, OpenFreeMap',
  );

  final String uri;

  /// If omitted, dark mode keeps [uri] without changing map services.
  final String? darkUri;

  /// Sent to the style and its referenced sources, sprites and tiles.
  final Map<String, String> headers;

  /// Additional credit displayed alongside the source's own attribution.
  final String attribution;

  const VectorMapStyle({
    required this.uri,
    this.darkUri,
    this.headers = const {},
    this.attribution = '',
  });

  String uriFor(bool dark) => dark ? darkUri ?? uri : uri;
}
