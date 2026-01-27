
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/enums/map_provider.dart';
import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/models/move_model.dart';
import 'package:map_kit/models/poly_line_model.dart';

import '../../models/user_marker.dart';

class FlutterMapWidget extends StatefulWidget {
  final PopupController popupController = PopupController();

  StreamSubscription<ServiceStatus>? _serviceStatusStream;

  UiMapController? uiMapController;
  List<MarkerModel>? markers;
  List<PolyLineModel>? polyLines;
  List<CircleModel>? circles;
  UserMarkerModel? userMarker;
  LatLng? initialCenter;
  bool? isDarkMode;
  bool? isCurrentLocationEnable;
  bool? gpsEnabled;
  double? zoom;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongPress;
  final void Function(MarkerModel)? onMarkerTap;
  final void Function(CircleModel)? onCircleTap;
  final Future<void> Function()? onMyLocationClick;

  MapProvider? mapProvider;

  FlutterMapWidget({
    this.uiMapController,
    this.markers,
    this.polyLines,
    this.circles,
    this.initialCenter,
    this.isDarkMode,
    this.isCurrentLocationEnable,
    this.zoom,
    this.onTap,
    this.onLongPress,
    this.onMarkerTap,
    this.onCircleTap,
    this.onMyLocationClick,
    this.mapProvider,
  });

  @override
  State<FlutterMapWidget> createState() => _FlutterMapWidgetState();
}

class _FlutterMapWidgetState extends State<FlutterMapWidget> {
  final MapController _mapController = MapController();
  String tileUrl = '';
  final Set<MarkerModel> _circleMarkers = {};
  MarkerModel? _lastTappedMarker;
  bool _popupVisible = false;

  @override
  void initState() {
    super.initState();

    if (widget.uiMapController != null) {
      widget.uiMapController!.addMarkers = (List<MarkerModel> markers) {
        // defer update until after current frame
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.markers!.addAll(markers);
          setState(() {});
        });
      };

      widget.uiMapController!.addCircles = (List<CircleModel> circles) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.circles!.addAll(circles);
          // also add new hidden markers for the new circles
          _circleMarkers.addAll(circles.map((circle) => MarkerModel(
                latitude: circle.latitude,
                longitude: circle.longitude,
                data: '',
                icon: '',
                snippetTitle: circle.snippetTitle,
                snippetDescription: circle.snippetDescription,
              )));
          setState(() {});
        });
      };

      widget.uiMapController!.addPolyline = (List<PolyLineModel> polyLines) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.polyLines!.addAll(polyLines);
          setState(() {});
        });
      };

      widget.uiMapController!.moveCamera = (MoveModel moveModel) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mapController.move(LatLng(moveModel.latitude, moveModel.longitude), moveModel.zoom!);
          setState(() {});
        });
      };

      widget.uiMapController!.setUserLocation = (userMarker) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.userMarker = userMarker;
          setState(() {});
        });
      };

      widget.uiMapController!.removeMarkers = (List<MarkerModel> markers) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.markers!.removeWhere((marker) => markers.contains(marker));
          setState(() {});
        });
      };

      widget.uiMapController!.removeCircles = (List<CircleModel> circles) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.circles!.removeWhere((circle) => circles.contains(circle));
          setState(() {});
        });
      };

      widget.uiMapController!.removeAllMarkers = () {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.markers!.removeRange(0, widget.markers!.length);
          setState(() {});
        });
      };

      widget.uiMapController!.removeAllCircles = () {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.circles!.clear();
          setState(() {});
        });
      };
    }

    _initializeHiddenMarkers();
    listenGpsStatus() ;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mapProvider == MapProvider.mapIr) {
      tileUrl = "https://map.ir/shiveh/xyz/1.0.0/Shiveh:Shiveh@EPSG:3857@png/{z}/{x}/{y}.png"
          "?x-api-key=eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6IjAwN2VjZjAzNGM3MTVkYmRjMTI1ZWIxNzA4YWNiMzY4MGRkMzk5NzQ3Y2Q4ZjhhMTYwZWNiYTZmNDYzNTRlNmI0ZDFjNzE0M2RkOWRjYzM1In0.eyJhdWQiOiIzMDM4MCIsImp0aSI6IjAwN2VjZjAzNGM3MTVkYmRjMTI1ZWIxNzA4YWNiMzY4MGRkMzk5NzQ3Y2Q4ZjhhMTYwZWNiYTZmNDYzNTRlNmI0ZDFjNzE0M2RkOWRjYzM1IiwiaWF0IjoxNzM2MjQ1MjYzLCJuYmYiOjE3MzYyNDUyNjMsImV4cCI6MTczODc1MDg2Mywic3ViIjoiIiwic2NvcGVzIjpbImJhc2ljIl19.JjWf4g8nNKq4NzgIcrps-K8TAQoS6P9_dA9SNL-b9H2Z4XFiAZQUT5V8tifr-utfsMUhZ0VAMfL1yKUJwDgYnanpKqWSRkolbpGYG3rE4vdatSY6gmt5s7YLPrhgaQY3r5S28cTjOxCH68SSmclekQDXhnUmnMBnP2708WCV2QsR3_-kqC6ElrYoZvRIU1RbFaeeP8PKhwcKGzxuwYm6Er_aJPI7lu040z4AtSY7m1ALPnm7TtZ00hbAA76srmqVROHQ4Tmh1fxGRfPOnRStXDxWzwMQ24mAeKAsjvaB9W7SAfbhfXCpF51NgMRJy695kA5JFsdoatVK7zxG9MT-rw";
    } else {
      tileUrl = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildFlutterMap(),
          if (widget.isCurrentLocationEnable ?? false)
            Positioned(
              right: 24,
              bottom: 24,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: _moveToUserLocation,
                child: Icon(
                  Icons.my_location,
                  color: widget.userMarker != null && (widget.gpsEnabled??false) ? Colors.blue : Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFlutterMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
          initialCenter: widget.initialCenter!,
          initialZoom: widget.zoom ?? 13,
          onTap: _handleMapTap,
          onLongPress: _handleMapLongPress,
          onMapEvent: (MapEvent event) {
            widget.zoom = event.camera.zoom;
            if (event is MapEventMoveStart) {
              widget.popupController.hideAllPopups();
              _lastTappedMarker = null;
              _popupVisible = false;
            }
          }),
      children: [
        TileLayer(
          urlTemplate:
              widget.isDarkMode ?? false ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png" : tileUrl,
          subdomains: const ['a', 'b', 'c'],
        ),
        PolylineLayer(
          polylines: [
            ...widget.polyLines!.map((polyLineModel) {
              final modifiedModel = polyLineModel.copyWith(
                color: polyLineModel.strokeColor ?? polyLineModel.color.withAlpha(100),
                strokeWidth: polyLineModel.strokeWidth! + 5,
              );
              return modifiedModel.toFlutterPolyLine();
            }),
            ...widget.polyLines!.map((polyLineModel) => polyLineModel.toFlutterPolyLine()),
          ],
        ),
        MarkerLayer(markers: _buildHeadingMarkers()),
        CircleLayer(
          circles: widget.circles!.map((circleModel) => circleModel.toFlutterCircleMarker()).toList(),
        ),
        _buildPopupMarkerLayer(),
        if (widget.userMarker != null) widget.userMarker!.toUserMarker(),
      ],
    );
  }

  void _initializeHiddenMarkers() {
    _circleMarkers.addAll(
      widget.circles!.map(
        (circle) => MarkerModel(
          latitude: circle.latitude,
          longitude: circle.longitude,
          data: '',
          icon: '',
          snippetTitle: circle.snippetTitle,
          snippetDescription: circle.snippetDescription,
        ),
      ),
    );
  }

  List<Marker> _buildHeadingMarkers() {
    final List<Marker> markers = [];

    for (final polyLine in widget.polyLines!) {
      if (polyLine.points != null && polyLine.showArrow == true) {
        for (final point in polyLine.points!) {
          markers.add(
            Marker(
              point: LatLng(point.latitude, point.longitude),
              width: 16,
              height: 16,
              child: Transform.rotate(
                angle: point.heading * (3.14159265359 / 180.0),
                child: SvgPicture.asset(
                  'assets/icons/arrow.svg',
                ),
              ),
            ),
          );
        }
      }
    }
    return markers;
  }

  PopupMarkerLayer _buildPopupMarkerLayer() {
    final combinedMarkers = [
      ...?widget.markers,
      ..._circleMarkers,
    ];
    return PopupMarkerLayer(
      options: PopupMarkerLayerOptions(
        popupController: widget.popupController,
        markers: [
          ...widget.markers!.map((markerModel) => markerModel.toFlutterMarker()),
          ..._circleMarkers.map((markerModel) => markerModel.toFlutterMarker()),
        ],
        popupDisplayOptions: PopupDisplayOptions(
          builder: (BuildContext context, Marker marker) {
            final tappedMarker = combinedMarkers.firstWhere(
              (m) => m.latitude == marker.point.latitude && m.longitude == marker.point.longitude && m.icon.isNotEmpty,
              orElse: () {
                final tappedMarker = combinedMarkers.firstWhere((m) =>
                    m.latitude == marker.point.latitude && m.longitude == marker.point.longitude && m.icon.isEmpty);
                return MarkerModel(
                    latitude: marker.point.latitude,
                    longitude: marker.point.longitude,
                    icon: '',
                    snippetTitle: tappedMarker.snippetTitle,
                    snippetDescription: tappedMarker.snippetDescription);
              },
            );

            if (!_popupVisible ||
                _lastTappedMarker == null ||
                _lastTappedMarker!.latitude != tappedMarker.latitude ||
                _lastTappedMarker!.longitude != tappedMarker.longitude) {
              if (tappedMarker.icon.isNotEmpty) {
                widget.onMarkerTap?.call(tappedMarker);
              } else {
                final tappedCircle = widget.circles!.firstWhere(
                  (c) => c.latitude == marker.point.latitude && c.longitude == marker.point.longitude,
                );
                widget.onCircleTap?.call(tappedCircle);
              }
              _lastTappedMarker = tappedMarker;
              _popupVisible = true;
            }

            return _buildPopupContent(tappedMarker);
          },
        ),
      ),
    );
  }

  Widget _buildPopupContent(MarkerModel marker) {
    return Visibility(
      visible: marker.snippetTitle != null || marker.snippetDescription != null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Wrap(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (marker.snippetTitle != null) Text(marker.snippetTitle!),
                if (marker.snippetDescription != null) Text(marker.snippetDescription!),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    widget.popupController.hideAllPopups();
    _lastTappedMarker = null;
    _popupVisible = false;

    final circle = widget.circles?.firstWhere(
      (circle) =>
          const Distance().as(
            LengthUnit.Meter,
            LatLng(circle.latitude, circle.longitude),
            point,
          ) <=
          circle.radius,
      orElse: () => CircleModel(
        latitude: 0,
        longitude: 0,
        radius: 0,
        color: Colors.red,
        borderColor: Colors.red,
      ),
    );

    if (circle != null && circle.longitude != 0) {
      widget.onCircleTap?.call(circle);
      widget.onTap?.call(point);
    } else {
      widget.onTap?.call(point);
    }
  }

  void _handleMapLongPress(TapPosition tapPosition, LatLng point) {
    widget.popupController.hideAllPopups();
    _lastTappedMarker = null;
    _popupVisible = false;
    widget.onLongPress?.call(point);
  }

  void _moveToUserLocation() async{
    await widget.onMyLocationClick?.call();
    if (widget.userMarker != null) {
      _mapController.move(LatLng(widget.userMarker!.latitude, widget.userMarker!.longitude), widget.zoom!);
    }
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
