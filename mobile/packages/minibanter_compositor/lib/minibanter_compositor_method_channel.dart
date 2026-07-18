import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'minibanter_compositor_platform_interface.dart';
import 'src/compositor_models.dart';

/// An implementation of [MinibanterCompositorPlatform] that uses method channels.
class MethodChannelMinibanterCompositor extends MinibanterCompositorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('minibanter_compositor');

  @override
  Future<void> prepare(CompositorConfiguration configuration) =>
      methodChannel.invokeMethod<void>('prepare', configuration.toMap());

  @override
  Future<int> startRecording() async =>
      (await methodChannel.invokeMethod<int>('startRecording'))!;
}
