import 'package:minibanter_compositor/minibanter_compositor.dart';

import 'native_compositor_gateway.dart';

class PigeonNativeCompositorGateway implements NativeCompositorGateway {
  PigeonNativeCompositorGateway({CompositorHostApi? hostApi})
    : _hostApi = hostApi ?? CompositorHostApi();

  final CompositorHostApi _hostApi;

  @override
  Future<void> prepare(NativeCompositorConfig config) => _hostApi.prepare(
    CompositorConfig(
      cameraFacing: config.cameraFacing.name,
      width: config.width,
      height: config.height,
      targetFps: config.targetFps,
      mirrorFrontPreview: config.cameraFacing == NativeCameraFacing.front,
    ),
  );

  @override
  Future<int> startRecording() => _hostApi.startRecording();

  @override
  Future<int> currentRecordingPresentationUs() =>
      _hostApi.currentPresentationUs();

  @override
  Future<void> appendCue(NativeOverlayCue cue) =>
      _hostApi.appendCue(_toPigeonCue(cue));

  @override
  Future<void> replaceCue(NativeOverlayCue cue) =>
      _hostApi.replaceCue(_toPigeonCue(cue));

  @override
  Future<NativeCompositedVideo> stopRecording() async {
    final video = await _hostApi.stopRecording();
    return NativeCompositedVideo(
      localPath: video.localPath,
      durationUs: video.durationUs,
      timelineJson: video.timelineJson,
    );
  }

  @override
  Future<void> dispose() => _hostApi.dispose();

  CompositorCue _toPigeonCue(NativeOverlayCue cue) => CompositorCue(
    id: cue.id,
    kind: cue.kind,
    text: cue.text,
    startUs: cue.startUs,
    endUs: cue.endUs,
    x: cue.x,
    y: cue.y,
    scale: cue.scale,
    rotationDegrees: cue.rotationDegrees,
    zIndex: cue.zIndex,
    styleTemplate: cue.styleTemplate,
  );
}
