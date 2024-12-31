import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/widgets/neshan/neshan_callback.dart';
import 'package:map_kit/widgets/neshan/neshan_methods.dart' as neshan;

class NeshanMapWidget extends StatefulWidget {
  UiMapController? uiMapController;
  LatLng? initialCenter;
  bool? isDarkMode;
  List<MarkerModel>? markers;

  NeshanMapWidget({
    super.key,
    this.uiMapController,
    this.initialCenter,
    this.isDarkMode,
    this.markers,
  });

  @override
  State<NeshanMapWidget> createState() => _NeshanMapWidgetState();
}

class _NeshanMapWidgetState extends State<NeshanMapWidget> implements NeshanCallbackInterface {
  @override
  void initState() {
    NeshanCallback.setNeshanCallback(this);

    if (widget.uiMapController != null) {
      widget.uiMapController!.addMarker = (MarkerModel marker) {
        widget.markers!.add(marker);
        neshan.NeshanMethods.addMarker(MarkerModel(
          latitude: marker.latitude,
          longitude: marker.longitude,
          data: 'marker Added Neshan Click',
          child: Container(),
        ));
      };
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AndroidView(
        viewType: 'com.golrang.map_kit/map_kit_view',
        creationParams: <String, dynamic>{
          'initialCenter': {
            'latitude': widget.initialCenter!.latitude,
            'longitude': widget.initialCenter!.longitude,
          },
          'isDarkMode': widget.isDarkMode,
          'markers': widget.markers!.map((flutterModel) => flutterModel.toNeshanMarker()).toList(),
        },
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        layoutDirection: TextDirection.ltr,
        onPlatformViewCreated: (int id) {
          print('the PlatfromId is : $id');
        });
  }

  @override
  void onMapTap(LatLng point) {
    if (widget.uiMapController != null) {
      widget.uiMapController!.addMarker(MarkerModel(
        latitude: point.latitude,
        longitude: point.longitude,
        child: Container(),
      ));
    }
  }

  @override
  void onMarkerTap(data) {
    print('onMarkerTap :$data');
  }
}
