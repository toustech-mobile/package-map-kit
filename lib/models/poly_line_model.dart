import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
}
