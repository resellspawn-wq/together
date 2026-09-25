/// A single point captured while the user's finger moves across the
/// drawing canvas. Coordinates are stored in the canvas's own logical
/// space (see [Glyph.width]/[Glyph.height]), not in screen pixels, so a
/// glyph can be replayed at any size later.
class StrokePoint {
  final double x;
  final double y;
  final int timestampMs;
  final double? pressure;

  const StrokePoint({
    required this.x,
    required this.y,
    required this.timestampMs,
    this.pressure,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        't': timestampMs,
        if (pressure != null) 'p': pressure,
      };

  factory StrokePoint.fromJson(Map<String, dynamic> json) => StrokePoint(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        timestampMs: (json['t'] as num?)?.toInt() ?? 0,
        pressure: (json['p'] as num?)?.toDouble(),
      );
}

/// One continuous finger-down-to-finger-up motion. A glyph is made of one
/// or more strokes.
class Stroke {
  final List<StrokePoint> points;

  const Stroke({required this.points});

  bool get isEmpty => points.isEmpty;

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => p.toJson()).toList(),
      };

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
        points: (json['points'] as List)
            .map((p) => StrokePoint.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}
