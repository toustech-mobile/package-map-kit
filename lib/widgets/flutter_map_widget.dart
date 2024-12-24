import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/models/circle_marker_model.dart';
import 'package:map_kit/models/marker_model.dart';

class FlutterMapWidget extends StatefulWidget {
  UiMapController? uiMapController;
  List<Marker>? markers;
  List<CircleMarkerModel>? circles;
  LatLng? initialCenter;
  bool? isDarkMode;
  double? zoom;
  final void Function(MarkerModel)? onMarkerTap;
  final void Function(CircleMarkerModel)? onCircleTap;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongPress;

  FlutterMapWidget({
    this.uiMapController,
    this.markers,
    this.circles,
    this.initialCenter,
    this.isDarkMode,
    this.zoom,
    this.onMarkerTap,
    this.onCircleTap,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<FlutterMapWidget> createState() => _FlutterMapWidgetState();
}

class _FlutterMapWidgetState extends State<FlutterMapWidget> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    if (widget.uiMapController != null) {
      widget.uiMapController!.addMarker = (MarkerModel marker) {
        widget.markers!.add(marker.toFlutterMarker(widget.onMarkerTap));
        setState(() {});
      };

      widget.uiMapController!.addCircle = (circleMarkerModel) {
        widget.circles!.add(circleMarkerModel);
        setState(() {});
      };
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _buildFlutterMap();
  }

  Widget _buildFlutterMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: widget.initialCenter,
        zoom: widget.zoom ?? 13,
        onTap: (tapPosition, point) {
          bool isCircleClicked = false;
          for (var circle in widget.circles!) {
            final distance = const Distance().as(LengthUnit.Meter,
                LatLng(circle.latitude, circle.longitude), point);
            if (distance <= circle.radius) {
              if (widget.onCircleTap != null) {
                widget.onCircleTap!.call(circle);
              }
              isCircleClicked = true;
              break;
            }
          }
          if (!isCircleClicked) {
            widget.onTap?.call(point); // Call onTap if no circle was clicked
          }
        },
        onLongPress: (tapPosition, point) {
          if (widget.onLongPress != null) widget.onLongPress!(point);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: widget.isDarkMode ?? false
              ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
              : "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
        ),
        CircleLayer(
            circles: widget.circles!
                .map((markerModel) => markerModel.toFlutterCircleMarker())
                .toList()),
        MarkerLayer(markers: widget.markers!),
        // PolylineLayer(polylines: widget.polyLines!),
      ],
    );
  }
}
