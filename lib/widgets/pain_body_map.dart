// lib/widgets/pain_body_map.dart
//
// Interactive front/back body silhouette for placing pain markers.
// Caregivers tap a body region, set an intensity 1-10, and the marker
// is stored as a normalized {x, y, region, view, intensity} record.
//
// Two layered CustomPainters:
//   • _BodyOutlinePainter — draws the human silhouette
//   • _PainMarkersPainter — draws the placed markers + optional heatmap
// A GestureDetector wraps the stack and converts taps into normalized
// (0..1) coordinates relative to the canvas size.
//
// All coordinates are normalized so the widget scales to any screen.

import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

// ─────────────────────────────────────────────────────────────
// PainPoint model — also used by the pain form payload.
// ─────────────────────────────────────────────────────────────

class PainPoint {
  final double x; // 0..1
  final double y; // 0..1
  final String bodyRegion;
  final String view; // 'front' | 'back'
  final int intensity; // 1..10

  const PainPoint({
    required this.x,
    required this.y,
    required this.bodyRegion,
    required this.view,
    required this.intensity,
  });

  Map<String, dynamic> toMap() => {
        'x': x,
        'y': y,
        'bodyRegion': bodyRegion,
        'view': view,
        'intensity': intensity,
      };

  factory PainPoint.fromMap(Map<String, dynamic> m) => PainPoint(
        x: (m['x'] as num?)?.toDouble() ?? 0,
        y: (m['y'] as num?)?.toDouble() ?? 0,
        bodyRegion: m['bodyRegion'] as String? ?? 'unknown',
        view: m['view'] as String? ?? 'front',
        intensity: (m['intensity'] as num?)?.toInt() ?? 5,
      );

  static Color colorForIntensity(int intensity) {
    if (intensity <= 3) return AppTheme.tileGold; // mild yellow/amber
    if (intensity <= 6) return const Color(0xFFFF9800); // moderate orange
    if (intensity <= 8) return AppTheme.statusRed; // severe red
    return const Color(0xFFB71C1C); // extreme deep red
  }

  static double radiusForIntensity(int intensity) =>
      8 + (intensity * 1.4); // 9.4 .. 22 px

  static String labelForRegion(String region) {
    return _kRegionLabels[region] ?? region;
  }
}

// Region IDs → friendly labels.
const Map<String, String> _kRegionLabels = {
  'head': 'Head',
  'neck': 'Neck',
  'leftShoulder': 'Left Shoulder',
  'rightShoulder': 'Right Shoulder',
  'chest': 'Chest',
  'upperBack': 'Upper Back',
  'abdomen': 'Abdomen',
  'lowerBack': 'Lower Back',
  'leftArm': 'Left Arm',
  'rightArm': 'Right Arm',
  'leftHip': 'Left Hip',
  'rightHip': 'Right Hip',
  'leftLeg': 'Left Leg',
  'rightLeg': 'Right Leg',
};

// ─────────────────────────────────────────────────────────────
// Region detection — given a normalized point + view, returns the
// region label. Uses simple rectangular zones layered on the silhouette.
// All Rects use 0..1 coordinate space.
// ─────────────────────────────────────────────────────────────

class _Zone {
  final String id;
  final Rect bounds; // normalized
  const _Zone(this.id, this.bounds);
}

// Front view zones (note: left/right are mirrored from the patient's
// perspective — viewer's left = patient's right, etc.)
const List<_Zone> _frontZones = [
  _Zone('head', Rect.fromLTWH(0.36, 0.02, 0.28, 0.12)),
  _Zone('neck', Rect.fromLTWH(0.42, 0.13, 0.16, 0.04)),
  _Zone('rightShoulder', Rect.fromLTWH(0.20, 0.16, 0.20, 0.08)),
  _Zone('leftShoulder', Rect.fromLTWH(0.60, 0.16, 0.20, 0.08)),
  _Zone('chest', Rect.fromLTWH(0.30, 0.18, 0.40, 0.14)),
  _Zone('rightArm', Rect.fromLTWH(0.06, 0.22, 0.18, 0.26)),
  _Zone('leftArm', Rect.fromLTWH(0.76, 0.22, 0.18, 0.26)),
  _Zone('abdomen', Rect.fromLTWH(0.30, 0.32, 0.40, 0.16)),
  _Zone('rightHip', Rect.fromLTWH(0.28, 0.46, 0.20, 0.10)),
  _Zone('leftHip', Rect.fromLTWH(0.52, 0.46, 0.20, 0.10)),
  _Zone('rightLeg', Rect.fromLTWH(0.28, 0.55, 0.21, 0.43)),
  _Zone('leftLeg', Rect.fromLTWH(0.51, 0.55, 0.21, 0.43)),
];

// Back view zones — same silhouette, different region labels.
const List<_Zone> _backZones = [
  _Zone('head', Rect.fromLTWH(0.36, 0.02, 0.28, 0.12)),
  _Zone('neck', Rect.fromLTWH(0.42, 0.13, 0.16, 0.04)),
  _Zone('leftShoulder', Rect.fromLTWH(0.20, 0.16, 0.20, 0.08)),
  _Zone('rightShoulder', Rect.fromLTWH(0.60, 0.16, 0.20, 0.08)),
  _Zone('upperBack', Rect.fromLTWH(0.30, 0.18, 0.40, 0.14)),
  _Zone('leftArm', Rect.fromLTWH(0.06, 0.22, 0.18, 0.26)),
  _Zone('rightArm', Rect.fromLTWH(0.76, 0.22, 0.18, 0.26)),
  _Zone('lowerBack', Rect.fromLTWH(0.30, 0.32, 0.40, 0.16)),
  _Zone('leftHip', Rect.fromLTWH(0.28, 0.46, 0.20, 0.10)),
  _Zone('rightHip', Rect.fromLTWH(0.52, 0.46, 0.20, 0.10)),
  _Zone('leftLeg', Rect.fromLTWH(0.28, 0.55, 0.21, 0.43)),
  _Zone('rightLeg', Rect.fromLTWH(0.51, 0.55, 0.21, 0.43)),
];

String _regionForPoint(double x, double y, String view) {
  final zones = view == 'back' ? _backZones : _frontZones;
  // Walk in reverse so smaller foreground zones win over larger ones.
  for (final z in zones.reversed) {
    if (z.bounds.contains(Offset(x, y))) return z.id;
  }
  return 'other';
}

// ─────────────────────────────────────────────────────────────
// Body outline painter — simplified human silhouette.
// ─────────────────────────────────────────────────────────────

class _BodyOutlinePainter extends CustomPainter {
  _BodyOutlinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = color.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    Offset p(double nx, double ny) => Offset(nx * w, ny * h);

    // Head
    final headRect = Rect.fromCircle(
      center: p(0.50, 0.075),
      radius: 0.06 * w,
    );
    canvas.drawOval(headRect, fill);
    canvas.drawOval(headRect, paint);

    // Neck
    final neckPath = Path()
      ..moveTo(p(0.45, 0.13).dx, p(0.45, 0.13).dy)
      ..lineTo(p(0.45, 0.17).dx, p(0.45, 0.17).dy)
      ..lineTo(p(0.55, 0.17).dx, p(0.55, 0.17).dy)
      ..lineTo(p(0.55, 0.13).dx, p(0.55, 0.13).dy);
    canvas.drawPath(neckPath, paint);

    // Torso (shoulders → waist) using a cubic for shape
    final torso = Path()
      ..moveTo(p(0.20, 0.20).dx, p(0.20, 0.20).dy) // L shoulder
      ..quadraticBezierTo(
        p(0.10, 0.34).dx, p(0.10, 0.34).dy, // ribcage curve
        p(0.27, 0.50).dx, p(0.27, 0.50).dy, // L waist
      )
      ..lineTo(p(0.73, 0.50).dx, p(0.73, 0.50).dy) // waist
      ..quadraticBezierTo(
        p(0.90, 0.34).dx, p(0.90, 0.34).dy,
        p(0.80, 0.20).dx, p(0.80, 0.20).dy, // R shoulder
      )
      ..close();
    canvas.drawPath(torso, fill);
    canvas.drawPath(torso, paint);

    // Left arm
    final lArm = Path()
      ..moveTo(p(0.20, 0.20).dx, p(0.20, 0.20).dy)
      ..quadraticBezierTo(
        p(0.10, 0.32).dx, p(0.10, 0.32).dy,
        p(0.10, 0.48).dx, p(0.10, 0.48).dy,
      )
      ..lineTo(p(0.16, 0.48).dx, p(0.16, 0.48).dy)
      ..quadraticBezierTo(
        p(0.18, 0.32).dx, p(0.18, 0.32).dy,
        p(0.27, 0.22).dx, p(0.27, 0.22).dy,
      )
      ..close();
    canvas.drawPath(lArm, fill);
    canvas.drawPath(lArm, paint);

    // Right arm (mirror)
    final rArm = Path()
      ..moveTo(p(0.80, 0.20).dx, p(0.80, 0.20).dy)
      ..quadraticBezierTo(
        p(0.90, 0.32).dx, p(0.90, 0.32).dy,
        p(0.90, 0.48).dx, p(0.90, 0.48).dy,
      )
      ..lineTo(p(0.84, 0.48).dx, p(0.84, 0.48).dy)
      ..quadraticBezierTo(
        p(0.82, 0.32).dx, p(0.82, 0.32).dy,
        p(0.73, 0.22).dx, p(0.73, 0.22).dy,
      )
      ..close();
    canvas.drawPath(rArm, fill);
    canvas.drawPath(rArm, paint);

    // Hands (simple ovals)
    canvas.drawOval(
        Rect.fromCircle(center: p(0.13, 0.51), radius: 0.04 * w), paint);
    canvas.drawOval(
        Rect.fromCircle(center: p(0.87, 0.51), radius: 0.04 * w), paint);

    // Hips → legs
    final hipsTopY = 0.50;
    final crotchY = 0.58;
    final kneesY = 0.78;
    final ankleY = 0.97;

    // Left leg
    final lLeg = Path()
      ..moveTo(p(0.27, hipsTopY).dx, p(0.27, hipsTopY).dy)
      ..lineTo(p(0.30, ankleY).dx, p(0.30, ankleY).dy)
      ..lineTo(p(0.46, ankleY).dx, p(0.46, ankleY).dy)
      ..lineTo(p(0.48, crotchY).dx, p(0.48, crotchY).dy)
      ..close();
    canvas.drawPath(lLeg, fill);
    canvas.drawPath(lLeg, paint);

    // Right leg
    final rLeg = Path()
      ..moveTo(p(0.73, hipsTopY).dx, p(0.73, hipsTopY).dy)
      ..lineTo(p(0.70, ankleY).dx, p(0.70, ankleY).dy)
      ..lineTo(p(0.54, ankleY).dx, p(0.54, ankleY).dy)
      ..lineTo(p(0.52, crotchY).dx, p(0.52, crotchY).dy)
      ..close();
    canvas.drawPath(rLeg, fill);
    canvas.drawPath(rLeg, paint);

    // Knee marks (small horizontal ticks)
    canvas.drawLine(p(0.32, kneesY), p(0.42, kneesY),
        paint..strokeWidth = 1);
    canvas.drawLine(p(0.58, kneesY), p(0.68, kneesY), paint);

    // Feet (small horizontal ovals)
    canvas.drawOval(
        Rect.fromLTWH(0.27 * w, ankleY * h, 0.13 * w, 0.025 * h), paint);
    canvas.drawOval(
        Rect.fromLTWH(0.60 * w, ankleY * h, 0.13 * w, 0.025 * h), paint);
  }

  @override
  bool shouldRepaint(covariant _BodyOutlinePainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─────────────────────────────────────────────────────────────
// Marker / heatmap painter
// ─────────────────────────────────────────────────────────────

class _PainMarkersPainter extends CustomPainter {
  _PainMarkersPainter({
    required this.points,
    required this.heatmap,
    required this.heatmapMode,
  });

  final List<PainPoint> points;
  final List<PainPoint> heatmap;
  final bool heatmapMode;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Heatmap layer first (semi-transparent dots). Blur is GPU-expensive,
    // so we only apply it when intensity ≥ 4 and only at a moderate radius.
    // Mild markers render as flat translucent dots — visually similar but
    // 5-10x cheaper to paint on low-end GPUs.
    if (heatmap.isNotEmpty) {
      for (final p in heatmap) {
        final color =
            PainPoint.colorForIntensity(p.intensity).withValues(alpha: 0.18);
        final radius = PainPoint.radiusForIntensity(p.intensity) * 1.6;
        final paint = Paint()..color = color;
        if (p.intensity >= 4) {
          paint.maskFilter = MaskFilter.blur(
              BlurStyle.normal, p.intensity >= 7 ? 5 : 3);
        }
        canvas.drawCircle(Offset(p.x * w, p.y * h), radius, paint);
      }
    }

    // Foreground markers
    if (!heatmapMode) {
      for (final p in points) {
        final color = PainPoint.colorForIntensity(p.intensity);
        final radius = PainPoint.radiusForIntensity(p.intensity);
        final fill = Paint()..color = color;
        final ring = Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        final center = Offset(p.x * w, p.y * h);
        canvas.drawCircle(center, radius, fill);
        canvas.drawCircle(center, radius, ring);
        // Number inside
        final tp = TextPainter(
          text: TextSpan(
            text: '${p.intensity}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PainMarkersPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.heatmap != heatmap ||
      oldDelegate.heatmapMode != heatmapMode;
}

// ─────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────

class PainBodyMap extends StatefulWidget {
  const PainBodyMap({
    super.key,
    this.initialPoints = const [],
    this.heatmapPoints = const [],
    this.readOnly = false,
    this.onChanged,
    this.height = 380,
  });

  final List<PainPoint> initialPoints;
  final List<PainPoint> heatmapPoints;
  final bool readOnly;
  final ValueChanged<List<PainPoint>>? onChanged;
  final double height;

  @override
  State<PainBodyMap> createState() => _PainBodyMapState();
}

class _PainBodyMapState extends State<PainBodyMap> {
  late List<PainPoint> _points;
  String _view = 'front'; // 'front' | 'back'

  // Cached filtered lists. Recomputed only when _points or _view change,
  // not on every parent rebuild — keeps `shouldRepaint` reference checks
  // honest so the painter doesn't redo expensive blur work each frame.
  late List<PainPoint> _cachedVisiblePoints;
  late List<PainPoint> _cachedVisibleHeatmap;

  @override
  void initState() {
    super.initState();
    _points = [...widget.initialPoints];
    _recomputeCaches();
  }

  void _recomputeCaches() {
    _cachedVisiblePoints =
        List.unmodifiable(_points.where((p) => p.view == _view));
    _cachedVisibleHeatmap = List.unmodifiable(
        widget.heatmapPoints.where((p) => p.view == _view));
  }

  @override
  void didUpdateWidget(covariant PainBodyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    var dirty = false;
    if (oldWidget.initialPoints != widget.initialPoints &&
        widget.initialPoints.isNotEmpty &&
        _points.isEmpty) {
      _points = [...widget.initialPoints];
      dirty = true;
    }
    if (oldWidget.heatmapPoints != widget.heatmapPoints) dirty = true;
    if (dirty) _recomputeCaches();
  }

  List<PainPoint> get _visiblePoints => _cachedVisiblePoints;

  List<PainPoint> get _visibleHeatmap => _cachedVisibleHeatmap;

  void _emit() => widget.onChanged?.call(_points);

  Future<void> _onTap(Offset localPos, Size canvasSize) async {
    if (widget.readOnly) return;
    final nx = (localPos.dx / canvasSize.width).clamp(0.0, 1.0);
    final ny = (localPos.dy / canvasSize.height).clamp(0.0, 1.0);

    // Did they tap an existing marker? (within ~22px radius)
    PainPoint? hit;
    for (final p in _visiblePoints) {
      final dx = (p.x - nx) * canvasSize.width;
      final dy = (p.y - ny) * canvasSize.height;
      if (sqrt(dx * dx + dy * dy) <= 24) {
        hit = p;
        break;
      }
    }

    if (hit != null) {
      final action = await _showEditSheet(hit);
      if (action == _MarkerAction.delete) {
        setState(() {
          _points.remove(hit);
          _recomputeCaches();
        });
        _emit();
      }
      return;
    }

    final region = _regionForPoint(nx, ny, _view);
    if (region == 'other') {
      // Tapped outside the silhouette — ignore softly.
      return;
    }
    final intensity = await _showIntensityPicker(initial: 5, region: region);
    if (intensity == null) return;
    setState(() {
      _points.add(PainPoint(
        x: nx,
        y: ny,
        bodyRegion: region,
        view: _view,
        intensity: intensity,
      ));
      _recomputeCaches();
    });
    HapticUtils.warning();
    _emit();
  }

  Future<int?> _showIntensityPicker({
    required int initial,
    required String region,
  }) async {
    int value = initial;
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  PainPoint.labelForRegion(region),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text('Pain intensity (1–10)',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ),
                const SizedBox(height: 12),
                _IntensityRow(
                  value: value,
                  onChanged: (v) => setSheet(() => value = v),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(value),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        PainPoint.colorForIntensity(value),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Place marker · $value/10'),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<_MarkerAction?> _showEditSheet(PainPoint hit) async {
    return showModalBottomSheet<_MarkerAction>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PainPoint.colorForIntensity(hit.intensity),
                  shape: BoxShape.circle,
                ),
                child: Text('${hit.intensity}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800)),
              ),
              title: Text(PainPoint.labelForRegion(hit.bodyRegion),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Intensity ${hit.intensity}/10'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: AppTheme.dangerColor),
              title: const Text('Remove marker',
                  style: TextStyle(color: AppTheme.dangerColor)),
              onTap: () => Navigator.of(ctx).pop(_MarkerAction.delete),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Front/back toggle
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'front', label: Text('Front')),
            ButtonSegment(value: 'back', label: Text('Back')),
          ],
          selected: {_view},
          onSelectionChanged: (s) => setState(() {
            _view = s.first;
            _recomputeCaches();
          }),
        ),
        const SizedBox(height: 8),
        // Canvas
        SizedBox(
          height: widget.height,
          child: Center(
            child: AspectRatio(
              aspectRatio: 0.55,
              child: LayoutBuilder(builder: (ctx, c) {
                final canvasSize = Size(c.maxWidth, c.maxHeight);
                return GestureDetector(
                  onTapDown: (d) => _onTap(d.localPosition, canvasSize),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                          color: Colors.grey.shade300, width: 1.5),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter:
                              _BodyOutlinePainter(color: Colors.grey.shade700),
                          size: canvasSize,
                        ),
                        CustomPaint(
                          painter: _PainMarkersPainter(
                            points: _visiblePoints,
                            heatmap: _visibleHeatmap,
                            heatmapMode: widget.readOnly,
                          ),
                          size: canvasSize,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            widget.readOnly
                ? 'Heatmap shows pain frequency · brighter = more recent'
                : 'Tap the body to mark pain · tap a marker to remove',
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}

enum _MarkerAction { delete }

// ─────────────────────────────────────────────────────────────
// Intensity selector row (1..10 colored chips)
// ─────────────────────────────────────────────────────────────

class _IntensityRow extends StatelessWidget {
  const _IntensityRow({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: List.generate(10, (i) {
        final n = i + 1;
        final selected = n == value;
        final color = PainPoint.colorForIntensity(n);
        return GestureDetector(
          onTap: () => onChanged(n),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? color : color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.black87 : color,
                width: selected ? 2 : 1,
              ),
            ),
            child: Text('$n',
                style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                )),
          ),
        );
      }),
    );
  }
}
