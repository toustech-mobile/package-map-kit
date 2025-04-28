import 'package:flutter/material.dart';
import 'package:map_kit/map_kit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('MapKit Example'),
        ),
        body: Center(
          child: MapKitView(
            onButtonTapped: () {
              print('Button tapped in iOS!');
              // You can add your callback logic here
            },
          ),
        ),
      ),
    );
  }
}
