import 'package:flutter/material.dart';
import 'package:minibanter_compositor/minibanter_compositor.dart';

void main() => runApp(const CompositorExampleApp());

class CompositorExampleApp extends StatelessWidget {
  const CompositorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    const configuration = CompositorConfiguration(
      cameraFacing: CompositorCameraFacing.back,
    );
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Minibanter compositor')),
        body: Center(
          child: Text(
            'Native compositor contract: ${configuration.width}×${configuration.height} at ${configuration.targetFps} FPS',
          ),
        ),
      ),
    );
  }
}
