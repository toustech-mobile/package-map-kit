import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/extensions/hex_color.dart';
import 'package:map_kit/models/poly_line_point_model.dart';

class PolyLineModel {
  List<PolyLinePointModel>? points;
  Color color;
  double? strokeWidth;
  Color? strokeColor;
  bool? showArrow;

  PolyLineModel({this.points, required this.color, this.strokeWidth, this.strokeColor, this.showArrow});

  Polyline toFlutterPolyLine() => Polyline(
        points: points!.map((point) => LatLng(point.latitude, point.longitude)).toList(),
        color: color,
        strokeWidth: strokeWidth!,
      );


  Map<String, dynamic> toNeshanPolyLines() {
    return {
      'points': points!.map((point) {
        return {
          "latitude": point.latitude,
          "longitude": point.longitude,
          "heading": point.heading,
        };
      }).toList(),
      'color': color.toHex(),
      'strokeWidth': strokeWidth,
      'strokeColor': strokeColor != null ? strokeColor!.toHex() : color.withAlpha(100).toHex(),
      'showArrow': showArrow,
    };
  }

  PolyLineModel copyWith({
    List<PolyLinePointModel>? points,
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
