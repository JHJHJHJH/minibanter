import 'package:minibanter/widgets/camera_preview_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a safe fallback when camera access is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CameraPreviewPanel(
          loadCameras: () async => throw StateError('camera permission denied'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Camera unavailable'), findsOneWidget);
    expect(find.text('Check camera permission and try again.'), findsOneWidget);
  });

  testWidgets('fallback adapts without a layout overflow in a tiny viewport', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 1,
          height: 1,
          child: CameraPreviewPanel(
            loadCameras: () async =>
                throw StateError('camera permission denied'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
