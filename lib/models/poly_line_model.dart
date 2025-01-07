import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/extensions/hex_color.dart';

class PolyLineModel {
  List<LatLng>? points;
  Color? color;
  double? strokeWidth;

  PolyLineModel({this.points, this.color, this.strokeWidth});

  Polyline toFlutterPolyLine() => Polyline(
        points: points!,
        color: color!,
        strokeWidth: strokeWidth!,
      );

  Map<String, dynamic> toNeshanPolyLines() {
    return {
      'points': points!.map((latLng) {
        return {
          "latitude": latLng.latitude,
          "longitude": latLng.longitude,
        };
      }).toList(),
      'color': color!.toHex(),
      'strokeWidth': strokeWidth,
    };
  }
}
