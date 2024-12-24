import 'package:latlong2/latlong.dart';
import 'package:map_kit/models/circle_marker_model.dart';
import 'package:map_kit/models/marker_model.dart';

mixin class UiMapController {
  late Function(MarkerModel) addMarker;
  late Function(CircleMarkerModel) addCircle;
  late Function(List<LatLng>) addPolyline;
}