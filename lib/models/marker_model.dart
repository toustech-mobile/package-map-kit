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
  String? markerContent = '';

  MarkerModel({
    required this.latitude,
    required this.longitude,
    this.data,
    required this.icon,
    this.iconSize,
    this.snippetWidget,
    this.snippetTitle,
    this.snippetDescription,
    this.markerContent,
  });

  Marker toFlutterMarker() {
    if (icon.isNotEmpty) {
      return Marker(
        point: LatLng(latitude, longitude),
        width: iconSize?.toDouble() ?? 30,
        height: iconSize?.toDouble() ?? 30,
        child: Stack(
          children: [
            SizedBox(
              width: iconSize?.toDouble() ?? 30,
              height: iconSize?.toDouble() ?? 30,
              child: SvgPicture.asset(
                icon.isEmpty ? 'assets/icons/icon.svg' : "assets/icons/$icon",
                fit: BoxFit.contain,
              ),
            ),
            Center(
                child: Padding(
              padding: EdgeInsets.only(bottom: iconSize == null ? 6 : (iconSize! / 4) - 2),
              child: Stack(
                children: [
                  if (markerContent != null)
                    markerContent!.length <= 2
                        ? Text(
                            markerContent ?? '2',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          )
                        : SizedBox(
                            width: iconSize! / 2,
                            height: iconSize! / 2,
                            child: SvgPicture.asset(
                              'assets/icons/$markerContent',
                              fit: BoxFit.contain,
                            ),
                          ),
                ],
              ),
            ))
          ],
        ),
      );
    } else {
      return Marker(
        point: LatLng(latitude, longitude),
        child: const Icon(Icons.circle, color: Colors.transparent),
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
      'markerContent': markerContent,
    };
  }
}
