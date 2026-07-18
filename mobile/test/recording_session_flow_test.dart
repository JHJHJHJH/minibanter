import 'package:minibanter/main.dart';
import 'package:minibanter/services/baby_subtitles_api.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_camera_capture.dart';

class FakeRecordingSessionGateway implements RecordingSessionGateway {
  bool wasCalled = false;

  @override
  Future<RecordingSession> createRecordingSession({
    required String personality,
    required String language,
    String? regionalStyle,
  }) async {
    wasCalled = true;
    return const RecordingSession(
      id: 'local-session',
      status: 'active',
      disclaimer: 'Fictional subtitles for entertainment only.',
    );
  }
}

void main() {
  testWidgets(
    'starts a backend recording session before displaying live caption',
    (tester) async {
      final gateway = FakeRecordingSessionGateway();
      await tester.pumpWidget(
        BabySubtitlesApp(
          sessionGateway: gateway,
          cameraCapture: FakeCameraCapture(),
        ),
      );

      await tester.tap(find.text('Start recording'));
      await tester.pump();

      expect(gateway.wasCalled, isTrue);
      expect(find.text('Recording'), findsOneWidget);
    },
  );
}
