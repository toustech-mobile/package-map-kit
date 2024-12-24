import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CircleMarkerModel {
  double latitude;
  double longitude;
  double radius;
  double? borderStroke;
  Color? color;
  Color? borderColor;
  dynamic data;

  CircleMarkerModel({
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.borderStroke,
    this.color,
    this.borderColor,
    this.data,
  });

  CircleMarker toFlutterCircleMarker() => CircleMarker(
        point: LatLng(latitude, longitude),
        color: color ?? Colors.blue.withOpacity(0.5),
        borderColor: borderColor ?? Colors.blue,
        borderStrokeWidth: borderStroke ?? 2,
        useRadiusInMeter: true,
        radius: radius,
      );
}
