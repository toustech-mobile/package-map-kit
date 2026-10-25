import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:map_kit/widgets/neshan/neshan_ios_renderer.dart';

class MapKit {
  static const MethodChannel _channel = MethodChannel('map_kit');
  static const MethodChannel _viewChannel = MethodChannel('map_kit_view');

  static Future<void> initialize() async {
    await NeshanIosRenderer.ensureAvailable();
    await _channel.invokeMethod('createMapView');
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
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = MapKit.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorWidget(snapshot.error!);
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.expand();
        }
        return UiKitView(
          viewType: NeshanIosRenderer.viewType,
          creationParams: widget.creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        );
      },
    );
  }
}
