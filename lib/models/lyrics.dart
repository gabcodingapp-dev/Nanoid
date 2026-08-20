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

/// A single timestamped line of an LRC file.
class LrcLine {
  const LrcLine(this.time, this.text);

  final Duration time;
  final String text;
}

/// How a set of lyrics is stored.
enum LyricsFormat {
  /// LRC with per-line timestamps; the player can highlight in time.
  synced,

  /// Unsynchronised plain text.
  plain,
}

/// Lyrics for one track, either timed (LRC) or plain text.
///
/// [content] always holds the raw payload as fetched, so a synced result can be
/// written straight out as a `.lrc` file and re-parsed later with no loss.
class Lyrics {
  const Lyrics({
    required this.format,
    required this.content,
    required this.source,
  });

  factory Lyrics.synced(String lrc, {required String source}) =>
      Lyrics(format: LyricsFormat.synced, content: lrc, source: source);

  factory Lyrics.plain(String text, {required String source}) =>
      Lyrics(format: LyricsFormat.plain, content: text, source: source);

  final LyricsFormat format;
  final String content;

  /// Where the lyrics came from, e.g. `lrclib`.
  final String source;

  bool get isSynced => format == LyricsFormat.synced;

  bool get isEmpty => content.trim().isEmpty;

  /// Matches `[mm:ss.xx]`, `[mm:ss.xxx]` and `[mm:ss]`.
  static final RegExp _timeTag = RegExp(
    r'\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]',
  );

  /// Metadata tags such as `[ar:...]`, `[ti:...]`, `[offset:...]`.
  static final RegExp _metaTag = RegExp(r'^\[[a-zA-Z#]+:.*\]$');

  /// `[offset:+250]` / `[offset:-1200]`, in milliseconds.
  static final RegExp _offsetTag = RegExp(
    r'^\[offset:\s*([+-]?\d+)\s*\]$',
    caseSensitive: false,
  );

  /// The file's own timing correction, in milliseconds.
  ///
  /// By LRC convention a positive offset means the lyrics should appear
  /// *earlier*, so it is subtracted from each timestamp. Ignoring this tag was
  /// making some tracks drift by up to a second.
  int get embeddedOffsetMs {
    if (!isSynced) return 0;
    for (final rawLine in content.split('\n')) {
      final match = _offsetTag.firstMatch(rawLine.trim());
      if (match != null) return int.tryParse(match.group(1) ?? '') ?? 0;
    }
    return 0;
  }

  /// Parses [content] as LRC. Returns an empty list for plain lyrics.
  ///
  /// A single source line may carry several timestamps (`[00:12.00][01:40.00]`),
  /// which is legal LRC and is expanded into one entry per timestamp. Lines are
  /// returned sorted by time; blank lyric lines are preserved because they act
  /// as musical rests during playback.
  List<LrcLine> parseSynced({int extraOffsetMs = 0}) {
    if (!isSynced) return const [];

    // Combine the file's own [offset:] with any user nudge, then subtract:
    // positive offset = show earlier.
    final totalOffset = Duration(
      milliseconds: embeddedOffsetMs + extraOffsetMs,
    );

    final result = <LrcLine>[];
    for (final rawLine in content.split('\n')) {
      final line = rawLine.trimRight();
      if (line.isEmpty) continue;
      if (_metaTag.hasMatch(line.trim())) continue;

      final matches = _timeTag.allMatches(line).toList();
      if (matches.isEmpty) continue;

      final text = line.substring(matches.last.end).trim();
      for (final match in matches) {
        final minutes = int.tryParse(match.group(1) ?? '') ?? 0;
        final seconds = int.tryParse(match.group(2) ?? '') ?? 0;
        final fraction = match.group(3);
        var millis = 0;
        if (fraction != null && fraction.isNotEmpty) {
          // '5' -> 500ms, '05' -> 50ms, '050' -> 50ms
          millis = int.tryParse(fraction.padRight(3, '0').substring(0, 3)) ?? 0;
        }
        var time =
            Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: millis,
            ) -
            totalOffset;
        if (time < Duration.zero) time = Duration.zero;
        result.add(LrcLine(time, text));
      }
    }

    result.sort((a, b) => a.time.compareTo(b.time));
    return result;
  }

  /// Readable text regardless of format, with LRC timestamps stripped.
  String get plainText {
    if (!isSynced) return content;
    return parseSynced().map((line) => line.text).join('\n');
  }
}
