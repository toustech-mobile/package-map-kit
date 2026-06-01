# <img src="https://github.com/toustechmobile/package-map-kit/blob/dev/example/assets/icons/package-map.png?raw=true" width="28"> MapKit

`UiMap` is a customizable map widget designed to support multiple map providers, such as `flutter_map` and others. It allows the integration of markers, circles, and polylines, with configurable options for interactions and map customization.

## Class Definition

```dart
class UiMap extends StatefulWidget {
  final MapProvider mapProvider;
  final UiMapController? controller;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongPress;
  final void Function(MarkerModel)? onMarkerTap;
  final void Function(CircleMarkerModel)? onCircleTap;
  LatLng? initialCenter;
  bool? isDarkMode;
  double? zoom;
  bool? isCurrentLocationEnable;
  List<MarkerModel>? markers;
  List<CircleMarkerModel>? circles;
  List<PolyLineModel>? polyLines;

  UiMap({
    super.key,
    required this.mapProvider,
    this.controller,
    this.onTap,
    this.onLongPress,
    this.onMarkerTap,
    this.onCircleTap,
    this.initialCenter,
    this.isDarkMode,
    this.zoom,
    this.isCurrentLocationEnable,
    List<MarkerModel>? markers,
    List<CircleMarkerModel>? circles,
    List<PolyLineModel>? polyLines,
  }) {
    this.markers = markers ?? [];
    this.circles = circles ?? [];
    this.polyLines = polyLines ?? [];
  }

  @override
  _UiMapState createState() => _UiMapState();
}
```

## Constructor Parameters

| Parameter                | Type                                | Description                                                                                           |
|--------------------------|-------------------------------------|-------------------------------------------------------------------------------------------------------|
| `mapProvider`            | `MapProvider`                      | Specifies the map provider to use (e.g., `flutter_map`).                                             |
| `controller`             | `UiMapController?`                 | Optional controller to manage the map programmatically.                                              |
| `onTap`                  | `void Function(LatLng)?`           | Callback for when the map is tapped.                                                                 |
| `onLongPress`            | `void Function(LatLng)?`           | Callback for when the map is long-pressed.                                                           |
| `onMarkerTap`            | `void Function(MarkerModel)?`      | Callback for when a marker is tapped.                                                                |
| `onCircleTap`            | `void Function(CircleMarkerModel)?`| Callback for when a circle is tapped.                                                                |
| `initialCenter`          | `LatLng?`                          | Initial center position of the map.                                                                  |
| `isDarkMode`             | `bool?`                            | Enables dark mode for the map (if supported by the provider).                                        |
| `zoom`                   | `double?`                          | Initial zoom level of the map.                                                                       |
| `isCurrentLocationEnable`| `bool?`                            | Enables or disables showing the user's current location.                                             |
| `markers`                | `List<MarkerModel>?`               | List of markers to be displayed on the map.                                                          |
| `circles`                | `List<CircleMarkerModel>?`         | List of circle markers to be displayed on the map.                                                   |
| `polyLines`              | `List<PolyLineModel>?`             | List of polylines to be displayed on the map.                                                        |

## Example Usage

```dart
UiMap(
  mapProvider: MapProvider.flutter,
  initialCenter: LatLng(35.6892, 51.3890),
  zoom: 12.0,
  isDarkMode: false,
  isCurrentLocationEnable: true,
  markers: [
    MarkerModel(position: LatLng(35.6892, 51.3890), id: "marker1"),
  ],
  onMarkerTap: (marker) {
    print("Marker tapped: ${marker.id}");
  },
);
```

## Controller

`UiMapController` provides methods to programmatically interact with the map.

### Methods

| Method           | Type                                | Description                                           |
|------------------|-------------------------------------|-------------------------------------------------------|
| `addMarker`      | `Function(MarkerModel)`             | Adds a marker to the map.                             |
| `addCircle`      | `Function(CircleMarkerModel)`       | Adds a circle to the map.                             |
| `addPolyline`    | `Function(List<PolyLineModel>)`     | Adds one or more polylines to the map.                |
| `moveCamera`     | `Function(MoveModel)`               | Moves the camera to a specified position.             |
| `setUserLocation`| `Function(UserMarkerModel)`         | Updates the user's location on the map.               |

## State Class

The `_UiMapState` class handles the map rendering and delegates functionality to the selected map provider.

### `_UiMapState.build`

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: widget.mapProvider == MapProvider.flutter
        ? FlutterMapWidget(
            uiMapController: widget.controller,
            initialCenter: widget.initialCenter,
            zoom: widget.zoom,
            isCurrentLocationEnable: widget.isCurrentLocationEnable,
            isDarkMode: widget.isDarkMode,
            markers: widget.markers,
            polyLines: widget.polyLines,
            circles: widget.circles,
            onMarkerTap: widget.onMarkerTap,
            onCircleTap: widget.onCircleTap,
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
          )
        : _buildNeshanMap(),
  );
}
```

### Dependencies

Ensure the following models and dependencies are available:
- `MarkerModel`
- `CircleMarkerModel`
- `PolyLineModel`
- `MoveModel`
- `UserMarkerModel`
