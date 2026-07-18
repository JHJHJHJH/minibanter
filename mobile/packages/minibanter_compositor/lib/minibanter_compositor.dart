export 'src/compositor_api.g.dart';
export 'src/compositor_models.dart';

import 'src/compositor_models.dart';
import 'minibanter_compositor_platform_interface.dart';

class MinibanterCompositor {
  Future<void> prepare(CompositorConfiguration configuration) =>
      MinibanterCompositorPlatform.instance.prepare(configuration);

  Future<int> startRecording() =>
      MinibanterCompositorPlatform.instance.startRecording();
}
