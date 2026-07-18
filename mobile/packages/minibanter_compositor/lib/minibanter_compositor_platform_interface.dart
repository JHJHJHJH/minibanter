import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'minibanter_compositor_method_channel.dart';
import 'src/compositor_models.dart';

abstract class MinibanterCompositorPlatform extends PlatformInterface {
  /// Constructs a MinibanterCompositorPlatform.
  MinibanterCompositorPlatform() : super(token: _token);

  static final Object _token = Object();

  static MinibanterCompositorPlatform _instance =
      MethodChannelMinibanterCompositor();

  /// The default instance of [MinibanterCompositorPlatform] to use.
  ///
  /// Defaults to [MethodChannelMinibanterCompositor].
  static MinibanterCompositorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MinibanterCompositorPlatform] when
  /// they register themselves.
  static set instance(MinibanterCompositorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> prepare(CompositorConfiguration configuration) {
    throw UnimplementedError('prepare() has not been implemented.');
  }

  Future<int> startRecording() {
    throw UnimplementedError('startRecording() has not been implemented.');
  }
}
