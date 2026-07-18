import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minibanter_compositor/minibanter_compositor.dart';
import 'package:minibanter_compositor/minibanter_compositor_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelMinibanterCompositor();
  const channel = MethodChannel('minibanter_compositor');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          calls.add(methodCall);
          switch (methodCall.method) {
            case 'prepare':
              return null;
            case 'startRecording':
              return 0;
            default:
              throw MissingPluginException(methodCall.method);
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('prepares a native compositor and starts its capture clock', () async {
    await platform.prepare(
      const CompositorConfiguration(
        cameraFacing: CompositorCameraFacing.front,
        width: 1920,
        height: 1080,
        targetFps: 30,
      ),
    );
    final originUs = await platform.startRecording();

    expect(originUs, 0);
    expect(calls.map((call) => call.method), ['prepare', 'startRecording']);
    expect(calls.first.arguments, {
      'cameraFacing': 'front',
      'width': 1920,
      'height': 1080,
      'targetFps': 30,
    });
  });
}
