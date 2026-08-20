/*
 *     Copyright (C) 2026 Nanoid contributors
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

import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:nanoid/services/settings_manager.dart';

/// Liquid Glass (Beta).
///
/// A translucent surface that blurs and lifts whatever sits behind it, with a
/// soft specular sheen across the top edge and a hairline rim light. Built only
/// from [BackdropFilter] and gradients, so there are no new dependencies and no
/// custom shaders to maintain.
///
/// Cost note: [BackdropFilter] forces the compositor to read back the layer
/// underneath, which is why this is opt-in and off by default. It is applied to
/// small, persistent chrome (the nav bar, the mini player) rather than to
/// scrolling content, where repeated read-backs would be expensive.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius,
    this.blur = 22,
    this.tintOpacity = 0.16,
    this.showRim = true,
    this.padding,
  });

  final Widget child;
  final BorderRadius? borderRadius;

  /// Gaussian sigma for the backdrop blur.
  final double blur;

  /// How much surface tint sits on top of the blur. Higher = more frosted.
  final double tintOpacity;

  /// Draws the hairline rim light that sells the "glass edge" read.
  final bool showRim;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Light glass picks up white; dark glass picks up the surface tint so it
    // does not turn milky grey on an OLED background.
    final sheen = isDark ? Colors.white : Colors.white;
    final base = isDark
        ? colorScheme.surface.withValues(alpha: tintOpacity + 0.18)
        : colorScheme.surface.withValues(alpha: tintOpacity + 0.42);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            // Vertical falloff: brighter at the top edge, settling into the
            // surface tint lower down. This is what reads as depth.
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                sheen.withValues(alpha: isDark ? 0.14 : 0.55),
                base,
                base,
              ],
              stops: const [0, 0.45, 1],
            ),
            border: showRim
                ? Border.all(
                    color: sheen.withValues(alpha: isDark ? 0.16 : 0.6),
                    width: 0.8,
                  )
                : null,
          ),
          child: padding == null
              ? child
              : Padding(padding: padding!, child: child),
        ),
      ),
    );
  }
}

/// Wraps [child] in [LiquidGlass] only while the Beta setting is on, and
/// rebuilds automatically when the user toggles it.
///
/// [fallback] receives the same child so callers can keep their existing opaque
/// styling when the effect is disabled.
class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({
    super.key,
    required this.child,
    required this.fallback,
    this.borderRadius,
    this.blur = 22,
    this.tintOpacity = 0.16,
  });

  final Widget child;
  final Widget Function(BuildContext context, Widget child) fallback;
  final BorderRadius? borderRadius;
  final double blur;
  final double tintOpacity;

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
          child: child,
        );
      },
    );
  }
}
