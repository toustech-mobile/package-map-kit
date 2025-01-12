import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/enums/map_provider.dart';
import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/models/poly_line_model.dart';
import 'package:map_kit/models/user_marker.dart';
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
      mapProvider: MapProvider.mapIr,
      controller: mapController,
      initialCenter: const LatLng(36.3156692, 59.5405541),
      isDarkMode: false,
      isCurrentLocationEnable: true,
      zoom: 12,
      markers: [
        MarkerModel(
            latitude: 36.3156692,
            longitude: 59.5405541,
            data: "Test Click On Marker",
            icon: 'pause.svg',
            snippetTitle: 'marker title',
            snippetDescription: 'marker description'),
        MarkerModel(
          latitude: 36.324915772569966,
          longitude: 59.54904346842852,
          data: "Test Click On Marker",
          icon: 'end_point.svg',
        ),
      ],
      polyLines: [
        PolyLineModel(points: [
          LatLng(36.3156692, 59.5405541),
          LatLng(36.315673, 59.5403954),
          LatLng(36.3156521, 59.5401282),
          LatLng(36.3156776, 59.5398778),
          LatLng(36.3157881, 59.5395753),
          LatLng(36.3159304, 59.539082),
          LatLng(36.3161398, 59.5384948),
          LatLng(36.3163329, 59.5379036),
          LatLng(36.3165588, 59.5372667),
        ], color: Colors.red, strokeWidth: 5),
        PolyLineModel(points: [
          LatLng(36.3167264, 59.5365894),
          LatLng(36.3169662, 59.5359136),
          LatLng(36.3172246, 59.5352273),
          LatLng(36.3174794, 59.5343151),
          LatLng(36.3177497, 59.5334306),
          LatLng(36.3179679, 59.5325732),
          LatLng(36.3182209, 59.5317401),
          LatLng(36.3184893, 59.5309729),
          LatLng(36.318721, 59.5302708),
          LatLng(36.3189011, 59.5296759),
          LatLng(36.3191815, 59.5289642),
        ], color: Colors.green, strokeWidth: 5, strokeColor: Colors.red),
        PolyLineModel(points: [
          LatLng(36.3196133, 59.5276296),
          LatLng(36.3198302, 59.5270538),
          LatLng(36.3200575, 59.5264617),
          LatLng(36.3203503, 59.5254298),
          LatLng(36.3205295, 59.5250031),
          LatLng(36.3208517, 59.5249409),
          LatLng(36.3213284, 59.5251547),
          LatLng(36.3218684, 59.5254108),
          LatLng(36.3229135, 59.5258929),
          LatLng(36.3230858, 59.525632),
          LatLng(36.3223972, 59.5251941),
          LatLng(36.3224258, 59.5248137),
          LatLng(36.3226065, 59.5243794),
          LatLng(36.3227928, 59.5240218),
          LatLng(36.3227517, 59.5238205),
          LatLng(36.3224315, 59.5237103),
        ], color: Colors.blue, strokeWidth: 5, strokeColor: Colors.red),
      ],
      circles: [
        CircleModel(
            latitude: 36.32209806699167,
            longitude: 59.52369428145562,
            radius: 700,
            color: Colors.blue.withOpacity(0.5),
            borderColor: Colors.blue,
            data: 'Man Circle Blue hastam',
            snippetTitle: 'circle Abi hastam',
            snippetDescription: 'man tozihat circle abi hastam'),
        CircleModel(
          latitude: 36.33377358253895,
          longitude: 59.54590011713316,
          radius: 500,
          color: Colors.deepOrange.withOpacity(0.5),
          borderColor: Colors.deepOrange,
          data: 'Man Circle Orange Hastam',
          // snippetTitle: 'asdsadsadasdsadsadaa',
          // snippetDescription: 'asfagasgasgasgasgasasgasg'
        ),
      ],
      onMarkerTap: (markerModel) {
        print("onMarkerTap: ${(markerModel as MarkerModel).data}");
      },
      onCircleTap: (circleMarkerModel) {
        print("onCircleTap: ${(circleMarkerModel as CircleModel).data}");
      },
      onTap: (LatLng point) {
        print('User tapped on: $point');
        // mapController.addMarker(
        //   MarkerModel(
        //     latitude: point.latitude,
        //     longitude: point.longitude,
        //     data: 123123213,
        //     child: const Icon(
        //       Icons.location_on,
        //       color: Colors.orange,
        //       size: 40,
        //     ),
        //   ),
        // );
      },
      onLongPress: (LatLng point) {
        mapController.addCircles([
          CircleModel(
              latitude: point.latitude,
              longitude: point.longitude,
              radius: 200,
              borderColor: Colors.purple,
              color: Colors.purple.withOpacity(.5),
              borderStroke: 2,
              data: "UserCircleData")
        ]);
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
        body: Stack(
          children: [
            Center(
              child: mapKitPlugin,
            ),
            ElevatedButton(
                onPressed: () {
                  mapController.setUserLocation(
                    UserMarkerModel(
                      latitude: 36.3219341,
                      longitude: 59.5214737,
                      accuracy: 100,
                    ),
                  );
                },
                child: Text('click'))
          ],
        ),
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () {
        //     mapController.moveCamera(MoveModel(point: const LatLng(36.3219744, 59.5381364), zoom: 14));
        //
        //     // mapController.addPolyline([
        //     //   PolyLineModel(points: [
        //     //     LatLng(36.3196133, 59.5276296),
        //     //     LatLng(36.3198302, 59.5270538),
        //     //     LatLng(36.3200575, 59.5264617),
        //     //     LatLng(36.3203503, 59.5254298),
        //     //     LatLng(36.3205295, 59.5250031),
        //     //     LatLng(36.3208517, 59.5249409),
        //     //     LatLng(36.3213284, 59.5251547),
        //     //     LatLng(36.3218684, 59.5254108),
        //     //     LatLng(36.3229135, 59.5258929),
        //     //     LatLng(36.3230858, 59.525632),
        //     //     LatLng(36.3223972, 59.5251941),
        //     //     LatLng(36.3224258, 59.5248137),
        //     //     LatLng(36.3226065, 59.5243794),
        //     //     LatLng(36.3227928, 59.5240218),
        //     //     LatLng(36.3227517, 59.5238205),
        //     //     LatLng(36.3224315, 59.5237103),
        //     //   ], color: Colors.purple, strokeWidth: 5),
        //     // ]);
        //
        //     // mapController.addMarker(
        //     //   MarkerModel(
        //     //     latitude: 36.5422255,
        //     //     longitude: 59.51455,
        //     //     child: const Icon(
        //     //       Icons.location_on,
        //     //       color: Colors.red,
        //     //       size: 40,
        //     //     ),
        //     //     data: 'test click',
        //     //   ),
        //     // );
        //   },
        //   child: const Icon(
        //     Icons.add_location,
        //     color: Colors.red,
        //   ),
        // ),
      ),
    );
  }
}
