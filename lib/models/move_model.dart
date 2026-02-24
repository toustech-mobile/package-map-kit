

class MoveModel {
  double latitude;
  double longitude;
  double? zoom;

  MoveModel({
    required this.latitude,
    required this.longitude,
    this.zoom,
  });

  Map<String, dynamic> toNeshanMoveModel() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'zoom': zoom,
    };
  }
}
