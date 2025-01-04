import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/models/poly_line_model.dart';
import 'package:map_kit/widgets/neshan/neshan_callback.dart';
import 'package:map_kit/widgets/neshan/neshan_methods.dart' as neshan;

class NeshanMapWidget extends StatefulWidget {
  GlobalKey globalKey = GlobalKey();
  UiMapController? uiMapController;
  LatLng? initialCenter;
  bool? isDarkMode;
  double? zoom;
  List<MarkerModel>? markers;
  List<PolyLineModel>? polyLines;
  List<CircleModel>? circles;

  NeshanMapWidget({
    super.key,
    this.uiMapController,
    this.initialCenter,
    this.isDarkMode,
    this.zoom,
    this.markers,
    this.polyLines,
    this.circles,
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
          icon: '',
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
          'zoom': widget.zoom,
          'markers': widget.markers!.map((flutterModel) => flutterModel.toNeshanMarker()).toList(),
          'polyLines': widget.polyLines!.map((flutterModel) => flutterModel.toNeshanPolyLines()).toList(),
          'circles': widget.circles!.map((flutterModel) => flutterModel.toNeshanCircle()).toList(),
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
        icon:'',
      ));
    }
  }

  @override
  void onMarkerTap(data) {
    print('onMarkerTap :$data');
  }
}
