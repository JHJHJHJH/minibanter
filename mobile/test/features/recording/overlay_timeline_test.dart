import 'package:flutter_test/flutter_test.dart';
import 'package:minibanter/features/recording/overlay_timeline.dart';

OverlayCue captionCue({
  required String id,
  required int startUs,
  required int endUs,
  int zIndex = 0,
}) {
  return OverlayCue.caption(
    id: id,
    text: 'Fictional caption $id',
    startUs: startUs,
    endUs: endUs,
    zIndex: zIndex,
    transform: OverlayTransform(x: 0.5, y: 0.83),
    style: const OverlayStyle(template: 'lower_third_v1'),
  );
}

void main() {
  test('a cue is active at its start and inactive at its end', () {
    final timeline = OverlayTimeline([
      captionCue(id: 'cue-1', startUs: 1000000, endUs: 3000000),
    ]);

    expect(timeline.activeAt(999999), isEmpty);
    expect(timeline.activeAt(1000000), hasLength(1));
    expect(timeline.activeAt(2999999), hasLength(1));
    expect(timeline.activeAt(3000000), isEmpty);
  });

  test('active cues are returned in stable z-order', () {
    final timeline = OverlayTimeline([
      captionCue(id: 'later', startUs: 0, endUs: 5000000, zIndex: 2),
      captionCue(id: 'first', startUs: 0, endUs: 5000000, zIndex: 1),
      captionCue(id: 'second', startUs: 0, endUs: 5000000, zIndex: 1),
    ]);

    expect(timeline.activeAt(1000000).map((cue) => cue.id), [
      'first',
      'second',
      'later',
    ]);
  });

  test('replacement swaps a cue without changing unrelated cues', () {
    final original = captionCue(id: 'cue-1', startUs: 0, endUs: 1000000);
    final replacement = captionCue(
      id: 'cue-1',
      startUs: 2000000,
      endUs: 3000000,
    );
    final unaffected = captionCue(id: 'cue-2', startUs: 0, endUs: 4000000);

    final timeline = OverlayTimeline([
      original,
      unaffected,
    ]).replace(replacement);

    expect(timeline.activeAt(500000).map((cue) => cue.id), ['cue-2']);
    expect(timeline.activeAt(2500000).map((cue) => cue.id), ['cue-1', 'cue-2']);
  });

  test('invalid cue times and transforms are rejected', () {
    expect(
      () => captionCue(id: 'invalid', startUs: 100, endUs: 100),
      throwsArgumentError,
    );
    expect(() => OverlayTransform(x: 1.1, y: 0.5), throwsArgumentError);
  });
}
