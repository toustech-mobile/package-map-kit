import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/extensions/hex_color.dart';

class PolyLineModel {
  List<LatLng>? points;
  Color color;
  double? strokeWidth;
  Color? strokeColor;

  PolyLineModel({this.points, required this.color, this.strokeWidth, this.strokeColor});

  Polyline toFlutterPolyLine() => Polyline(
        points: points!,
        color: color,
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
      'color': color.toHex(),
      'strokeWidth': strokeWidth,
      'strokeColor': strokeColor != null ? strokeColor!.toHex() : color.withAlpha(100).toHex(),
    };
  }

  PolyLineModel copyWith({
    List<LatLng>? points,
    Color? color,
    double? strokeWidth,
  }) {
    return PolyLineModel(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}
