import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/models/move_model.dart';
import 'package:map_kit/models/poly_line_model.dart';
import 'package:map_kit/models/user_marker.dart';

mixin class UiMapController {
  late Function(List<MarkerModel>) addMarkers;
  late Function(List<MarkerModel>) removeMarkers;
  late Function(CircleModel) addCircle;
  late Function(List<PolyLineModel>) addPolyline;
  late Function(MoveModel) moveCamera;
  late Function(UserMarkerModel) setUserLocation;
}
