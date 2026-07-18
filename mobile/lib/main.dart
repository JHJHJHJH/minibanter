import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'services/baby_subtitles_api.dart';
import 'widgets/camera_preview_panel.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

abstract interface class ExportOpener {
  Future<bool> open(Uri uri);
}

class UrlLauncherExportOpener implements ExportOpener {
  @override
  Future<bool> open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}

void main() {
  final api = BabySubtitlesApi(
    baseUrl: Uri.parse(apiBaseUrl),
    client: http.Client(),
  );
  runApp(
    BabySubtitlesApp(
      sessionGateway: api,
      exportGateway: api,
      exportOpener: UrlLauncherExportOpener(),
    ),
  );
}

class BabySubtitlesApp extends StatelessWidget {
  const BabySubtitlesApp({
    super.key,
    this.sessionGateway,
    this.exportGateway,
    this.exportOpener,
    this.cameraCapture,
  });

  final RecordingSessionGateway? sessionGateway;
  final VideoExportGateway? exportGateway;
  final ExportOpener? exportOpener;
  final CameraCapture? cameraCapture;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minibanter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B6B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: CameraExperiencePage(
        sessionGateway: sessionGateway,
        exportGateway: exportGateway,
        exportOpener: exportOpener,
        cameraCapture: cameraCapture,
      ),
    );
  }
}

class CameraExperiencePage extends StatefulWidget {
  const CameraExperiencePage({
    super.key,
    this.sessionGateway,
    this.exportGateway,
    this.exportOpener,
    this.cameraCapture,
  });

  final RecordingSessionGateway? sessionGateway;
  final VideoExportGateway? exportGateway;
  final ExportOpener? exportOpener;
  final CameraCapture? cameraCapture;

  @override
  State<CameraExperiencePage> createState() => _CameraExperiencePageState();
}

class _CameraExperiencePageState extends State<CameraExperiencePage> {
  static const _caption = 'I specifically requested the deluxe milk package.';
  static const _personalities = <String>[
    'Tiny CEO',
    'Drama Queen',
    'Sleepy Philosopher',
    'Gremlin Mode',
    'Food Critic',
    'Wholesome',
  ];

  static const _languages = <String>[
    'English',
    'Mandarin Chinese',
    'Malay',
    'Tamil',
    'Japanese',
    'Korean',
    'Spanish',
    'French',
    'German',
    'Indonesian',
    'Thai',
  ];
  static const _languageCodes = <String, String>{
    'English': 'en',
    'Mandarin Chinese': 'zh',
    'Malay': 'ms',
    'Tamil': 'ta',
    'Japanese': 'ja',
    'Korean': 'ko',
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
    'Indonesian': 'id',
    'Thai': 'th',
  };

  static const _regionalStyles = <String>[
    'No regional style',
    'Singapore English',
    'Mandarin',
    'British',
    'American',
    'Australian',
  ];
  static const _regionalStyleCodes = <String, String>{
    'Singapore English': 'singapore_english',
    'Mandarin': 'mandarin',
    'British': 'british',
    'American': 'american',
    'Australian': 'australian',
  };

  bool _isRecording = false;
  bool _isStarting = false;
  bool _isExporting = false;
  String? _errorText;
  RecordedVideo? _completedVideo;
  String? _sessionId;
  String? _exportUrl;
  CameraCapture? _cameraCapture;
  String _personality = _personalities.first;
  String _language = _languages.first;
  String _regionalStyle = _regionalStyles.first;

  @override
  void initState() {
    super.initState();
    _cameraCapture = widget.cameraCapture;
  }

  Future<void> _toggleRecording() async {
    final cameraCapture = _cameraCapture;
    if (cameraCapture == null) {
      setState(
        () => _errorText = 'Camera is still opening. Try again in a moment.',
      );
      return;
    }
    if (_isRecording) {
      setState(() => _isStarting = true);
      try {
        final video = await cameraCapture.stopVideoRecording();
        if (mounted) {
          setState(() {
            _isRecording = false;
            _completedVideo = video;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(
            () => _errorText = 'Could not finish the recording. Try again.',
          );
        }
      } finally {
        if (mounted) setState(() => _isStarting = false);
      }
      return;
    }
    setState(() {
      _isStarting = true;
      _errorText = null;
      _completedVideo = null;
      _exportUrl = null;
      _sessionId = null;
    });
    try {
      final session = await widget.sessionGateway?.createRecordingSession(
        personality: _personality.toLowerCase().replaceAll(' ', '_'),
        language: _languageCodes[_language]!,
        regionalStyle: _regionalStyleCodes[_regionalStyle],
      );
      await cameraCapture.startVideoRecording();
      if (mounted) {
        setState(() {
          _sessionId = session?.id;
          _isRecording = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorText = 'Could not start a recording session. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _exportVideo() async {
    final video = _completedVideo;
    final sessionId = _sessionId;
    final exportGateway = widget.exportGateway;
    if (video == null || sessionId == null || exportGateway == null) {
      setState(() => _errorText = 'This recording cannot be exported yet.');
      return;
    }
    setState(() {
      _isExporting = true;
      _errorText = null;
    });
    try {
      final exported = await exportGateway.exportRecording(
        sessionId: sessionId,
        videoBytes: await video.readBytes(),
        caption: _caption,
      );
      if (mounted) setState(() => _exportUrl = exported.downloadUrl);
    } catch (_) {
      if (mounted) {
        setState(() => _errorText = 'Could not export the video. Try again.');
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _openExport() async {
    final exportUrl = _exportUrl;
    final exportOpener = widget.exportOpener;
    if (exportUrl == null || exportOpener == null) {
      setState(() => _errorText = 'The exported video is not available yet.');
      return;
    }
    final didOpen = await exportOpener.open(Uri.parse(exportUrl));
    if (!didOpen && mounted) {
      setState(
        () => _errorText = 'Could not open the exported video. Try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreviewPanel(
              onCaptureReady: (capture) {
                if (mounted) setState(() => _cameraCapture ??= capture);
              },
            ),
            Positioned(
              top: 18,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  const Text(
                    'Fictional captions for entertainment only',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  if (_isRecording) const _SubtitleOverlay(text: _caption),
                ],
              ),
            ),
            Positioned(
              top: 18,
              left: 20,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Text(
                    'Minibanter',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Selector(
                          value: _personality,
                          values: _personalities,
                          onChanged: (value) =>
                              setState(() => _personality = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Selector(
                          value: _language,
                          values: _languages,
                          onChanged: (value) =>
                              setState(() => _language = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Selector(
                    value: _regionalStyle,
                    values: _regionalStyles,
                    onChanged: (value) =>
                        setState(() => _regionalStyle = value),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Semantics(
                      button: true,
                      label: _isRecording
                          ? 'Stop recording'
                          : 'Start recording',
                      child: FilledButton.icon(
                        onPressed: _isStarting ? null : _toggleRecording,
                        icon: Icon(
                          _isRecording
                              ? Icons.stop_rounded
                              : Icons.fiber_manual_record_rounded,
                        ),
                        label: Text(
                          _isRecording ? 'Stop recording' : 'Start recording',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _isRecording
                              ? colors.error
                              : colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isRecording
                        ? 'Recording'
                        : 'Ready to capture a sweet moment',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (_completedVideo != null) ...[
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _isExporting ? null : _exportVideo,
                      icon: const Icon(Icons.file_upload_outlined),
                      label: Text(_isExporting ? 'Exporting…' : 'Export video'),
                    ),
                  ],
                  if (_exportUrl != null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Export ready',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _openExport,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open exported video'),
                    ),
                  ],
                  if (_errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorText!,
                      key: const Key('recording-error'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubtitleOverlay extends StatelessWidget {
  const _SubtitleOverlay({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 180),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 25,
          height: 1.2,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(-2, -2)),
          ],
        ),
      ),
    );
  }
}

class _Selector extends StatelessWidget {
  const _Selector({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            dropdownColor: const Color(0xFF263238),
            iconEnabledColor: Colors.white,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            items: values
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (item) {
              if (item != null) onChanged(item);
            },
          ),
        ),
      ),
    );
  }
}
