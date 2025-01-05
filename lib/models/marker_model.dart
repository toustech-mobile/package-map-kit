import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

class MarkerModel {
  double latitude;
  double longitude;
  dynamic data;
  String icon;
  Widget? snippetWidget;
  bool? visibility;

  MarkerModel(
      {required this.latitude,
      required this.longitude,
      this.data,
      required this.icon,
      this.snippetWidget,
      this.visibility});

  Marker toFlutterMarker() => Marker(
        point: LatLng(latitude, longitude),
        child: SvgPicture.asset(icon.isEmpty ? 'assets/icons/icon.svg' : "assets/icons/$icon"),
      );

  Map<String, dynamic> toNeshanMarker() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'data': data,
      'icon': icon,
      'visibility': visibility ?? true,
    };
  }
}
