import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class UserMarkerModel {
  double latitude;
  double longitude;
  double accuracy;
  double? borderStroke;

  UserMarkerModel({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.borderStroke,
  });

  Widget toUserMarker() => Stack(
        children: [
          CircleLayer(
            circles: [
              CircleMarker(
                point: LatLng(latitude, longitude),
                color: Colors.blue.withOpacity(0.5),
                borderColor: Colors.blue,
                borderStrokeWidth: borderStroke ?? 2,
                useRadiusInMeter: true,
                radius: accuracy,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(latitude, longitude),
                child: Container(
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                      border: Border.fromBorderSide(BorderSide(color: Colors.white))),
                ),
                width: 18,
                height: 18,
              ),
            ],
          ),
        ],
      );

  Map<String, dynamic> toNeshanUserMarker() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
    };
  }
}
