import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/compositor_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/src/main/kotlin/com/minibanter/minibanter_compositor/CompositorApi.g.kt',
    kotlinOptions: KotlinOptions(),
    swiftOut:
        'ios/minibanter_compositor/Sources/minibanter_compositor/CompositorApi.g.swift',
    swiftOptions: SwiftOptions(),
    dartPackageName: 'minibanter_compositor',
  ),
)
class CompositorConfig {
  CompositorConfig({
    required this.cameraFacing,
    required this.width,
    required this.height,
    required this.targetFps,
    required this.mirrorFrontPreview,
  });

  String cameraFacing;
  int width;
  int height;
  int targetFps;
  bool mirrorFrontPreview;
}

class CompositorCue {
  CompositorCue({
    required this.id,
    required this.kind,
    this.text,
    required this.startUs,
    required this.endUs,
    required this.x,
    required this.y,
    required this.scale,
    required this.rotationDegrees,
    required this.zIndex,
    required this.styleTemplate,
  });

  String id;
  String kind;
  String? text;
  int startUs;
  int endUs;
  double x;
  double y;
  double scale;
  double rotationDegrees;
  int zIndex;
  String styleTemplate;
}

class NativeRecordingState {
  NativeRecordingState({
    required this.isReady,
    required this.isRecording,
    required this.presentationUs,
    this.previewTextureId,
    this.errorCode,
  });

  bool isReady;
  bool isRecording;
  int presentationUs;
  String? previewTextureId;
  String? errorCode;
}

class RecordedCompositedVideo {
  RecordedCompositedVideo({
    required this.localPath,
    required this.durationUs,
    required this.timelineJson,
  });

  String localPath;
  int durationUs;
  String timelineJson;
}

@HostApi()
abstract class CompositorHostApi {
  @async
  void prepare(CompositorConfig config);

  @async
  int startRecording();

  @async
  int currentPresentationUs();

  @async
  void appendCue(CompositorCue cue);

  @async
  void replaceCue(CompositorCue cue);

  @async
  RecordedCompositedVideo stopRecording();

  @async
  void dispose();
}

@FlutterApi()
abstract class CompositorFlutterApi {
  void onStateChanged(NativeRecordingState state);

  void onRecoverableError(String code, String message);
}
