import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minibanter_compositor/minibanter_compositor.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('defines a native recording configuration', (tester) async {
    const configuration = CompositorConfiguration(
      cameraFacing: CompositorCameraFacing.front,
      targetFps: 30,
    );

    expect(configuration.toMap()['cameraFacing'], 'front');
    expect(configuration.toMap()['targetFps'], 30);
  });
}
