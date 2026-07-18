enum OverlayKind { caption, sticker }

class OverlayTransform {
  OverlayTransform({
    required this.x,
    required this.y,
    this.scale = 1,
    this.rotationDegrees = 0,
  }) {
    if (x < 0 || x > 1 || y < 0 || y > 1) {
      throw ArgumentError.value(
        '$x, $y',
        'position',
        'Overlay coordinates must be normalized between 0 and 1.',
      );
    }
    if (scale <= 0) {
      throw ArgumentError.value(scale, 'scale', 'Scale must be positive.');
    }
  }

  final double x;
  final double y;
  final double scale;
  final double rotationDegrees;
}

class OverlayStyle {
  const OverlayStyle({required this.template, this.fontScale = 1});

  final String template;
  final double fontScale;
}

class OverlayCue {
  OverlayCue.caption({
    required this.id,
    required String text,
    required this.startUs,
    required this.endUs,
    required this.transform,
    required this.style,
    this.zIndex = 0,
  }) : kind = OverlayKind.caption,
       text = text.trim() {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Cue ID cannot be empty.');
    }
    if (this.text!.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Caption text cannot be empty.');
    }
    _validateTimes(startUs, endUs);
  }

  final String id;
  final OverlayKind kind;
  final String? text;
  final int startUs;
  final int endUs;
  final int zIndex;
  final OverlayTransform transform;
  final OverlayStyle style;

  bool isActiveAt(int presentationUs) =>
      startUs <= presentationUs && presentationUs < endUs;

  static void _validateTimes(int startUs, int endUs) {
    if (startUs < 0 || endUs <= startUs) {
      throw ArgumentError.value(
        '$startUs-$endUs',
        'timeRange',
        'Cue time range must be non-negative with a positive duration.',
      );
    }
  }
}

class OverlayTimeline {
  OverlayTimeline(Iterable<OverlayCue> cues) : _cues = List.unmodifiable(cues);

  final List<OverlayCue> _cues;

  List<OverlayCue> get cues => _cues;

  List<OverlayCue> activeAt(int presentationUs) {
    final active = _cues
        .where((cue) => cue.isActiveAt(presentationUs))
        .toList(growable: false);
    active.sort((left, right) {
      final zOrder = left.zIndex.compareTo(right.zIndex);
      return zOrder != 0 ? zOrder : left.id.compareTo(right.id);
    });
    return active;
  }

  OverlayTimeline replace(OverlayCue replacement) {
    final index = _cues.indexWhere((cue) => cue.id == replacement.id);
    if (index == -1) {
      return OverlayTimeline([..._cues, replacement]);
    }
    return OverlayTimeline([
      for (var i = 0; i < _cues.length; i++)
        if (i == index) replacement else _cues[i],
    ]);
  }
}
