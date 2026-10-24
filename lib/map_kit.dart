import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class MapKit {
  static const MethodChannel _channel = MethodChannel('map_kit');
  static const MethodChannel _viewChannel = MethodChannel('map_kit_view');

  static Future<void> initialize() async {
    try {
      await _channel.invokeMethod('createMapView');
    } on PlatformException catch (e) {
      print('Failed to initialize map view: ${e.message}');
    }
  }

  @Deprecated('The prototype button was removed. Use UiMap callbacks.')
  static void setButtonCallback(Function() onButtonTapped) {
    _viewChannel.setMethodCallHandler((call) async {
      if (call.method == 'onButtonTapped') {
        onButtonTapped();
      }
    });
  }
}

class MapKitView extends StatefulWidget {
  final Function()? onButtonTapped;
  final Map<String, dynamic> creationParams;

  const MapKitView(
      {super.key, this.onButtonTapped, this.creationParams = const {}});

  @override
  State<MapKitView> createState() => _MapKitViewState();
}

class _MapKitViewState extends State<MapKitView> {
  @override
  void initState() {
    super.initState();
    MapKit.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: 'map_kit_view',
      creationParams: widget.creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
