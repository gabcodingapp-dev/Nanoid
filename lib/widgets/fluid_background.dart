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
import 'package:nanoid/services/fluid_motion_service.dart';
import 'package:nanoid/services/settings_manager.dart';

/// The moving backdrop behind the exclusive Fluid theme.
///
/// Four soft radial blobs drift on independent low-frequency orbits. Because
/// the theme is strictly monochrome the blobs are plain white (or black on a
/// light background) at low alpha, so they read as light pooling behind the UI
/// rather than as coloured shapes.
///
/// Two Beta modulations can ride on top:
///   * Fluid Motion - the whole field leans with the device tilt
///   * Fluid Rhythm - the blobs swell on each estimated beat
class FluidBackground extends StatefulWidget {
  const FluidBackground({super.key, this.intensity = 1});

  /// Scales overall opacity, so the same widget works as a full-screen
  /// backdrop or as a subtle wash behind a card.
  final double intensity;

  @override
  State<FluidBackground> createState() => _FluidBackgroundState();
}

class _FluidBackgroundState extends State<FluidBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    // One very slow cycle; the blobs use different multiples of it so the
    // field never visibly repeats.
    duration: const Duration(seconds: 32),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final motion = FluidMotionService();

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return ValueListenableBuilder<Offset>(
            valueListenable: motion.tilt,
            builder: (context, tilt, __) {
              return ValueListenableBuilder<double>(
                valueListenable: motion.beat,
                builder: (context, beat, ___) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _FluidPainter(
                      t: _controller.value,
                      tilt: fluidGyroEnabled.value ? tilt : Offset.zero,
                      beat: fluidRhythmEnabled.value ? beat : 0,
                      isDark: isDark,
                      intensity: widget.intensity,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _Blob {
  const _Blob(this.cx, this.cy, this.radius, this.speed, this.phase);

  /// Orbit centre as a fraction of the canvas.
  final double cx;
  final double cy;

  /// Radius as a fraction of the shortest canvas side.
  final double radius;

  /// Orbit speed multiplier relative to the driving controller.
  final double speed;
  final double phase;
}

class _FluidPainter extends CustomPainter {
  const _FluidPainter({
    required this.t,
    required this.tilt,
    required this.beat,
    required this.isDark,
    required this.intensity,
  });

  final double t;
  final Offset tilt;
  final double beat;
  final bool isDark;
  final double intensity;

  static const List<_Blob> _blobs = [
    _Blob(0.24, 0.20, 0.62, 1, 0),
    _Blob(0.78, 0.32, 0.52, 0.7, 1.30),
    _Blob(0.38, 0.78, 0.58, 0.85, 2.60),
    _Blob(0.86, 0.86, 0.44, 1.25, 4.10),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    // Beat swells the blobs; tilt slides the whole field.
    final swell = 1 + (beat * 0.16);
    final leanX = -tilt.dx * size.width * 0.06;
    final leanY = tilt.dy * size.height * 0.04;

    final blobColor = isDark ? Colors.white : Colors.black;
    final baseAlpha = (isDark ? 0.085 : 0.055) * intensity;

    for (final blob in _blobs) {
      final angle = (t * blob.speed * 2 * math.pi) + blob.phase;
      final driftX = math.cos(angle) * size.width * 0.10;
      final driftY = math.sin(angle * 0.8) * size.height * 0.07;

      final centre = Offset(
        (blob.cx * size.width) + driftX + leanX,
        (blob.cy * size.height) + driftY + leanY,
      );
      final radius = blob.radius * shortest * swell;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            blobColor.withValues(alpha: baseAlpha + (beat * 0.05)),
            blobColor.withValues(alpha: 0),
          ],
          stops: const [0, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: radius));

      canvas.drawCircle(centre, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_FluidPainter old) =>
      old.t != t ||
      old.tilt != tilt ||
      old.beat != beat ||
      old.isDark != isDark ||
      old.intensity != intensity;
}
