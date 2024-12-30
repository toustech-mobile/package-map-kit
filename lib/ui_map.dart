import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/enums/map_provider.dart';
import 'package:map_kit/models/circle_marker_model.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/models/poly_line_model.dart';
import 'package:map_kit/widgets/flutter_map_widget.dart';

class UiMap extends StatefulWidget {
  final MapProvider mapProvider;
  final UiMapController? controller;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongPress;
  final void Function(MarkerModel)? onMarkerTap;
  final void Function(CircleMarkerModel)? onCircleTap;
  LatLng? initialCenter;
  bool? isDarkMode;
  double? zoom;
  bool? isCurrentLocationEnable;
  List<MarkerModel>? markers;
  List<CircleMarkerModel>? circles;
  List<PolyLineModel>? polyLines;

  UiMap({
    super.key,
    required this.mapProvider,
    this.controller,
    this.onTap,
    this.onLongPress,
    this.onMarkerTap,
    this.onCircleTap,
    this.initialCenter,
    this.isDarkMode,
    this.zoom,
    this.isCurrentLocationEnable,
    List<MarkerModel>? markers,
    List<CircleMarkerModel>? circles,
    List<PolyLineModel>? polyLines,
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
    return Scaffold(
      body: widget.mapProvider == MapProvider.flutter
          ? FlutterMapWidget(
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
            )
          : _buildNeshanMap(),
    );
  }

  Widget _buildNeshanMap() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          MyPlugin.openActivity();
        },
        child: Text('Open Native Activity'),
      ),
    );
  }
}

class MyPlugin {
  static const MethodChannel _channel = MethodChannel('com.golrang.map_kit/map_kit');

  static Future<void> openActivity() async {
    await _channel.invokeMethod('openActivity');
  }
}
