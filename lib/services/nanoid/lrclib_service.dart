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

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nanoid/main.dart';
import 'package:nanoid/models/lyrics.dart';

/// Client for LRCLIB (https://lrclib.net).
///
/// LRCLIB is an MIT-licensed, openly accessible lyrics database built for FOSS
/// music players. It needs no API key and applies no rate limiting, but asks
/// that clients identify themselves via User-Agent, which [_userAgent] does.
///
/// It is the only source here that returns genuinely synchronised (LRC) lyrics,
/// which is what lets the player highlight lines in time with playback.
class LrcLibService {
  factory LrcLibService() => _instance;
  LrcLibService._internal();
  static final LrcLibService _instance = LrcLibService._internal();

  static const String _base = 'https://lrclib.net';
  static const String _userAgent =
      'Nanoid (https://github.com/gabcodingapp-dev/Nanoid)';
  static const Duration _timeout = Duration(seconds: 10);
  static const String sourceName = 'lrclib';

  /// Timing drift past this many seconds means it is a different recording.
  static const int _maxDurationDriftSeconds = 8;

  Map<String, String> get _headers => const {'User-Agent': _userAgent};

  /// Looks up lyrics for a track.
  ///
  /// Tries the exact-match endpoint first (it uses duration to disambiguate
  /// covers and re-releases), then falls back to a fuzzy search. Returns `null`
  /// when nothing is found or the track is flagged instrumental.
  Future<Lyrics?> fetch({
    required String artist,
    required String title,
    String? album,
    Duration? duration,
  }) async {
    if (artist.trim().isEmpty || title.trim().isEmpty) return null;

    final exact = await _get(
      artist: artist,
      title: title,
      album: album,
      duration: duration,
    );
    // A synced hit is the whole point, so only stop here if we actually got
    // one. Previously a plain-text exact match short-circuited the search and
    // the user lost line highlighting for tracks that do have an LRC.
    if (exact != null && exact.isSynced) return exact;

    final searched = await _search(
      artist: artist,
      title: title,
      duration: duration,
    );
    if (searched != null && searched.isSynced) return searched;

    return exact ?? searched;
  }

  Future<Lyrics?> _get({
    required String artist,
    required String title,
    String? album,
    Duration? duration,
  }) async {
    try {
      final params = <String, String>{
        'artist_name': artist.trim(),
        'track_name': title.trim(),
        if (album != null && album.trim().isNotEmpty) 'album_name': album.trim(),
        if (duration != null && duration > Duration.zero)
          'duration': duration.inSeconds.toString(),
      };

      final uri = Uri.parse('$_base/api/get').replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic>) return null;
      return _toLyrics(body);
    } catch (e, stackTrace) {
      logger.log('LRCLIB get failed', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<Lyrics?> _search({
    required String artist,
    required String title,
    Duration? duration,
  }) async {
    try {
      final uri = Uri.parse('$_base/api/search').replace(
        queryParameters: {
          'artist_name': artist.trim(),
          'track_name': title.trim(),
        },
      );
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! List || body.isEmpty) return null;

      final candidates = body.whereType<Map<String, dynamic>>().toList()
        ..sort((a, b) => _score(a, duration).compareTo(_score(b, duration)));

      for (final candidate in candidates) {
        final lyrics = _toLyrics(candidate);
        if (lyrics != null) return lyrics;
      }
      return null;
    } catch (e, stackTrace) {
      logger.log('LRCLIB search failed', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Lower is better: prefer synced results, then the closest duration match.
  int _score(Map<String, dynamic> item, Duration? target) {
    final synced = (item['syncedLyrics'] as String?)?.trim();
    final hasSynced = synced != null && synced.isNotEmpty;
    var score = hasSynced ? 0 : 10000;

    if (target != null && target > Duration.zero) {
      final itemDuration = (item['duration'] as num?)?.round();
      if (itemDuration != null) {
        final delta = (itemDuration - target.inSeconds).abs();
        // Beyond ~8s apart it is almost certainly a different cut (live,
        // extended, radio edit) and its timings will not line up.
        score += delta > _maxDurationDriftSeconds ? 5000 + delta : delta;
      } else {
        score += 500;
      }
    }
    return score;
  }

  Lyrics? _toLyrics(Map<String, dynamic> json) {
    // An instrumental track legitimately has no lyrics; treat it as "none"
    // rather than falling through to a scraper that would invent something.
    if (json['instrumental'] == true) return null;

    final synced = (json['syncedLyrics'] as String?)?.trim();
    if (synced != null && synced.isNotEmpty) {
      return Lyrics.synced(synced, source: sourceName);
    }

    final plain = (json['plainLyrics'] as String?)?.trim();
    if (plain != null && plain.isNotEmpty) {
      return Lyrics.plain(plain, source: sourceName);
    }

    return null;
  }
}
