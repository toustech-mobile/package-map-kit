
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/enums/map_provider.dart';
import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/models/poly_line_model.dart';
import 'package:map_kit/widgets/flutter/flutter_map_widget.dart';
import 'package:map_kit/widgets/neshan/neshan_map_widget.dart';

class UiMap extends StatefulWidget {
  final MapProvider mapProvider;
  final UiMapController? controller;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongPress;
  final void Function(dynamic)? onMarkerTap;
  final void Function(dynamic)? onCircleTap;
  final Future<void> Function()? onMyLocationClick;
  final void Function(dynamic data)? onPolylineTap;

  LatLng? initialCenter;
  bool? isDarkMode;
  double? zoom;
  bool? isCurrentLocationEnable;
  List<MarkerModel>? markers;
  List<CircleModel>? circles;
  List<PolyLineModel>? polyLines;

  UiMap({
    super.key,
    required this.mapProvider,
    this.controller,
    this.onTap,
    this.onLongPress,
    this.onMarkerTap,
    this.onCircleTap,
    this.onMyLocationClick,
    this.initialCenter,
    this.isDarkMode,
    this.zoom,
    this.isCurrentLocationEnable,
    List<MarkerModel>? markers,
    List<CircleModel>? circles,
    List<PolyLineModel>? polyLines,
    this.onPolylineTap
  }) {
    this.markers = markers ?? [];
    this.circles = circles ?? [];
    this.polyLines = polyLines ?? [];
  }

  @override
  _UiMapState createState() => _UiMapState();
}

class _UiMapState extends State<UiMap> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _loadMap());
  }

  _loadMap() {
    switch (widget.mapProvider) {
      case MapProvider.flutter:
        return FlutterMapWidget(
          uiMapController: widget.controller,
          initialCenter: widget.initialCenter,
          zoom: widget.zoom,
          isCurrentLocationEnable: widget.isCurrentLocationEnable,
          isDarkMode: widget.isDarkMode,
          markers: widget.markers,
          polyLines: widget.polyLines,
          circles: widget.circles,
          onMarkerTap: widget.onMarkerTap,
          onCircleTap: widget.onCircleTap,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          mapProvider: MapProvider.flutter,
          onMyLocationClick: widget.onMyLocationClick,
          onPolylineTap: widget.onPolylineTap,
        );
      case MapProvider.mapIr:
        return FlutterMapWidget(
          uiMapController: widget.controller,
          initialCenter: widget.initialCenter,
          zoom: widget.zoom,
          isCurrentLocationEnable: widget.isCurrentLocationEnable,
          isDarkMode: widget.isDarkMode,
          markers: widget.markers,
          polyLines: widget.polyLines,
          circles: widget.circles,
          onMarkerTap: widget.onMarkerTap,
          onCircleTap: widget.onCircleTap,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onMyLocationClick: widget.onMyLocationClick,
          mapProvider: MapProvider.mapIr,
          onPolylineTap: widget.onPolylineTap,
        );

      case MapProvider.neshan:
        return NeshanMapWidget(
          uiMapController: widget.controller,
          initialCenter: widget.initialCenter,
          zoom: widget.zoom,
          isDarkMode: widget.isDarkMode,
          isCurrentLocationEnable: widget.isCurrentLocationEnable,
          markers: widget.markers,
          polyLines: widget.polyLines,
          circles: widget.circles,
          onMarkerTap: widget.onMarkerTap,
          onCircleTap: widget.onCircleTap,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onMyLocationClick: widget.onMyLocationClick,
          onPolylineTap: widget.onPolylineTap,
        );
    }
  }
}
