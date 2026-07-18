import 'package:flutter_test/flutter_test.dart';
import 'package:minibanter/features/recording/native_compositor_gateway.dart';
import 'package:minibanter/features/recording/recording_controller.dart';

class FakeNativeCompositorGateway implements NativeCompositorGateway {
  int currentPresentationUs = 1000000;
  final appendedCues = <NativeOverlayCue>[];
  bool prepared = false;
  bool started = false;

  @override
  Future<void> appendCue(NativeOverlayCue cue) async {
    appendedCues.add(cue);
  }

  @override
  Future<int> currentRecordingPresentationUs() async => currentPresentationUs;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> prepare(NativeCompositorConfig config) async {
    prepared = true;
  }

  @override
  Future<int> startRecording() async {
    started = true;
    return 0;
  }

  @override
  Future<void> replaceCue(NativeOverlayCue cue) async {
    appendedCues.add(cue);
  }

  @override
  Future<NativeCompositedVideo> stopRecording() {
    throw UnimplementedError();
  }
}

void main() {
  test('schedules a fictional caption from the native capture clock', () async {
    final compositor = FakeNativeCompositorGateway();
    final controller = RecordingController(compositor: compositor);

    await controller.prepare(const NativeCompositorConfig());
    await controller.startRecording();
    final cue = await controller.scheduleCaption(
      id: 'cue-1',
      text: 'A fictional joke.',
      duration: const Duration(milliseconds: 2600),
    );

    expect(compositor.prepared, isTrue);
    expect(compositor.started, isTrue);
    expect(cue.startUs, 1200000);
    expect(cue.endUs, 3800000);
    expect(compositor.appendedCues, hasLength(1));
    expect(compositor.appendedCues.single.startUs, cue.startUs);
  });
}
