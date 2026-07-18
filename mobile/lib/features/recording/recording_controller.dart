import 'native_compositor_gateway.dart';
import 'overlay_timeline.dart';

class RecordingController {
  RecordingController({
    required this.compositor,
    this.captionLead = const Duration(milliseconds: 200),
  });

  final NativeCompositorGateway compositor;
  final Duration captionLead;
  OverlayTimeline _timeline = OverlayTimeline([]);
  bool _isPrepared = false;
  bool _isRecording = false;

  OverlayTimeline get timeline => _timeline;
  bool get isPrepared => _isPrepared;
  bool get isRecording => _isRecording;

  Future<void> prepare(NativeCompositorConfig config) async {
    await compositor.prepare(config);
    _isPrepared = true;
  }

  Future<void> startRecording() async {
    if (!_isPrepared) {
      throw StateError('Prepare the native compositor before recording.');
    }
    await compositor.startRecording();
    _isRecording = true;
    _timeline = OverlayTimeline([]);
  }

  Future<OverlayCue> scheduleCaption({
    required String id,
    required String text,
    required Duration duration,
    OverlayTransform? transform,
    OverlayStyle? style,
    int zIndex = 0,
  }) async {
    if (!_isRecording) {
      throw StateError('Start recording before scheduling an overlay.');
    }
    final nowUs = await compositor.currentRecordingPresentationUs();
    final startUs = nowUs + captionLead.inMicroseconds;
    final cue = OverlayCue.caption(
      id: id,
      text: text,
      startUs: startUs,
      endUs: startUs + duration.inMicroseconds,
      transform: transform ?? OverlayTransform(x: 0.5, y: 0.83),
      style: style ?? const OverlayStyle(template: 'lower_third_v1'),
      zIndex: zIndex,
    );
    await compositor.appendCue(NativeOverlayCue.fromTimelineCue(cue));
    _timeline = _timeline.replace(cue);
    return cue;
  }

  Future<NativeCompositedVideo> stopRecording() async {
    if (!_isRecording) {
      throw StateError('No native recording is active.');
    }
    try {
      return await compositor.stopRecording();
    } finally {
      _isRecording = false;
    }
  }

  Future<void> dispose() => compositor.dispose();
}
