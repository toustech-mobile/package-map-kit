import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/models/circle_marker_model.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/models/move_model.dart';
import 'package:map_kit/models/poly_line_model.dart';

import '../models/user_marker.dart';

class FlutterMapWidget extends StatefulWidget {
  PopupController? popupController = PopupController();
  UiMapController? uiMapController;
  List<MarkerModel>? markers;
  List<PolyLineModel>? polyLines;
  List<CircleMarkerModel>? circles;
  UserMarkerModel? userMarker;
  LatLng? initialCenter;
  bool? isDarkMode;
  bool? isCurrentLocationEnable;
  double? zoom;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongPress;
  final void Function(MarkerModel)? onMarkerTap;
  final void Function(CircleMarkerModel)? onCircleTap;

  FlutterMapWidget({
    this.uiMapController,
    this.markers,
    this.polyLines,
    this.circles,
    this.initialCenter,
    this.isDarkMode,
    this.isCurrentLocationEnable,
    this.zoom,
    this.onTap,
    this.onLongPress,
    this.onMarkerTap,
    this.onCircleTap,
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
        widget.markers!.add(marker);
        setState(() {});
      };

      widget.uiMapController!.addCircle = (circleMarkerModel) {
        widget.circles!.add(circleMarkerModel);
        setState(() {});
      };

      widget.uiMapController!.addPolyline = (polyLines) {
        widget.polyLines!.addAll(polyLines);
        setState(() {});
      };

      widget.uiMapController!.moveCamera = (MoveModel moveModel) {
        _mapController.move(moveModel.point, moveModel.zoom);
        setState(() {});
      };

      widget.uiMapController!.setUserLocation = (userMarker) {
        widget.userMarker = userMarker;
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
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: widget.initialCenter!,
          initialZoom: widget.zoom ?? 13,
          onPositionChanged: (MapCamera position, bool hasGesture) {},
          onTap: (tapPosition, point) {
            widget.popupController!.hideAllPopups();

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
            widget.popupController!.hideAllPopups();
            if (widget.onLongPress != null) widget.onLongPress!(point);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: widget.isDarkMode ?? false
                ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
                : "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
          ),
          CircleLayer(
              circles: widget.circles!
                  .map((markerModel) => markerModel.toFlutterCircleMarker())
                  .toList()),
          _markers(),
          PolylineLayer(
              polylines: widget.polyLines!
                  .map((polyLineModel) => polyLineModel.toFlutterPolyLine())
                  .toList()),
          widget.userMarker != null
              ? widget.userMarker!.toUserMarker()
              : Container()
        ],
      ),
      floatingActionButton: Visibility(
        visible: widget.isCurrentLocationEnable!,
        child: FloatingActionButton(
          onPressed: () {
            _mapController.move(
                LatLng(
                    widget.userMarker!.latitude, widget.userMarker!.longitude),
                11);
          },
          child: const Icon(
            Icons.my_location,
          ),
        ),
      ),
    );
  }

  PopupMarkerLayer _markers() {
    return PopupMarkerLayer(
      options: PopupMarkerLayerOptions(
        popupController: widget.popupController,
        markers:
            widget.markers!.map((marker) => marker.toFlutterMarker()).toList(),
        popupDisplayOptions: PopupDisplayOptions(
          builder: (BuildContext context, Marker marker) {
            MarkerModel? tappedMarker;
            for (var m in widget.markers!) {
              if (m.latitude == marker.point.latitude &&
                  m.longitude == marker.point.longitude) {
                tappedMarker = m;
                widget.onMarkerTap!(tappedMarker);
                break;
              }
            }
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Click On Marker ${tappedMarker!.data}',
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ),
    );
  }
}
