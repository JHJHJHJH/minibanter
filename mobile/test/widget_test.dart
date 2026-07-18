import 'package:minibanter/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens a camera-first fictional subtitles experience', (
    tester,
  ) async {
    await tester.pumpWidget(const BabySubtitlesApp());

    expect(find.text('Minibanter'), findsOneWidget);
    expect(
      find.text('Fictional captions for entertainment only'),
      findsOneWidget,
    );
    expect(find.text('Start recording'), findsOneWidget);
  });

  testWidgets('waits for the camera before recording begins', (tester) async {
    await tester.pumpWidget(const BabySubtitlesApp());

    await tester.tap(find.text('Start recording'));
    await tester.pump();

    expect(
      find.text('Camera is still opening. Try again in a moment.'),
      findsOneWidget,
    );
    expect(find.text('Recording'), findsNothing);
  });
}
