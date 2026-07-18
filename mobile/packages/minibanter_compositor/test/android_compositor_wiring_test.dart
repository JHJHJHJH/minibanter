import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android plugin registers the Pigeon host API and compositor session', () {
    final plugin = File(
      'android/src/main/kotlin/com/minibanter/minibanter_compositor/MinibanterCompositorPlugin.kt',
    ).readAsStringSync();
    final session = File(
      'android/src/main/kotlin/com/minibanter/minibanter_compositor/AndroidCompositorSession.kt',
    ).readAsStringSync();

    expect(plugin, contains('CompositorHostApi.setUp'));
    expect(plugin, contains('AndroidCompositorSession'));
    expect(plugin, isNot(contains('MethodChannel')));
    expect(session, contains('CaptureClock'));
    expect(session, contains('onCameraFrameTimestamp'));
    expect(session, isNot(contains('SystemClock')));
    expect(session, contains('MediaCodec'));
    expect(session, contains('MediaMuxer'));
    expect(
      File(
        'android/src/main/kotlin/com/minibanter/minibanter_compositor/H264Mp4Encoder.kt',
      ).existsSync(),
      isTrue,
    );
    expect(session, isNot(contains('ffmpeg')));
  });
}
