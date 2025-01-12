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
  final PopupController popupController = PopupController();

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
  final Set<MarkerModel> _circleMarkers = {};

  @override
  void initState() {
    super.initState();

    if (widget.uiMapController != null) {
      widget.uiMapController!.addMarkers = (List<MarkerModel> markers) {
        widget.markers!.addAll(markers);
        setState(() {});
      };

      widget.uiMapController!.addCircles = (circles) {
        widget.circles!.addAll(circles);
        setState(() {});
      };

      widget.uiMapController!.addPolyline = (polyLines) {
        widget.polyLines!.addAll(polyLines);
        setState(() {});
      };

      widget.uiMapController!.moveCamera = (MoveModel moveModel) {
        _mapController.move(LatLng(moveModel.latitude, moveModel.longitude), moveModel.zoom!);
        setState(() {});
      };

      widget.uiMapController!.setUserLocation = (userMarker) {
        widget.userMarker = userMarker;
        setState(() {});
      };
    }

    _initializeHiddenMarkers();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mapProvider == MapProvider.mapIr) {
      tileUrl = "https://map.ir/shiveh/xyz/1.0.0/Shiveh:Shiveh@EPSG:3857@png/{z}/{x}/{y}.png"
          "?x-api-key=eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6IjAwN2VjZjAzNGM3MTVkYmRjMTI1ZWIxNzA4YWNiMzY4MGRkMzk5NzQ3Y2Q4ZjhhMTYwZWNiYTZmNDYzNTRlNmI0ZDFjNzE0M2RkOWRjYzM1In0.eyJhdWQiOiIzMDM4MCIsImp0aSI6IjAwN2VjZjAzNGM3MTVkYmRjMTI1ZWIxNzA4YWNiMzY4MGRkMzk5NzQ3Y2Q4ZjhhMTYwZWNiYTZmNDYzNTRlNmI0ZDFjNzE0M2RkOWRjYzM1IiwiaWF0IjoxNzM2MjQ1MjYzLCJuYmYiOjE3MzYyNDUyNjMsImV4cCI6MTczODc1MDg2Mywic3ViIjoiIiwic2NvcGVzIjpbImJhc2ljIl19.JjWf4g8nNKq4NzgIcrps-K8TAQoS6P9_dA9SNL-b9H2Z4XFiAZQUT5V8tifr-utfsMUhZ0VAMfL1yKUJwDgYnanpKqWSRkolbpGYG3rE4vdatSY6gmt5s7YLPrhgaQY3r5S28cTjOxCH68SSmclekQDXhnUmnMBnP2708WCV2QsR3_-kqC6ElrYoZvRIU1RbFaeeP8PKhwcKGzxuwYm6Er_aJPI7lu040z4AtSY7m1ALPnm7TtZ00hbAA76srmqVROHQ4Tmh1fxGRfPOnRStXDxWzwMQ24mAeKAsjvaB9W7SAfbhfXCpF51NgMRJy695kA5JFsdoatVK7zxG9MT-rw";
    } else {
      tileUrl = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
    }

    return Scaffold(
      body: _buildFlutterMap(),
      floatingActionButton: widget.isCurrentLocationEnable ?? false
          ? FloatingActionButton(
              onPressed: _moveToUserLocation,
              child: Icon(
                Icons.my_location,
                color: widget.userMarker != null ? Colors.blue : Colors.grey,
              ),
            )
          : null,
    );
  }

  Widget _buildFlutterMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
          initialCenter: widget.initialCenter!,
          initialZoom: widget.zoom ?? 13,
          onTap: _handleMapTap,
          onLongPress: _handleMapLongPress,
          onMapEvent: (MapEvent event) {
            widget.zoom = event.camera.zoom;
            if (event is MapEventMoveStart) {
              widget.popupController.hideAllPopups();
            }
          }),
      children: [
        TileLayer(
          urlTemplate:
              widget.isDarkMode ?? false ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png" : tileUrl,
          subdomains: const ['a', 'b', 'c'],
        ),
        PolylineLayer(
          polylines: [
            ...widget.polyLines!.map((polyLineModel) {
              final modifiedModel = polyLineModel.copyWith(
                color: polyLineModel.strokeColor ?? polyLineModel.color.withAlpha(100),
                strokeWidth: polyLineModel.strokeWidth! + 5,
              );
              return modifiedModel.toFlutterPolyLine();
            }),
            ...widget.polyLines!.map((polyLineModel) => polyLineModel.toFlutterPolyLine()),
          ],
        ),
        CircleLayer(
          circles: widget.circles!.map((circleModel) => circleModel.toFlutterCircleMarker()).toList(),
        ),
        _buildPopupMarkerLayer(),
        if (widget.userMarker != null) widget.userMarker!.toUserMarker(),
      ],
    );
  }

  void _initializeHiddenMarkers() {
    _circleMarkers.addAll(
      widget.circles!.map(
        (circle) => MarkerModel(
          latitude: circle.latitude,
          longitude: circle.longitude,
          data: '',
          icon: '',
          snippetTitle: circle.snippetTitle,
          snippetDescription: circle.snippetDescription,
        ),
      ),
    );
  }

  PopupMarkerLayer _buildPopupMarkerLayer() {
    final combinedMarkers = [
      ...?widget.markers,
      ..._circleMarkers,
    ];
    return PopupMarkerLayer(
      options: PopupMarkerLayerOptions(
        popupController: widget.popupController,
        markers: [
          ...widget.markers!.map((markerModel) => markerModel.toFlutterMarker()),
          ..._circleMarkers.map((markerModel) => markerModel.toFlutterMarker()),
        ],
        popupDisplayOptions: PopupDisplayOptions(
          builder: (BuildContext context, Marker marker) {
            final tappedMarker = combinedMarkers.firstWhere(
              (m) => m.latitude == marker.point.latitude && m.longitude == marker.point.longitude && m.icon.isNotEmpty,
              orElse: () {
                //fill hidden marker data
                final tappedMarker = combinedMarkers.firstWhere((m) =>
                    m.latitude == marker.point.latitude && m.longitude == marker.point.longitude && m.icon.isEmpty);
                return MarkerModel(
                    latitude: marker.point.latitude,
                    longitude: marker.point.longitude,
                    icon: '',
                    snippetTitle: tappedMarker.snippetTitle,
                    snippetDescription: tappedMarker.snippetDescription);
              },
            );

            if (tappedMarker.icon.isNotEmpty) {
              widget.onMarkerTap?.call(tappedMarker);
              return _buildPopupContent(tappedMarker);
            } else {
              final tappedCircle = widget.circles!.firstWhere(
                (c) => c.latitude == marker.point.latitude && c.longitude == marker.point.longitude,
              );
              widget.onCircleTap?.call(tappedCircle);
              return _buildPopupContent(tappedMarker);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPopupContent(MarkerModel marker) {
    return Visibility(
      visible: marker.snippetTitle != null || marker.snippetDescription != null,
      child: Container(
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
        child: Wrap(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (marker.snippetTitle != null) Text(marker.snippetTitle!),
                if (marker.snippetDescription != null) Text(marker.snippetDescription!),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    widget.popupController.hideAllPopups();
    final circle = widget.circles?.firstWhere(
      (circle) =>
          const Distance().as(LengthUnit.Meter, LatLng(circle.latitude, circle.longitude), point) <= circle.radius,
      orElse: () => CircleModel(latitude: 0, longitude: 0, radius: 0, color: Colors.red, borderColor: Colors.red),
    );
    if (circle!.longitude != 0) {
      widget.onCircleTap?.call(circle);
    } else {
      widget.onTap?.call(point);
    }
  }

  void _handleMapLongPress(TapPosition tapPosition, LatLng point) {
    widget.popupController.hideAllPopups();
    widget.onLongPress?.call(point);
  }

  void _moveToUserLocation() {
    if (widget.userMarker != null) {
      _mapController.move(LatLng(widget.userMarker!.latitude, widget.userMarker!.longitude), widget.zoom!);
    }
  }
}
