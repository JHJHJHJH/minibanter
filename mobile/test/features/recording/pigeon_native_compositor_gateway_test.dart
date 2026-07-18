import 'package:flutter_test/flutter_test.dart';
import 'package:minibanter/features/recording/native_compositor_gateway.dart';
import 'package:minibanter/features/recording/pigeon_native_compositor_gateway.dart';
import 'package:minibanter_compositor/minibanter_compositor.dart';

class FakeCompositorHostApi extends CompositorHostApi {
  CompositorConfig? preparedWith;
  CompositorCue? appendedCue;
  CompositorCue? replacedCue;

  @override
  Future<void> prepare(CompositorConfig config) async {
    preparedWith = config;
  }

  @override
  Future<int> startRecording() async => 0;

  @override
  Future<int> currentPresentationUs() async => 1250000;

  @override
  Future<void> appendCue(CompositorCue cue) async {
    appendedCue = cue;
  }

  @override
  Future<void> replaceCue(CompositorCue cue) async {
    replacedCue = cue;
  }

  @override
  Future<RecordedCompositedVideo> stopRecording() async =>
      RecordedCompositedVideo(
        localPath: '/tmp/composited.mp4',
        durationUs: 2500000,
        timelineJson: '{"version":1,"cues":[]}',
      );

  @override
  Future<void> dispose() async {}
}

void main() {
  test(
    'maps the app native gateway to the Pigeon compositor contract',
    () async {
      final host = FakeCompositorHostApi();
      final gateway = PigeonNativeCompositorGateway(hostApi: host);

      await gateway.prepare(
        const NativeCompositorConfig(cameraFacing: NativeCameraFacing.front),
      );
      await gateway.appendCue(
        const NativeOverlayCue(
          id: 'cue-1',
          kind: 'caption',
          text: 'A fictional joke.',
          startUs: 1200000,
          endUs: 3800000,
          x: 0.5,
          y: 0.83,
          scale: 1,
          rotationDegrees: 0,
          zIndex: 1,
          styleTemplate: 'lower_third_v1',
        ),
      );
      await gateway.replaceCue(
        const NativeOverlayCue(
          id: 'cue-1',
          kind: 'caption',
          text: 'A replacement fictional joke.',
          startUs: 1300000,
          endUs: 3900000,
          x: 0.5,
          y: 0.83,
          scale: 1,
          rotationDegrees: 0,
          zIndex: 1,
          styleTemplate: 'lower_third_v1',
        ),
      );

      expect(host.preparedWith!.cameraFacing, 'front');
      expect(await gateway.currentRecordingPresentationUs(), 1250000);
      expect(host.appendedCue!.startUs, 1200000);
      expect(host.appendedCue!.styleTemplate, 'lower_third_v1');
      expect(host.replacedCue!.startUs, 1300000);
      expect(host.replacedCue!.text, 'A replacement fictional joke.');
    },
  );

  test(
    'preserves the native-produced overlay timeline with the final MP4',
    () async {
      final gateway = PigeonNativeCompositorGateway(
        hostApi: FakeCompositorHostApi(),
      );

      final video = await gateway.stopRecording();

      expect(video.timelineJson, '{"version":1,"cues":[]}');
    },
  );
}
