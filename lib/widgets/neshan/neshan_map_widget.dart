import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/models/poly_line_model.dart';
import 'package:map_kit/models/user_marker.dart';
import 'package:map_kit/widgets/neshan/neshan_callback.dart';
import 'package:map_kit/widgets/neshan/neshan_methods.dart';
import 'package:map_kit/widgets/neshan/neshan_marker_codec.dart';
import 'package:map_kit/widgets/neshan/neshan_ios_renderer.dart';

class NeshanMapWidget extends StatefulWidget {
  late Map<String, dynamic> creationParams;
  UiMapController? uiMapController;
  LatLng? initialCenter;
  bool? isDarkMode;
  bool? gpsEnabled;
  double? zoom;
  List<MarkerModel>? markers;
  List<PolyLineModel>? polyLines;
  List<CircleModel>? circles;
  UserMarkerModel? userMarker;
  final void Function(LatLng point)? onTap;
  final void Function(LatLng point)? onLongPress;
  final void Function(dynamic data, LatLng point)? onMarkerTap;
  final void Function(dynamic data, LatLng? point)? onCircleTap;
  final void Function(dynamic data, LatLng? point)? onPolylineTap;

  NeshanMapWidget({
    super.key,
    this.uiMapController,
    this.initialCenter,
    this.isDarkMode,
    this.zoom,
    this.markers,
    this.polyLines,
    this.circles,
    this.onTap,
    this.onLongPress,
    this.onMarkerTap,
    this.onCircleTap,
    this.onPolylineTap,
  });

  @override
  State<NeshanMapWidget> createState() => _NeshanMapWidgetState();
}

class _NeshanMapWidgetState extends State<NeshanMapWidget>
    implements NeshanCallbackInterface {
  StreamSubscription<dynamic>? _subscription;
  Future<Map<String, dynamic>>? _iosCreationParams;

  @override
  void initState() {
    super.initState();
    widget.initialCenter ??= const LatLng(35.6892, 51.3890);
    widget.markers ??= [];
    widget.circles ??= [];
    widget.polyLines ??= [];
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      _iosCreationParams = _prepareIosParams();
    } else {
      _subscription = NeshanCallback.setNeshanCallback(this);
    }

    final controller = widget.uiMapController;
    if (controller == null) return;
    controller.addMarkers = (markers) async {
      await NeshanMethods.addMarkers(markers);
      if (mounted) widget.markers!.addAll(markers);
    };
    controller.removeMarkers = (markers) async {
      await NeshanMethods.removeMarkers(markers);
      if (mounted) widget.markers!.removeWhere(markers.contains);
    };
    controller.removeAllMarkers = () async {
      await NeshanMethods.removeAllMarkers();
      if (mounted) widget.markers!.clear();
    };
    controller.addCircles = (circles) async {
      await NeshanMethods.addCircles(circles);
      if (mounted) widget.circles!.addAll(circles);
    };
    controller.removeCircles = (circles) async {
      await NeshanMethods.removeCircles(circles);
      if (mounted) widget.circles!.removeWhere(circles.contains);
    };
    controller.removeAllCircles = () async {
      await NeshanMethods.removeAllCircles();
      if (mounted) widget.circles!.clear();
    };
    controller.addPolyline = (lines) async {
      await NeshanMethods.addPolylines(lines);
      if (mounted) widget.polyLines!.addAll(lines);
    };
    controller.removePolyLines = (lines) async {
      await NeshanMethods.removePolyLines(lines);
      if (mounted) widget.polyLines!.removeWhere(lines.contains);
    };
    controller.removeAllPolyLines = () async {
      await NeshanMethods.removeAllPolyLines();
      if (mounted) widget.polyLines!.clear();
    };
    controller.cameraCallback = NeshanMethods.getCamera;
    controller.setUserLocation = (user) async {
      await NeshanMethods.setUserMarker(user);
      if (mounted) widget.userMarker = user;
    };
    controller.moveCamera = NeshanMethods.moveCamera;
    controller.fitBounds = NeshanMethods.fitBounds;
    controller.setDarkMode = (dark) async {
      await NeshanMethods.setDarkMode(dark);
      if (mounted) widget.isDarkMode = dark;
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return FutureBuilder<Map<String, dynamic>>(
        future: _iosCreationParams,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorWidget(snapshot.error!);
          if (!snapshot.hasData) return const SizedBox.expand();
          return UiKitView(
            viewType: NeshanIosRenderer.viewType,
            creationParams: snapshot.data,
            creationParamsCodec: const StandardMessageCodec(),
            gestureRecognizers: const {
              Factory<OneSequenceGestureRecognizer>(PanGestureRecognizer.new),
            },
            layoutDirection: TextDirection.ltr,
          );
        },
      );
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('Native Neshan maps support Android and iOS.');
    }
    return AndroidView(
      viewType: 'com.example.example/map_kit_view',
      creationParams: _creationParams(),
      creationParamsCodec: const StandardMessageCodec(),
      gestureRecognizers: const {
        Factory<OneSequenceGestureRecognizer>(PanGestureRecognizer.new),
      },
      layoutDirection: TextDirection.ltr,
    );
  }

  Future<Map<String, dynamic>> _prepareIosParams() async {
    final params = _creationParams();
    await NeshanIosRenderer.ensureAvailable();
    if (mounted) _subscription = NeshanCallback.setNeshanCallback(this);
    params['markers'] = await NeshanMarkerCodec.encode(widget.markers!);
    return params;
  }

  Map<String, dynamic> _creationParams() {
    final center = widget.initialCenter ?? const LatLng(35.6892, 51.3890);
    widget.markers ??= [];
    widget.circles ??= [];
    widget.polyLines ??= [];
    widget.creationParams = {
      'initialCenter': {
        'latitude': center.latitude,
        'longitude': center.longitude,
      },
      'isDarkMode': widget.isDarkMode ?? false,
      'zoom': widget.zoom,
      'markers':
          widget.markers!.map((model) => model.toNeshanMarker()).toList(),
      'polyLines':
          widget.polyLines!.map((model) => model.toNeshanPolyLines()).toList(),
      'circles':
          widget.circles!.map((model) => model.toNeshanCircle()).toList(),
    };
    return widget.creationParams;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void onMapTap(LatLng point) => widget.onTap?.call(point);
  @override
  void onMapLongPress(LatLng point) => widget.onLongPress?.call(point);
  @override
  void onMarkerTap(dynamic data, LatLng point) =>
      widget.onMarkerTap?.call(data, point);
  @override
  void onCircleTap(dynamic data, LatLng? point) =>
      widget.onCircleTap?.call(data, point);
  @override
  void onPolylineTap(dynamic data, LatLng? point) =>
      widget.onPolylineTap?.call(data, point);
}
