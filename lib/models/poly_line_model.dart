import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/extensions/hex_color.dart';
import 'package:map_kit/models/poly_line_point_model.dart';

class PolyLineModel {
  final List<PolyLinePointModel>? points;
  final Color color;
  final double? strokeWidth;
  final Color? strokeColor;
  final dynamic data;

  PolyLineModel({this.points, required this.color, this.strokeWidth, this.strokeColor, this.data});

  PolyLineModel.decodePoints(
      {String? encodedPoints, required this.color, this.strokeWidth, this.strokeColor, this.data})
      : points = PolyLinePointModel.decodePoints(encodedPoints);

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
      'data': data?.toString(),
    };
  }

  PolyLineModel copyWith({List<PolyLinePointModel>? points, Color? color, double? strokeWidth, dynamic data}) {
    return PolyLineModel(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      data: data ?? this.data,
    );
  }

  bool isPointNear(LatLng point, double zoom, {double pixelTolerance = 30.0}) {
    if (points == null || points!.isEmpty) return false;
    const double R = 6371000;

    double metersPerPixel = 156543.03392 * math.cos(point.latitude * math.pi / 180) / math.pow(2, zoom);
    double threshold = metersPerPixel * pixelTolerance;

    double minDistance = double.infinity;
    double px0 = point.longitude * math.pi / 180;
    double py0 = point.latitude * math.pi / 180;

    for (int i = 0; i < points!.length - 1; i++) {
      double px1 = points![i].longitude * math.pi / 180;
      double py1 = points![i].latitude * math.pi / 180;
      double px2 = points![i + 1].longitude * math.pi / 180;
      double py2 = points![i + 1].latitude * math.pi / 180;

      double dx2 = (px2 - px1) * math.cos(py1) * R;
      double dy2 = (py2 - py1) * R;
      double dx0 = (px0 - px1) * math.cos(py1) * R;
      double dy0 = (py0 - py1) * R;

      double l2 = dx2 * dx2 + dy2 * dy2;
      double dist;

      if (l2 == 0) {
        dist = math.sqrt(dx0 * dx0 + dy0 * dy0);
      } else {
        double t = ((dx0 * dx2) + (dy0 * dy2)) / l2;
        t = math.max(0, math.min(1, t)); // Constrain to segment
        double projX = t * dx2;
        double projY = t * dy2;
        dist = math.sqrt((dx0 - projX) * (dx0 - projX) + (dy0 - projY) * (dy0 - projY));
      }

      if (dist < minDistance) minDistance = dist;
    }

    return minDistance <= threshold;
  }
}
