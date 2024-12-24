import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/enums/map_provider.dart';
import 'package:map_kit/models/circle_marker_model.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/ui_map.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final UiMap mapKitPlugin;
  final UiMapController mapController = UiMapController();

  @override
  void initState() {
    super.initState();
    mapKitPlugin = UiMap(
      mapProvider: MapProvider.flutter,
      controller: mapController,
      initialCenter: LatLng(36.54665465, 59.564654),
      isDarkMode: false,
      zoom: 12,
      markers: [
        MarkerModel(
          latitude: 36.54665465,
          longitude: 59.564654,
          data: "Test Click On Marker",
          child: const Icon(
            Icons.location_on,
            color: Colors.blue,
            size: 40,
          ),
        )
      ],
      circles: [
        CircleMarkerModel(
            latitude: 36.54665465,
            longitude: 59.564654,
            radius: 200,
            color: Colors.deepOrange.withOpacity(0.5),
            borderColor: Colors.deepOrange,
            data: 'Circle data 22222'),
      ],
      onMarkerTap: (markerModel) {
        print(markerModel.data);
      },
      onCircleTap: (circleMarkerModel) {
        print("onCircleTap: ${circleMarkerModel.data}");
      },
      onTap: (LatLng point) {
        print('User tapped on: $point');
        mapController.addMarker(MarkerModel(
            latitude: point.latitude,
            longitude: point.longitude,
            data: 123123213,
            child: Icon(
              Icons.location_on,
              color: Colors.orange,
              size: 40,
            )));
      },
      onLongPress: (LatLng point) {
        mapController.addCircle(CircleMarkerModel(
            latitude: point.latitude,
            longitude: point.longitude,
            radius: 100,
            borderColor: Colors.purple,
            color: Colors.purple.withOpacity(.5),
            borderStroke: 2,
            data: "UserCircleData"));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: mapKitPlugin,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            mapController.addMarker(
              MarkerModel(
                latitude: 36.5422255,
                longitude: 59.51455,
                child: Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
                data: 'test click',
              ),
            );
          },
          child: const Icon(
            Icons.add_location,
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}
