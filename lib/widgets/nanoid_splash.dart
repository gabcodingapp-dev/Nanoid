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
                          Transform.rotate(
                            // A slow unwind into place; the mark is a swirl,
                            // so rotation is the motion it already implies.
                            angle: (1 - _ring.value) * 0.9,
                            child: Transform.scale(
                              scale: 0.72 + (0.28 * _spindle.value.clamp(0.0, 1.0)),
                              child: Opacity(
                                opacity: _ring.value,
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    markColor,
                                    BlendMode.srcIn,
                                  ),
                                  child: Image.asset(
                                    'assets/branding/nanoid_mark.png',
                                    width: 118,
                                    height: 118,
                                    filterQuality: FilterQuality.medium,
                                  ),
                                ),
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
