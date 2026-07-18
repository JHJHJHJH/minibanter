import 'overlay_timeline.dart';

class NativeCompositorConfig {
  const NativeCompositorConfig({
    this.cameraFacing = NativeCameraFacing.back,
    this.width = 1920,
    this.height = 1080,
    this.targetFps = 30,
  });

  final NativeCameraFacing cameraFacing;
  final int width;
  final int height;
  final int targetFps;
}

enum NativeCameraFacing { front, back }

class NativeOverlayCue {
  const NativeOverlayCue({
    required this.id,
    required this.kind,
    required this.text,
    required this.startUs,
    required this.endUs,
    required this.x,
    required this.y,
    required this.scale,
    required this.rotationDegrees,
    required this.zIndex,
    required this.styleTemplate,
  });

  factory NativeOverlayCue.fromTimelineCue(OverlayCue cue) => NativeOverlayCue(
    id: cue.id,
    kind: cue.kind.name,
    text: cue.text,
    startUs: cue.startUs,
    endUs: cue.endUs,
    x: cue.transform.x,
    y: cue.transform.y,
    scale: cue.transform.scale,
    rotationDegrees: cue.transform.rotationDegrees,
    zIndex: cue.zIndex,
    styleTemplate: cue.style.template,
  );

  final String id;
  final String kind;
  final String? text;
  final int startUs;
  final int endUs;
  final double x;
  final double y;
  final double scale;
  final double rotationDegrees;
  final int zIndex;
  final String styleTemplate;
}

class NativeCompositedVideo {
  const NativeCompositedVideo({
    required this.localPath,
    required this.durationUs,
    required this.timelineJson,
  });

  final String localPath;
  final int durationUs;
  final String timelineJson;
}

abstract interface class NativeCompositorGateway {
  Future<void> prepare(NativeCompositorConfig config);
  Future<int> startRecording();
  Future<int> currentRecordingPresentationUs();
  Future<void> appendCue(NativeOverlayCue cue);
  Future<void> replaceCue(NativeOverlayCue cue);
  Future<NativeCompositedVideo> stopRecording();
  Future<void> dispose();
}
