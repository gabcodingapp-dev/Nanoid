/*
 *     Copyright (C) 2026 Gab Nikumura
 *
 *     Nanoid is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Nanoid is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// In-app splash, shown over the first frame.
///
/// The Android 12 splash exits the instant Flutter's first frame is ready,
/// which on a warm start is far too fast to perceive - that is why the native
/// animation was effectively invisible. This overlay is owned by Flutter, so it
/// is guaranteed to play for its full duration before handing over.
///
/// The animation is a single continuous gesture: the ring draws itself, the
/// spindle pops, the wordmark rises, then the whole thing lifts away.
class NanoidSplash extends StatefulWidget {
  const NanoidSplash({super.key, required this.child});

  final Widget child;

  /// Total time the mark is on screen before the hand-off begins.
  static const Duration holdDuration = Duration(milliseconds: 1150);
  static const Duration fadeDuration = Duration(milliseconds: 420);

  @override
  State<NanoidSplash> createState() => _NanoidSplashState();
}

class _NanoidSplashState extends State<NanoidSplash>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: NanoidSplash.holdDuration,
  );
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: NanoidSplash.fadeDuration,
  );

  bool _done = false;

  // Ring sweeps in first, then the spindle, then the wordmark: staggered so
  // the eye is led rather than hit with everything at once.
  late final Animation<double> _ring = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _spindle = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.40, 0.72, curve: Curves.elasticOut),
  );
  late final Animation<double> _word = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.55, 1, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _intro.forward();
    if (!mounted) return;
    await _exit.forward();
    if (!mounted) return;
    setState(() => _done = true);
  }

  @override
  void dispose() {
    _intro.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF0B0B0F) : Colors.white;
    final markColor = isDark ? Colors.white : const Color(0xFF111111);

    return Stack(
      children: [
        widget.child,
        AnimatedBuilder(
          animation: Listenable.merge([_intro, _exit]),
          builder: (context, _) {
            final exitValue = Curves.easeInCubic.transform(_exit.value);
            return IgnorePointer(
              child: Opacity(
                opacity: 1 - exitValue,
                child: Transform.scale(
                  // Lifts towards the viewer as it leaves.
                  scale: 1 + (exitValue * 0.12),
                  child: ColoredBox(
                    color: background,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 104,
                            height: 104,
                            child: CustomPaint(
                              painter: _MarkPainter(
                                progress: _ring.value,
                                spindle: _spindle.value.clamp(0.0, 1.0),
                                markColor: markColor,
                                accent: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Opacity(
                            opacity: _word.value,
                            child: Transform.translate(
                              offset: Offset(0, 12 * (1 - _word.value)),
                              child: Text(
                                'nanoid',
                                style: TextStyle(
                                  color: markColor,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Draws the Nanoid "g" progressively: bowl arc, then stem, then tail.
class _MarkPainter extends CustomPainter {
  const _MarkPainter({
    required this.progress,
    required this.spindle,
    required this.markColor,
    required this.accent,
  });

  final double progress;
  final double spindle;
  final Color markColor;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    // Geometry matches assets/branding/icon_foreground.svg (108 unit space).
    final scale = size.width / 108;
    final stroke = 8.5 * scale;
    final centre = Offset(54 * scale, 42 * scale);
    final radius = 15 * scale;

    final paint = Paint()
      ..color = markColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    // 0.0-0.7 of progress draws the bowl, 0.7-1.0 draws stem + tail.
    final bowlT = (progress / 0.7).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      2 * math.pi * bowlT,
      false,
      paint,
    );

    if (progress > 0.7) {
      final tailT = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
      final stemX = 69 * scale;
      final path = Path()..moveTo(stemX, 42 * scale);
      path.lineTo(stemX, (42 + (28 * tailT)) * scale);
      if (tailT > 0.6) {
        final hook = ((tailT - 0.6) / 0.4).clamp(0.0, 1.0);
        path.cubicTo(
          stemX,
          79 * scale,
          (69 - (8 * hook)) * scale,
          82 * scale,
          (69 - (19 * hook)) * scale,
          (70 + (8.5 * hook)) * scale,
        );
      }
      canvas.drawPath(path, paint);
    }

    if (spindle > 0) {
      canvas.drawCircle(
        centre,
        4.2 * scale * spindle,
        Paint()..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.progress != progress ||
      old.spindle != spindle ||
      old.markColor != markColor ||
      old.accent != accent;
}
