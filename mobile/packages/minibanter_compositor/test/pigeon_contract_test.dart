import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defines the typed native capture and direct MP4 delivery contract', () {
    final contractFile = File('pigeons/compositor_api.dart');

    expect(contractFile.existsSync(), isTrue);
    final contract = contractFile.readAsStringSync();
    expect(contract, contains('class CompositorConfig'));
    expect(contract, contains('class NativeRecordingState'));
    expect(contract, contains('class RecordedCompositedVideo'));
    expect(contract, contains('abstract class CompositorHostApi'));
    expect(contract, contains('int startRecording()'));
    expect(contract, contains('int currentPresentationUs()'));
    expect(contract, contains('RecordedCompositedVideo stopRecording()'));
    expect(contract, contains('void appendCue(CompositorCue cue)'));
    expect(contract, contains('void replaceCue(CompositorCue cue)'));
    expect(contract, isNot(contains('ffmpeg')));
  });
}
