enum CompositorCameraFacing { front, back }

class CompositorConfiguration {
  const CompositorConfiguration({
    this.cameraFacing = CompositorCameraFacing.back,
    this.width = 1920,
    this.height = 1080,
    this.targetFps = 30,
  });

  final CompositorCameraFacing cameraFacing;
  final int width;
  final int height;
  final int targetFps;

  Map<String, Object> toMap() => {
    'cameraFacing': cameraFacing.name,
    'width': width,
    'height': height,
    'targetFps': targetFps,
  };
}
