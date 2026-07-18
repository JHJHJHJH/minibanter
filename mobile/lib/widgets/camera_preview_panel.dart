import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

abstract interface class CameraCapture {
  Future<void> startVideoRecording();
  Future<RecordedVideo> stopVideoRecording();
}

class RecordedVideo {
  const RecordedVideo(this.readBytes);

  final Future<List<int>> Function() readBytes;

  factory RecordedVideo.fromBytes(List<int> bytes) =>
      RecordedVideo(() async => bytes);
}

class CameraControllerCapture implements CameraCapture {
  CameraControllerCapture(this._controller);

  final CameraController _controller;

  @override
  Future<void> startVideoRecording() => _controller.startVideoRecording();

  @override
  Future<RecordedVideo> stopVideoRecording() async {
    final recordedFile = await _controller.stopVideoRecording();
    return RecordedVideo(recordedFile.readAsBytes);
  }
}

class CameraPreviewPanel extends StatefulWidget {
  const CameraPreviewPanel({super.key, this.loadCameras, this.onCaptureReady});

  final Future<List<CameraDescription>> Function()? loadCameras;
  final ValueChanged<CameraCapture>? onCaptureReady;

  @override
  State<CameraPreviewPanel> createState() => _CameraPreviewPanelState();
}

class _CameraPreviewPanelState extends State<CameraPreviewPanel> {
  CameraController? _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await (widget.loadCameras ?? availableCameras)();
      if (cameras.isEmpty) {
        throw StateError('No camera is available.');
      }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      widget.onCaptureReady?.call(CameraControllerCapture(controller));
    } catch (_) {
      if (mounted) setState(() => _errorText = 'Camera unavailable');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorText != null) {
      return const _CameraFallback();
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(
        color: Color(0xFF1E2B2E),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_rounded, size: 64, color: Colors.white70),
              SizedBox(height: 12),
              Text('Opening camera…', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _CameraFallback extends StatelessWidget {
  const _CameraFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF2F3E46),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_rounded, size: 64, color: Colors.white70),
            SizedBox(height: 12),
            Text(
              'Camera unavailable',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Check camera permission and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
