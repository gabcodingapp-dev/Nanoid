/*
 *     Copyright (C) 2026 Gab Nikumura
 *
 *     Nanoid is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 */

import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:nanoid/services/settings_manager.dart';

/// Nanoid Liquid Glass.
///
/// The v2 surface combines backdrop blur, a directional rim, a soft internal
/// refraction sweep and pointer-following specular light. [Listener] observes
/// the press without taking gestures away from controls inside the glass.
///
/// Inspired by the interaction quality of SimpMusic's liquid-glass surfaces,
/// independently implemented with Flutter's built-in compositor APIs.
class LiquidGlass extends StatefulWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius,
    this.blur = 30,
    this.tintOpacity = 0.10,
    this.showRim = true,
    this.padding,
    this.interactive = true,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final double blur;
  final double tintOpacity;
  final bool showRim;
  final EdgeInsetsGeometry? padding;
  final bool interactive;

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass> {
  bool _pressed = false;
  Alignment _touchAlignment = Alignment.center;

  void _updateTouch(PointerEvent event) {
    if (!widget.interactive) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || box.size.isEmpty) return;
    final local = box.globalToLocal(event.position);
    final dx = (local.dx / box.size.width) * 2 - 1;
    final dy = (local.dy / box.size.height) * 2 - 1;
    setState(() {
      _pressed = true;
      _touchAlignment = Alignment(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
    });
  }

  void _release(PointerEvent event) {
    if (_pressed && mounted) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(24);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceTint = Color.lerp(
      colorScheme.surface,
      isDark ? Colors.black : Colors.white,
      isDark ? 0.24 : 0.38,
    )!;

    final content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.blur + (_pressed ? 2 : 0),
          sigmaY: widget.blur + (_pressed ? 2 : 0),
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.17 : 0.58),
                    surfaceTint.withValues(
                      alpha: isDark
                          ? widget.tintOpacity + 0.20
                          : widget.tintOpacity + 0.35,
                    ),
                    (isDark ? Colors.black : colorScheme.primary).withValues(
                      alpha: isDark ? 0.16 : 0.055,
                    ),
                  ],
                  stops: const [0, 0.46, 1],
                ),
              ),
              child: widget.padding == null
                  ? widget.child
                  : Padding(padding: widget.padding!, child: widget.child),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _GlassLightPainter(
                    borderRadius: radius,
                    isDark: isDark,
                    showRim: widget.showRim,
                    pressed: _pressed,
                    touchAlignment: _touchAlignment,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _updateTouch,
      onPointerMove: _updateTouch,
      onPointerUp: _release,
      onPointerCancel: _release,
      child: AnimatedScale(
        scale: _pressed && widget.interactive ? 1.008 : 1,
        duration: const Duration(milliseconds: 170),
        curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
        child: content,
      ),
    );
  }
}

class _GlassLightPainter extends CustomPainter {
  const _GlassLightPainter({
    required this.borderRadius,
    required this.isDark,
    required this.showRim,
    required this.pressed,
    required this.touchAlignment,
  });

  final BorderRadius borderRadius;
  final bool isDark;
  final bool showRim;
  final bool pressed;
  final Alignment touchAlignment;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect).deflate(0.6);

    // A diagonal refraction sweep keeps the surface from reading as a flat,
    // uniformly frosted rectangle.
    final sweep = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-1, -0.85),
        end: const Alignment(1, 0.7),
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.10 : 0.20),
          Colors.transparent,
          Colors.white.withValues(alpha: isDark ? 0.035 : 0.09),
        ],
        stops: const [0, 0.48, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, sweep);

    if (pressed) {
      final glow = Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          center: touchAlignment,
          radius: 1.15,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.19 : 0.30),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect);
      canvas.drawRRect(rrect, glow);
    }

    if (showRim) {
      final rim = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.48 : 0.88),
            Colors.white.withValues(alpha: isDark ? 0.10 : 0.30),
            Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
            Colors.white.withValues(alpha: isDark ? 0.30 : 0.68),
          ],
          stops: const [0, 0.38, 0.72, 1],
        ).createShader(rect);
      canvas.drawRRect(rrect, rim);
    }
  }

  @override
  bool shouldRepaint(covariant _GlassLightPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.showRim != showRim ||
        oldDelegate.pressed != pressed ||
        oldDelegate.touchAlignment != touchAlignment ||
        oldDelegate.borderRadius != borderRadius;
  }
}

/// Wraps [child] in [LiquidGlass] only while the Beta setting is on.
class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({
    super.key,
    required this.child,
    required this.fallback,
    this.borderRadius,
    this.blur = 30,
    this.tintOpacity = 0.10,
    this.interactive = true,
  });

  final Widget child;
  final Widget Function(BuildContext context, Widget child) fallback;
  final BorderRadius? borderRadius;
  final double blur;
  final double tintOpacity;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: liquidGlassEnabled,
      builder: (context, enabled, _) {
        if (!enabled) return fallback(context, child);
        return LiquidGlass(
          borderRadius: borderRadius,
          blur: blur,
          tintOpacity: tintOpacity,
          interactive: interactive,
          child: child,
        );
      },
    );
  }
}
