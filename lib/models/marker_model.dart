import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

class MarkerModel {
  double latitude;
  double longitude;
  dynamic data;
  String icon;
  int? iconSize;
  Widget? snippetWidget; //todo must be removed
  String? snippetTitle;
  String? snippetDescription;

  MarkerModel({
    required this.latitude,
    required this.longitude,
    this.data,
    required this.icon,
    this.iconSize,
    this.snippetWidget,
    this.snippetTitle,
    this.snippetDescription,
  });

  Marker toFlutterMarker() {
    if (icon.isNotEmpty) {
      return Marker(
        point: LatLng(latitude, longitude),
        child: SvgPicture.asset(
          icon.isEmpty ? 'assets/icons/icon.svg' : "assets/icons/$icon",
          width: iconSize?.toDouble() ?? 30,
          height: iconSize?.toDouble() ?? 30,
        ),
      );
    } else {
      return Marker(
        point: LatLng(latitude, longitude),
        child: const Icon(Icons.circle, color: Colors.transparent, ),
      );
    }
  }

  Map<String, dynamic> toNeshanMarker() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'data': data,
      'icon': icon,
      'iconSize': iconSize,
      'snippetTitle': snippetTitle,
      'snippetDescription': snippetDescription,
    };
  }
}
