import 'package:map_kit/models/circle_marker_model.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/models/move_model.dart';
import 'package:map_kit/models/poly_line_model.dart';
import 'package:map_kit/models/user_marker.dart';

mixin class UiMapController {
  late Function(MarkerModel) addMarker;
  late Function(CircleMarkerModel) addCircle;
  late Function(List<PolyLineModel>) addPolyline;
  late Function(MoveModel) moveCamera;
  late Function(UserMarkerModel) setUserLocation;
}
