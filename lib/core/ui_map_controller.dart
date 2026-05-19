import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/models/map_bounds_model.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/models/move_model.dart';
import 'package:map_kit/models/poly_line_model.dart';
import 'package:map_kit/models/user_marker.dart';

mixin class UiMapController {
  late Function(List<MarkerModel>) addMarkers;
  late Function(List<MarkerModel>) removeMarkers;
  late Function() removeAllMarkers;
  late Function() removeAllCircles;
  late Function(List<CircleModel>) addCircles;
  late Function(List<CircleModel>) removeCircles;
  late Function(List<PolyLineModel>) addPolyline;
  late Function(List<PolyLineModel>) removePolyLines;
  late Function() removeAllPolyLines;
  late Function(MoveModel) moveCamera;
  late Function(MapBoundsModel) fitBounds;
  Function(UserMarkerModel)? setUserLocation;
  late Function(bool) setDarkMode;
}
