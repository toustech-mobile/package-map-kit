import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/widgets/marker_widget.dart';

class MarkerModel {
  double latitude;
  double longitude;
  dynamic data;
  Widget child;

  MarkerModel({
    required this.latitude,
    required this.longitude,
    this.data,
    required this.child,
  });

  Marker toFlutterMarker(void Function(MarkerModel)? onMarkerTap) => Marker(
        point: LatLng(latitude, longitude),
        builder: (context) => MarkerWidget(
          model: this,
          onMarkerTap: onMarkerTap,
          child: child,
        ),
      );
}
