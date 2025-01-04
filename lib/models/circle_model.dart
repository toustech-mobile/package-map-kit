import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/extensions/hex_color.dart';

class CircleModel {
  double latitude;
  double longitude;
  double radius;
  double? borderStroke;
  Color? color;
  Color? borderColor;
  dynamic data;
  bool? visibility;

  CircleModel({
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.borderStroke,
    this.color,
    this.borderColor,
    this.data,
    this.visibility,
  });

  CircleMarker toFlutterCircleMarker() => CircleMarker(
        point: LatLng(latitude, longitude),
        color: color ?? Colors.blue.withOpacity(0.5),
        borderColor: borderColor ?? Colors.blue,
        borderStrokeWidth: borderStroke ?? 2,
        useRadiusInMeter: true,
        radius: radius,
      );

  Map<String, dynamic> toNeshanCircle() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'borderStroke': borderStroke ?? 2,
      'color': color!.toHex(),
      'borderColor': borderColor!.toHex(),
      'data': data,
      'visibility': visibility ?? true,
    };
  }
}
