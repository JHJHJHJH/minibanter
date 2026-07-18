import 'package:minibanter/main.dart';
import 'package:minibanter/services/baby_subtitles_api.dart';
import 'package:minibanter/widgets/camera_preview_panel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeGateway implements RecordingSessionGateway {
  @override
  Future<RecordingSession> createRecordingSession({
    required String personality,
    required String language,
    String? regionalStyle,
  }) async => const RecordingSession(
    id: 'session',
    status: 'active',
    disclaimer: 'Fictional subtitles for entertainment only.',
  );
}

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

class FakeExportGateway implements VideoExportGateway {
  List<int>? uploadedBytes;

  @override
  Future<ExportedVideo> exportRecording({
    required String sessionId,
    required List<int> videoBytes,
    required String caption,
  }) async {
    uploadedBytes = videoBytes;
    return const ExportedVideo(
      id: 'export',
      status: 'ready',
      downloadUrl: 'http://example.test/export.mp4',
    );
  }
}

class FakeExportOpener implements ExportOpener {
  Uri? openedUri;

  @override
  Future<bool> open(Uri uri) async {
    openedUri = uri;
    return true;
  }
}

void main() {
  testWidgets('records and marks a captured video ready for export', (
    tester,
  ) async {
    final capture = FakeCameraCapture();
    final exportGateway = FakeExportGateway();
    final exportOpener = FakeExportOpener();
    await tester.pumpWidget(
      BabySubtitlesApp(
        sessionGateway: FakeGateway(),
        exportGateway: exportGateway,
        exportOpener: exportOpener,
        cameraCapture: capture,
      ),
    );

    await tester.tap(find.text('Start recording'));
    await tester.pump();
    expect(capture.started, isTrue);
    expect(find.text('Recording'), findsOneWidget);

    await tester.tap(find.text('Stop recording'));
    await tester.pump();
    expect(capture.stopped, isTrue);
    expect(find.text('Export video'), findsOneWidget);

    await tester.tap(find.text('Export video'));
    await tester.pump();
    expect(exportGateway.uploadedBytes, [1, 2, 3]);
    expect(find.text('Export ready'), findsOneWidget);
    expect(find.text('Open exported video'), findsOneWidget);

    await tester.tap(find.text('Open exported video'));
    await tester.pump();
    expect(exportOpener.openedUri, Uri.parse('http://example.test/export.mp4'));
  });
}
