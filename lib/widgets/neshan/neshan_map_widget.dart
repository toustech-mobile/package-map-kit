import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/map_kit.dart';
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

      widget.uiMapController!.setDarkMode = (bool isDarkMode) {
        widget.isDarkMode = isDarkMode;
        neshan.NeshanMethods.setDarkMode(isDarkMode);
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
        Platform.isIOS
            ? const MapKitView()
            : AndroidView(
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
          child: Positioned(
            right: 24,
            bottom: 24,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
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
