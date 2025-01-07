import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/enums/map_provider.dart';
import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/models/move_model.dart';
import 'package:map_kit/models/poly_line_model.dart';

import '../../models/user_marker.dart';

class FlutterMapWidget extends StatefulWidget {
  PopupController? popupController = PopupController();
  UiMapController? uiMapController;
  List<MarkerModel>? markers;
  List<PolyLineModel>? polyLines;
  List<CircleModel>? circles;
  UserMarkerModel? userMarker;
  LatLng? initialCenter;
  bool? isDarkMode;
  bool? isCurrentLocationEnable;
  double? zoom;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongPress;
  final void Function(MarkerModel)? onMarkerTap;
  final void Function(CircleModel)? onCircleTap;
  MapProvider? mapProvider;

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
    this.mapProvider,
  });

  @override
  State<FlutterMapWidget> createState() => _FlutterMapWidgetState();
}

class _FlutterMapWidgetState extends State<FlutterMapWidget> {
  final MapController _mapController = MapController();
  String tileUrl = '';

  @override
  void initState() {
    if (widget.uiMapController != null) {
      widget.uiMapController!.addMarkers = (List<MarkerModel> markers) {
        widget.markers!.addAll(markers);
        setState(() {});
      };

      widget.uiMapController!.addCircles = (circleMarkerModel) {
        widget.circles!.addAll(circleMarkerModel);
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
    if (widget.mapProvider == MapProvider.mapIr) {
      tileUrl =
          "https://map.ir/shiveh/xyz/1.0.0/Shiveh:Shiveh@EPSG:3857@png/{z}/{x}/{y}.png"
          "?x-api-key=eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6IjAwN2VjZjAzNGM3MTVkYmRjMTI1ZWIxNzA4YWNiMzY4MGRkMzk5NzQ3Y2Q4ZjhhMTYwZWNiYTZmNDYzNTRlNmI0ZDFjNzE0M2RkOWRjYzM1In0.eyJhdWQiOiIzMDM4MCIsImp0aSI6IjAwN2VjZjAzNGM3MTVkYmRjMTI1ZWIxNzA4YWNiMzY4MGRkMzk5NzQ3Y2Q4ZjhhMTYwZWNiYTZmNDYzNTRlNmI0ZDFjNzE0M2RkOWRjYzM1IiwiaWF0IjoxNzM2MjQ1MjYzLCJuYmYiOjE3MzYyNDUyNjMsImV4cCI6MTczODc1MDg2Mywic3ViIjoiIiwic2NvcGVzIjpbImJhc2ljIl19.JjWf4g8nNKq4NzgIcrps-K8TAQoS6P9_dA9SNL-b9H2Z4XFiAZQUT5V8tifr-utfsMUhZ0VAMfL1yKUJwDgYnanpKqWSRkolbpGYG3rE4vdatSY6gmt5s7YLPrhgaQY3r5S28cTjOxCH68SSmclekQDXhnUmnMBnP2708WCV2QsR3_-kqC6ElrYoZvRIU1RbFaeeP8PKhwcKGzxuwYm6Er_aJPI7lu040z4AtSY7m1ALPnm7TtZ00hbAA76srmqVROHQ4Tmh1fxGRfPOnRStXDxWzwMQ24mAeKAsjvaB9W7SAfbhfXCpF51NgMRJy695kA5JFsdoatVK7zxG9MT-rw";
    } else {
      tileUrl = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
    }
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
                : tileUrl,
            subdomains: const ['a', 'b', 'c'],
          ),
          CircleLayer(
              circles: widget.circles!
                  .map((circleModel) => circleModel.toFlutterCircleMarker())
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
        visible: widget.isCurrentLocationEnable ?? false,
        child: FloatingActionButton(
          onPressed: () {
            if (widget.userMarker != null) {
              _mapController.move(
                  LatLng(widget.userMarker!.latitude,
                      widget.userMarker!.longitude),
                  widget.zoom ?? 11);
            } else {
              //fixme show error message
            }
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
        markers: widget.markers!
            .map((markerModel) => markerModel.toFlutterMarker())
            .toList(),
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
