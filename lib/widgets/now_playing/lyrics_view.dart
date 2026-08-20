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

import 'package:material_ui/material_ui.dart';
import 'package:nanoid/main.dart';
import 'package:nanoid/models/lyrics.dart';
import 'package:nanoid/models/position_data.dart';

/// Renders lyrics for the now-playing card.
///
/// Synced (LRC) lyrics highlight the current line and auto-scroll it into view;
/// plain lyrics fall back to the previous static, centred layout.
class LyricsView extends StatelessWidget {
  const LyricsView({super.key, required this.lyrics, required this.textColor});

  final Lyrics lyrics;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    if (!lyrics.isSynced) {
      return _PlainLyrics(text: lyrics.content, textColor: textColor);
    }

    final lines = lyrics.parseSynced();
    if (lines.isEmpty) {
      // Malformed LRC - degrade to whatever readable text we can recover.
      return _PlainLyrics(text: lyrics.plainText, textColor: textColor);
    }

    return _SyncedLyrics(lines: lines, textColor: textColor);
  }
}

class _PlainLyrics extends StatelessWidget {
  const _PlainLyrics({required this.text, required this.textColor});

  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textColor,
          height: 1.6,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SyncedLyrics extends StatefulWidget {
  const _SyncedLyrics({required this.lines, required this.textColor});

  final List<LrcLine> lines;
  final Color textColor;

  @override
  State<_SyncedLyrics> createState() => _SyncedLyricsState();
}

class _SyncedLyricsState extends State<_SyncedLyrics> {
  static const double _lineExtent = 46;
  static const Duration _scrollDuration = Duration(milliseconds: 320);

  final ScrollController _controller = ScrollController();
  int _activeIndex = -1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Index of the last line whose timestamp has passed, or -1 before the first.
  ///
  /// Binary search keeps this cheap: the position stream ticks frequently and a
  /// long song can carry a few hundred lines.
  int _indexFor(Duration position) {
    final lines = widget.lines;
    var low = 0;
    var high = lines.length - 1;
    var found = -1;

    while (low <= high) {
      final mid = (low + high) >> 1;
      if (lines[mid].time <= position) {
        found = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return found;
  }

  void _centreOn(int index) {
    if (!_controller.hasClients || index < 0) return;

    final viewport = _controller.position.viewportDimension;
    final target = (index * _lineExtent) - (viewport / 2) + (_lineExtent / 2);
    final clamped = target.clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );

    _controller.animateTo(
      clamped,
      duration: _scrollDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PositionData>(
      stream: audioHandler.positionDataStream,
      builder: (context, snapshot) {
        final position = snapshot.data?.position ?? Duration.zero;
        final index = _indexFor(position);

        if (index != _activeIndex) {
          _activeIndex = index;
          WidgetsBinding.instance.addPostFrameCallback((_) => _centreOn(index));
        }

        return ListView.builder(
          controller: _controller,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          physics: const BouncingScrollPhysics(),
          itemCount: widget.lines.length,
          itemExtent: _lineExtent,
          itemBuilder: (context, i) {
            final isActive = i == index;
            final line = widget.lines[i].text;

            return Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: isActive ? 20 : 17,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: widget.textColor.withValues(
                    alpha: isActive ? 1 : 0.45,
                  ),
                  height: 1.3,
                ),
                child: Text(
                  // Instrumental breaks come through as empty LRC lines.
                  line.isEmpty ? '♪' : line,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
