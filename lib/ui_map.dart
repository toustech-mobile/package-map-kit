import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/enums/map_provider.dart';
import 'package:map_kit/models/circle_marker_model.dart';
import 'package:map_kit/models/marker_model.dart';
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
  List<MarkerModel>? markers;
  List<CircleMarkerModel>? circles;
  List<Polyline>? polyLines;

  UiMap({
    required this.mapProvider,
    this.controller,
    this.onTap,
    this.onLongPress,
    this.onMarkerTap,
    this.onCircleTap,
    this.initialCenter,
    this.isDarkMode,
    this.zoom,
    List<MarkerModel>? markers,
    List<CircleMarkerModel>? circles,
    List<Polyline>? polyLines,
  }) {
    this.markers = markers ?? [];
    this.circles = circles ?? [];
    this.polyLines = polyLines ?? [];
  }

  @override
  _UiMapState createState() => _UiMapState();
}

class _UiMapState extends State<UiMap> {
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _getUserLocation();

    // widget.controller!.initialize(
    //   addMarkerCallback: addMarker,
    //   addPolygonCallback: addPolygon,
    //   addPolylineCallback: addPolyline,
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.mapProvider == MapProvider.flutter
          ? FlutterMapWidget(
              uiMapController: widget.controller,
              initialCenter: widget.initialCenter,
              isDarkMode: widget.isDarkMode,
              zoom: widget.zoom,
              markers: widget.markers!
                  .map((markerModel) =>
                      markerModel.toFlutterMarker(widget.onMarkerTap))
                  .toList(),
              circles: widget.circles,
              onMarkerTap: widget.onMarkerTap,
              onCircleTap: widget.onCircleTap,
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
            )
          : _buildNeshanMap(),
    );
  }

  Future<void> _getUserLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    final locData = await location.getLocation();
    setState(() {
      _currentLocation = LatLng(locData.latitude!, locData.longitude!);
    });
    // _mapController.move(_currentLocation!, 15);
  }

  Widget _buildNeshanMap() {
    return Center(
      child: Text(
        "Neshan Map is not implemented yet.",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

//
//
// void addPolyline(List<LatLng> points) {
//   setState(() {
//     widget.polyLines!.add(Polyline(
//       points: points,
//       color: Colors.green,
//       strokeWidth: 4,
//     ));
//   });
// }
}
