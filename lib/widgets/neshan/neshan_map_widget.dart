import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/map_kit.dart';
import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/models/map_bounds_model.dart';
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
  bool? gpsEnabled;

  double? zoom;
  List<MarkerModel>? markers;
  List<PolyLineModel>? polyLines;
  List<CircleModel>? circles;
  UserMarkerModel? userMarker;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongPress;
  final void Function(dynamic)? onMarkerTap;
  final void Function(dynamic)? onCircleTap;
  final Future<void> Function()? onMyLocationClick;

  StreamSubscription<ServiceStatus>? _serviceStatusStream;

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
    this.onMyLocationClick,
  });

  @override
  State<NeshanMapWidget> createState() => _NeshanMapWidgetState();
}

class _NeshanMapWidgetState extends State<NeshanMapWidget> implements NeshanCallbackInterface {
  Size? _mapSize;

  @override
  void initState() {
    NeshanCallback.setNeshanCallback(this);
    print('NeshanCallback setNeshanCallback set');

    if (widget.uiMapController != null) {
      widget.uiMapController!.addMarkers = (List<MarkerModel> markers) {
        widget.markers!.addAll(markers);
        neshan.NeshanMethods.addMarkers(markers);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      };

      widget.uiMapController!.removeMarkers = (List<MarkerModel> markers) {
        neshan.NeshanMethods.removeMarkers(markers);
        for (var m in markers) {
          widget.markers!.remove(m);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      };

      widget.uiMapController!.removeAllMarkers = () {
        neshan.NeshanMethods.removeAllMarkers();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      };

      widget.uiMapController!.removeAllCircles = () {
        neshan.NeshanMethods.removeAllCircles();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      };

      widget.uiMapController!.addCircles = (List<CircleModel> circles) {
        widget.circles!.addAll(circles);
        neshan.NeshanMethods.addCircles(circles);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      };

      widget.uiMapController!.removeCircles = (List<CircleModel> circles) {
        neshan.NeshanMethods.removeCircles(circles);
        for (var c in circles) {
          widget.circles!.remove(c);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      };

      widget.uiMapController!.addPolyline = (List<PolyLineModel> polyLines) {
        widget.polyLines!.addAll(polyLines);
        neshan.NeshanMethods.addPolylines(polyLines);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      };

      widget.uiMapController!.setUserLocation = (UserMarkerModel userMarkerModel) {
        widget.userMarker = userMarkerModel;
        neshan.NeshanMethods.setUserMarker(userMarkerModel);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      };

      widget.uiMapController!.moveCamera = (MoveModel moveModel) {
        neshan.NeshanMethods.moveCamera(moveModel);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      };

      widget.uiMapController!.fitBounds = (MapBoundsModel mapBoundsModel) {
        final moveModel = _calculateMoveModelForBounds(mapBoundsModel);
        if (moveModel == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final retryMoveModel = _calculateMoveModelForBounds(mapBoundsModel);
            if (retryMoveModel == null) return;
            neshan.NeshanMethods.moveCamera(retryMoveModel);
            if (mounted) setState(() {});
          });
          return;
        }

        neshan.NeshanMethods.moveCamera(moveModel);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      };

      widget.uiMapController!.setDarkMode = (bool isDarkMode) {
        widget.isDarkMode = isDarkMode;
        neshan.NeshanMethods.setDarkMode(isDarkMode);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      };
    }

    listenGpsStatus();
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
    return LayoutBuilder(
      builder: (context, constraints) {
        _mapSize = Size(constraints.maxWidth, constraints.maxHeight);
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
                    color: widget.userMarker != null && (widget.gpsEnabled ?? false) ? Colors.blue : Colors.grey,
                  ),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  void _moveToUserLocation() async {
    await widget.onMyLocationClick?.call();
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

  MoveModel? _calculateMoveModelForBounds(MapBoundsModel mapBoundsModel) {
    if (mapBoundsModel.points.isEmpty) return null;
    if (mapBoundsModel.points.length == 1) {
      final point = mapBoundsModel.points.first;
      return MoveModel(
        latitude: point.latitude,
        longitude: point.longitude,
        zoom: widget.zoom ?? 15,
      );
    }

    final mapSize = _mapSize;
    if (mapSize == null || mapSize.width <= 0 || mapSize.height <= 0) {
      return null;
    }

    final lats = mapBoundsModel.points.map((p) => p.latitude);
    final lngs = mapBoundsModel.points.map((p) => p.longitude);

    final minLat = lats.reduce(math.min);
    final maxLat = lats.reduce(math.max);
    final minLng = lngs.reduce(math.min);
    final maxLng = lngs.reduce(math.max);

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    final horizontalPadding = (mapBoundsModel.padding * 2).clamp(0, mapSize.width - 1);
    final verticalPadding = (mapBoundsModel.padding * 2).clamp(0, mapSize.height - 1);
    final usableWidth = math.max(1.0, mapSize.width - horizontalPadding);
    final usableHeight = math.max(1.0, mapSize.height - verticalPadding);

    final latFraction = (_latRad(maxLat) - _latRad(minLat)).abs() / math.pi;
    final lngDiff = (maxLng - minLng).abs();
    final lngFraction = (lngDiff > 180 ? 360 - lngDiff : lngDiff) / 360;

    double zoom = widget.zoom ?? 15;
    const worldPx = 256.0;

    if (latFraction > 0 && lngFraction > 0) {
      final latZoom = math.log(usableHeight / worldPx / latFraction) / math.ln2;
      final lngZoom = math.log(usableWidth / worldPx / lngFraction) / math.ln2;
      zoom = math.min(latZoom, lngZoom);
    } else if (latFraction > 0) {
      zoom = math.log(usableHeight / worldPx / latFraction) / math.ln2;
    } else if (lngFraction > 0) {
      zoom = math.log(usableWidth / worldPx / lngFraction) / math.ln2;
    }

    return MoveModel(
      latitude: centerLat,
      longitude: centerLng,
      zoom: zoom.clamp(1, 20).toDouble(),
    );
  }

  double _latRad(double lat) {
    final sinValue = math.sin(lat * math.pi / 180);
    final radX2 = math.log((1 + sinValue) / (1 - sinValue)) / 2;
    return radX2.clamp(-math.pi, math.pi).toDouble();
  }

  void listenGpsStatus() {
    widget._serviceStatusStream = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      widget.gpsEnabled = status == ServiceStatus.enabled;
      setState(() {});
    });
  }

  @override
  void dispose() {
    widget._serviceStatusStream?.cancel();
    super.dispose();
  }
}
