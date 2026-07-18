import 'package:minibanter/main.dart';
import 'package:minibanter/services/baby_subtitles_api.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_camera_capture.dart';

class CapturingGateway implements RecordingSessionGateway {
  String? language;

  @override
  Future<RecordingSession> createRecordingSession({
    required String personality,
    required String language,
    String? regionalStyle,
  }) async {
    this.language = language;
    return const RecordingSession(
      id: 'session',
      status: 'active',
      disclaimer: 'Fictional subtitles for entertainment only.',
    );
  }
}

void main() {
  testWidgets(
    'sends the parent-selected subtitle language to the session API',
    (tester) async {
      final gateway = CapturingGateway();
      await tester.pumpWidget(
        BabySubtitlesApp(
          sessionGateway: gateway,
          cameraCapture: FakeCameraCapture(),
        ),
      );

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Japanese').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start recording'));
      await tester.pump();

      expect(gateway.language, 'ja');
    },
  );
}
