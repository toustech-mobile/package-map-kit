import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MarkerModel {
  double latitude;
  double longitude;
  dynamic data;
  Widget child;
  Widget? snippetWidget;

  MarkerModel({
    required this.latitude,
    required this.longitude,
    this.data,
    required this.child,
    this.snippetWidget,
  });

  Marker toFlutterMarker() => Marker(
        point: LatLng(latitude, longitude),
        child: child,
      );
}
