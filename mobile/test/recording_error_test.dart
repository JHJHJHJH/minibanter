import 'package:minibanter/main.dart';
import 'package:minibanter/services/baby_subtitles_api.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_camera_capture.dart';

class FailingRecordingSessionGateway implements RecordingSessionGateway {
  @override
  Future<RecordingSession> createRecordingSession({
    required String personality,
    required String language,
    String? regionalStyle,
  }) => throw StateError('network unavailable');
}

void main() {
  testWidgets(
    'keeps recording stopped and displays a retryable error on API failure',
    (tester) async {
      await tester.pumpWidget(
        BabySubtitlesApp(
          sessionGateway: FailingRecordingSessionGateway(),
          cameraCapture: FakeCameraCapture(),
        ),
      );

      await tester.tap(find.text('Start recording'));
      await tester.pump();

      expect(
        find.text('Could not start a recording session. Try again.'),
        findsOneWidget,
      );
      expect(find.text('Recording'), findsNothing);
      expect(find.text('Start recording'), findsOneWidget);
    },
  );
}
