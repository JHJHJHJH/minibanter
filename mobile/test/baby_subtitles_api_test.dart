import 'package:minibanter/services/baby_subtitles_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates a recording session using the backend contract', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/v1/recording-sessions');
      expect(request.headers['content-type'], 'application/json');
      expect(request.body, contains('"personality":"tiny_ceo"'));
      return http.Response(
        '{"id":"session-123","status":"active","disclaimer":"Fictional subtitles for entertainment only.","personality":"tiny_ceo","language":"en","regional_style":null}',
        201,
      );
    });
    final api = BabySubtitlesApi(
      baseUrl: Uri.parse('http://localhost:8000'),
      client: client,
    );

    final session = await api.createRecordingSession(
      personality: 'tiny_ceo',
      language: 'en',
    );

    expect(session.id, 'session-123');
    expect(session.disclaimer, 'Fictional subtitles for entertainment only.');
  });

  test('uploads recorded video bytes for caption burn-in export', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/v1/recording-sessions/session-123/exports');
      expect(request.url.queryParameters['caption'], 'A fictional caption.');
      expect(request.headers['content-type'], 'video/mp4');
      expect(request.bodyBytes, [1, 2, 3]);
      return http.Response(
        '{"id":"export-123","session_id":"session-123","status":"ready","download_url":"/v1/exports/export-123"}',
        201,
      );
    });
    final api = BabySubtitlesApi(
      baseUrl: Uri.parse('http://localhost:8000'),
      client: client,
    );

    final exported = await api.exportRecording(
      sessionId: 'session-123',
      videoBytes: [1, 2, 3],
      caption: 'A fictional caption.',
    );

    expect(exported.downloadUrl, 'http://localhost:8000/v1/exports/export-123');
  });
}
