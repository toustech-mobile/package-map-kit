class PolyLinePointModel {
  double latitude;
  double longitude;
  double heading;

  PolyLinePointModel(this.latitude, this.longitude, this.heading);


  static List<PolyLinePointModel> decodePoints(String? encoded) {
    if (encoded == null) return [];
    if (encoded.isEmpty) return [];
    List<PolyLinePointModel> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(PolyLinePointModel(lat / 1e5, lng / 1e5, 0.0));
    }
    return points;
  }
}
