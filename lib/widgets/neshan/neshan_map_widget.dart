import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/models/move_model.dart';
import 'package:map_kit/models/poly_line_model.dart';
import 'package:map_kit/models/user_marker.dart';
import 'package:map_kit/widgets/neshan/neshan_callback.dart';
import 'package:map_kit/widgets/neshan/neshan_methods.dart' as neshan;

class NeshanMapWidget extends StatefulWidget {
  late Map<String, dynamic> creationParams;
  UiMapController? uiMapController;
  LatLng? initialCenter;
  bool? isDarkMode;
  bool? isCurrentLocationEnable;
  double? zoom;
  List<MarkerModel>? markers;
  List<PolyLineModel>? polyLines;
  List<CircleModel>? circles;
  UserMarkerModel? userMarker;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongPress;
  final void Function(dynamic)? onMarkerTap;
  final void Function(dynamic)? onCircleTap;

  NeshanMapWidget({
    super.key,
    this.uiMapController,
    this.initialCenter,
    this.isDarkMode,
    this.isCurrentLocationEnable,
    this.zoom,
    this.markers,
    this.polyLines,
    this.circles,
    this.onTap,
    this.onLongPress,
    this.onMarkerTap,
    this.onCircleTap,
  });

  @override
  State<NeshanMapWidget> createState() => _NeshanMapWidgetState();
}

class _NeshanMapWidgetState extends State<NeshanMapWidget> implements NeshanCallbackInterface {
  @override
  void initState() {
    NeshanCallback.setNeshanCallback(this);
    print('NeshanCallback setNeshanCallback set');
    if (widget.uiMapController != null) {
      widget.uiMapController!.addMarkers = (List<MarkerModel> markers) {
        widget.markers!.addAll(markers);
        neshan.NeshanMethods.addMarkers(markers);
      };

      widget.uiMapController!.removeMarkers = (List<MarkerModel> markers) {
        neshan.NeshanMethods.removeMarkers(markers);
        for (var m in markers) {
          widget.markers!.remove(m);
        }
      };

      widget.uiMapController!.addCircles = (List<CircleModel> circles) {
        widget.circles!.addAll(circles);
        neshan.NeshanMethods.addCircles(circles);
      };

      widget.uiMapController!.removeCircles = (List<CircleModel> circles) {
        neshan.NeshanMethods.removeCircles(circles);
        for (var c in circles) {
          widget.circles!.remove(c);
        }
      };

      widget.uiMapController!.addPolyline = (List<PolyLineModel> polyLines) {
        widget.polyLines!.addAll(polyLines);
        neshan.NeshanMethods.addPolylines(polyLines);
      };

      widget.uiMapController!.setUserLocation = (UserMarkerModel userMarkerModel) {
        widget.userMarker = userMarkerModel;
        neshan.NeshanMethods.setUserMarker(userMarkerModel);

        setState(() {});
      };
    }

    super.initState();
  }

  void setCreationParams() {
    widget.creationParams = <String, dynamic>{
      'initialCenter': {
        'latitude': widget.initialCenter!.latitude,
        'longitude': widget.initialCenter!.longitude,
      },
      'isDarkMode': widget.isDarkMode ?? false,
      'zoom': widget.zoom,
      'markers': widget.markers!.map((flutterModel) => flutterModel.toNeshanMarker()).toList(),
      'polyLines': widget.polyLines!.map((flutterModel) => flutterModel.toNeshanPolyLines()).toList(),
      'circles': widget.circles!.map((flutterModel) => flutterModel.toNeshanCircle()).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    setCreationParams();
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        AndroidView(
            viewType: 'com.example.example/map_kit_view',
            creationParams: widget.creationParams,
            creationParamsCodec: const StandardMessageCodec(),
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            layoutDirection: TextDirection.ltr,
            onPlatformViewCreated: (int id) {
              print('the PlatfromId is : $id');
            }),
        Visibility(
          visible: widget.isCurrentLocationEnable ?? false,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton(
              onPressed: _moveToUserLocation,
              child: Icon(
                Icons.my_location,
                color: widget.userMarker != null ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        )
      ],
    );
  }

  void _moveToUserLocation() {
    if (widget.userMarker != null) {
      neshan.NeshanMethods.moveCamera(
          MoveModel(latitude: widget.userMarker!.latitude, longitude: widget.userMarker!.longitude));
    }
  }

  @override
  void onMapTap(LatLng point) {
    if (widget.onTap != null) {
      widget.onTap!(point);
    }

    if (widget.uiMapController != null) {
      widget.uiMapController!.addPolyline([
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
        ], color: Colors.green, strokeWidth: 5),
      ]);

      widget.uiMapController!.setUserLocation(UserMarkerModel(
        latitude: 36.3212712247589,
        longitude: 59.590460127376986,
        accuracy: 2500,
      ));
    }
  }

  @override
  void onMapLongPress(LatLng point) {
    if (widget.onLongPress != null) {
      widget.onLongPress!(point);
    }
  }

  @override
  void onMarkerTap(data) {
    if (widget.onMarkerTap != null) {
      widget.onMarkerTap!(data);
    }
  }

  @override
  void onCircleTap(data) {
    if (widget.onCircleTap != null) {
      widget.onCircleTap!(data);
    }
  }
}
