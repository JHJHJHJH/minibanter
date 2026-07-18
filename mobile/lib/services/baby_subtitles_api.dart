import 'dart:convert';

import 'package:http/http.dart' as http;

class RecordingSession {
  const RecordingSession({
    required this.id,
    required this.status,
    required this.disclaimer,
  });

  final String id;
  final String status;
  final String disclaimer;

  factory RecordingSession.fromJson(Map<String, dynamic> json) =>
      RecordingSession(
        id: json['id'] as String,
        status: json['status'] as String,
        disclaimer: json['disclaimer'] as String,
      );
}

class ExportedVideo {
  const ExportedVideo({
    required this.id,
    required this.status,
    required this.downloadUrl,
  });

  final String id;
  final String status;
  final String downloadUrl;

  factory ExportedVideo.fromJson(Map<String, dynamic> json, Uri baseUrl) =>
      ExportedVideo(
        id: json['id'] as String,
        status: json['status'] as String,
        downloadUrl: baseUrl.resolve(json['download_url'] as String).toString(),
      );
}

abstract interface class RecordingSessionGateway {
  Future<RecordingSession> createRecordingSession({
    required String personality,
    required String language,
    String? regionalStyle,
  });
}

abstract interface class VideoExportGateway {
  Future<ExportedVideo> exportRecording({
    required String sessionId,
    required List<int> videoBytes,
    required String caption,
  });
}

class BabySubtitlesApi implements RecordingSessionGateway, VideoExportGateway {
  BabySubtitlesApi({required this.baseUrl, required this.client});

  final Uri baseUrl;
  final http.Client client;

  @override
  Future<RecordingSession> createRecordingSession({
    required String personality,
    required String language,
    String? regionalStyle,
  }) async {
    final response = await client.post(
      baseUrl.resolve('/v1/recording-sessions'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'personality': personality,
        'language': language,
        'regional_style': regionalStyle,
      }),
    );
    if (response.statusCode != 201) {
      throw StateError(
        'Unable to create recording session (${response.statusCode}).',
      );
    }
    return RecordingSession.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<ExportedVideo> exportRecording({
    required String sessionId,
    required List<int> videoBytes,
    required String caption,
  }) async {
    final exportUri = baseUrl
        .resolve('/v1/recording-sessions/$sessionId/exports')
        .replace(queryParameters: {'caption': caption});
    final response = await client.post(
      exportUri,
      headers: const {'content-type': 'video/mp4'},
      body: videoBytes,
    );
    if (response.statusCode != 201) {
      throw StateError('Unable to export recording (${response.statusCode}).');
    }
    return ExportedVideo.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
      baseUrl,
    );
  }
}
