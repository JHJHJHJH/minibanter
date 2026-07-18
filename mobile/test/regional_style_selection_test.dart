import 'package:minibanter/main.dart';
import 'package:minibanter/services/baby_subtitles_api.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_camera_capture.dart';

class StyleCapturingGateway implements RecordingSessionGateway {
  String? regionalStyle;

  @override
  Future<RecordingSession> createRecordingSession({
    required String personality,
    required String language,
    String? regionalStyle,
  }) async {
    this.regionalStyle = regionalStyle;
    return const RecordingSession(
      id: 'session',
      status: 'active',
      disclaimer: 'Fictional subtitles for entertainment only.',
    );
  }
}

void main() {
  testWidgets(
    'sends the optional parent-selected regional style to the session API',
    (tester) async {
      final gateway = StyleCapturingGateway();
      await tester.pumpWidget(
        BabySubtitlesApp(
          sessionGateway: gateway,
          cameraCapture: FakeCameraCapture(),
        ),
      );

      await tester.tap(find.text('No regional style'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Singapore English').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start recording'));
      await tester.pump();

      expect(gateway.regionalStyle, 'singapore_english');
    },
  );

  testWidgets('sends Mandarin regional style when selected by the parent', (
    tester,
  ) async {
    final gateway = StyleCapturingGateway();
    await tester.pumpWidget(
      BabySubtitlesApp(
        sessionGateway: gateway,
        cameraCapture: FakeCameraCapture(),
      ),
    );

    await tester.tap(find.text('No regional style'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mandarin').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start recording'));
    await tester.pump();

    expect(gateway.regionalStyle, 'mandarin');
  });
}
