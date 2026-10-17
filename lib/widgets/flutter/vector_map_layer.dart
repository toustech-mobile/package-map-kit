import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:map_kit/models/vector_map_style.dart';

/// Owns the asynchronously loaded style independently of camera and overlays.
class VectorMapLayer extends StatefulWidget {
  final VectorMapStyle style;
  final bool dark;

  @visibleForTesting
  final Future<vt.Style> Function(String uri, Map<String, String> headers)?
      loader;

  const VectorMapLayer({
    super.key,
    required this.style,
    this.dark = false,
    this.loader,
  });

  @override
  State<VectorMapLayer> createState() => _VectorMapLayerState();
}

class _VectorMapLayerState extends State<VectorMapLayer> {
  vt.Style? _loaded;
  bool _loading = true;
  bool _failed = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(VectorMapLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.style.uriFor(widget.dark) !=
            oldWidget.style.uriFor(oldWidget.dark) ||
        !mapEquals(widget.style.headers, oldWidget.style.headers) ||
        widget.loader != oldWidget.loader) {
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _loading = true;
    _failed = false;
    try {
      final uri = widget.style.uriFor(widget.dark);
      final headers = Map<String, String>.of(widget.style.headers);
      final style = await (widget.loader?.call(uri, headers) ??
          vt.StyleReader(uri: uri, headers: headers, cache: false).read());
      if (!mounted || generation != _generation) {
        style.dispose();
        return;
      }
      final previous = _loaded;
      setState(() {
        _loaded = style;
        _loading = false;
      });
      // The old renderer must detach before its providers/sprites are released.
      if (previous != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
      }
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  void dispose() {
    ++_generation;
    _loaded?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _loaded;
    final attribution = {
      if (widget.style.attribution.isNotEmpty) widget.style.attribution,
      if (style != null) ...style.attributions.map((entry) => entry.text),
    }.join(' · ');
    return Stack(
      children: [
        if (style != null)
          vt.VectorTileLayer(
            key: ObjectKey(style),
            theme: style.theme,
            tileProviders: style.providers,
            rasterSources: style.rasterSources,
            sprites: style.sprites,
            // Do not persist provider data without opting into its cache policy.
            diskCacheMaximumSizeInBytes: 0,
          ),
        if (_loading)
          const IgnorePointer(
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_failed)
          Center(
            child: Material(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load map style.'),
                    TextButton(
                      onPressed: () => setState(() {
                        _load();
                      }),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (attribution.isNotEmpty)
          Align(
            alignment: Alignment.bottomRight,
            child: ColoredBox(
              color: Colors.white70,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(attribution,
                    style: const TextStyle(fontSize: 11, color: Colors.black)),
              ),
            ),
          ),
      ],
    );
  }
}
