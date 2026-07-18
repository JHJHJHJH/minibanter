import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Android capture clock derives recording PTS from camera frame timestamps',
    () {
      final source = File(
        'android/src/main/kotlin/com/minibanter/minibanter_compositor/CaptureClock.kt',
      ).readAsStringSync();

      expect(source, contains('class CaptureClock'));
      expect(source, contains('fun startAt(sensorTimestampNs: Long)'));
      expect(
        source,
        contains('fun presentationUs(sensorTimestampNs: Long): Long'),
      );
      expect(source, contains('sensorTimestampNs - recordingOriginNs'));
      expect(
        source,
        contains(
          'fun encoderPresentationTimeNs(sensorTimestampNs: Long): Long',
        ),
      );
      expect(source, isNot(contains('System.currentTimeMillis')));
    },
  );
}
