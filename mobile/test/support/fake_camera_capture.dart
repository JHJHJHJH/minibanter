import 'package:minibanter/widgets/camera_preview_panel.dart';

class FakeCameraCapture implements CameraCapture {
  bool started = false;
  bool stopped = false;

  @override
  Future<void> startVideoRecording() async => started = true;

  @override
  Future<RecordedVideo> stopVideoRecording() async {
    stopped = true;
    return RecordedVideo.fromBytes([1, 2, 3]);
  }
}
