import 'package:flutter/material.dart';
import 'package:map_kit/models/marker_model.dart';

class MarkerWidget extends StatelessWidget {
  Widget child;
  MarkerModel model;
  void Function(MarkerModel)? onMarkerTap;

  MarkerWidget({
    super.key,
    required this.child,
    required this.model,
    this.onMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: child,
      onTap: () {
        if (onMarkerTap != null) {
          onMarkerTap!.call(model);
        }
      },
    );
  }
}
