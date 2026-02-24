import 'package:latlong2/latlong.dart';

class MapBoundsModel {
  final List<LatLng> points;
  final double padding;

  MapBoundsModel({
    required this.points,
    this.padding = 24,
  });
}
