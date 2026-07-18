import 'package:flutter_test/flutter_test.dart';
import 'package:minibanter_compositor/minibanter_compositor.dart';
import 'package:minibanter_compositor/minibanter_compositor_method_channel.dart';
import 'package:minibanter_compositor/minibanter_compositor_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMinibanterCompositorPlatform
    with MockPlatformInterfaceMixin
    implements MinibanterCompositorPlatform {
  @override
  Future<void> prepare(CompositorConfiguration configuration) async {}

  @override
  Future<int> startRecording() async => 42;
}

void main() {
  final initialPlatform = MinibanterCompositorPlatform.instance;

  test('$MethodChannelMinibanterCompositor is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMinibanterCompositor>());
  });

  test('delegates native capture-clock startup to the platform', () async {
    final compositor = MinibanterCompositor();
    MinibanterCompositorPlatform.instance = MockMinibanterCompositorPlatform();

    await compositor.prepare(const CompositorConfiguration());

    expect(await compositor.startRecording(), 42);
  });
}
