import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minibanter/features/recording/native_compositor_gateway.dart';
import 'package:minibanter/features/recording/recording_controller.dart';
import 'package:minibanter/main.dart';
import 'package:minibanter/services/baby_subtitles_api.dart';

class FakeSessionGateway implements RecordingSessionGateway {
  @override
  Future<RecordingSession> createRecordingSession({
    required String personality,
    required String language,
    String? regionalStyle,
  }) async => const RecordingSession(
    id: 'session-native',
    status: 'active',
    disclaimer: 'Fictional subtitles for entertainment only.',
  );
}

class FakeNativeCompositor implements NativeCompositorGateway {
  bool prepared = false;
  bool started = false;
  bool stopped = false;
  final List<NativeOverlayCue> cues = [];

  @override
  Future<void> prepare(NativeCompositorConfig config) async => prepared = true;

  @override
  Future<int> startRecording() async {
    started = true;
    return 0;
  }

  @override
  Future<int> currentRecordingPresentationUs() async => 1000000;

  @override
  Future<void> appendCue(NativeOverlayCue cue) async => cues.add(cue);

  @override
  Future<void> replaceCue(NativeOverlayCue cue) async => cues.add(cue);

  @override
  Future<NativeCompositedVideo> stopRecording() async {
    stopped = true;
    return const NativeCompositedVideo(
      localPath: '/tmp/composited.mp4',
      durationUs: 2000000,
      timelineJson: '{"version":1,"cues":[]}',
    );
  }

  @override
  Future<void> dispose() async {}
}

class DelayedPrepareNativeCompositor extends FakeNativeCompositor {
  final Completer<void> prepareCompleter = Completer<void>();

  @override
  Future<void> prepare(NativeCompositorConfig config) =>
      prepareCompleter.future;
}

void main() {
  testWidgets('does not enable native recording until capture is prepared', (
    tester,
  ) async {
    final compositor = DelayedPrepareNativeCompositor();
    final controller = RecordingController(compositor: compositor);

    await tester.pumpWidget(
      BabySubtitlesApp(
        sessionGateway: FakeSessionGateway(),
        nativeRecordingController: controller,
      ),
    );
    await tester.pump();

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    compositor.prepareCompleter.complete();
    await tester.pump();
    await tester.pump();

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('uses the native compositor capture clock when injected', (
    tester,
  ) async {
    final compositor = FakeNativeCompositor();
    final controller = RecordingController(compositor: compositor);

    await tester.pumpWidget(
      BabySubtitlesApp(
        sessionGateway: FakeSessionGateway(),
        nativeRecordingController: controller,
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Start recording'));
    await tester.pump();

    expect(compositor.prepared, isTrue);
    expect(compositor.started, isTrue);
    expect(compositor.cues.single.startUs, 1200000);
    expect(
      find.text('I specifically requested the deluxe milk package.'),
      findsNothing,
      reason:
          'The native compositor, not a Flutter overlay, owns burned captions.',
    );

    await tester.tap(find.text('Stop recording'));
    await tester.pump();

    expect(compositor.stopped, isTrue);
    expect(find.text('Native video ready to export'), findsOneWidget);
    expect(find.text('Export video'), findsOneWidget);
  });
}
