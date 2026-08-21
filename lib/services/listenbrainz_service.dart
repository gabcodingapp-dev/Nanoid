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

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nanoid/main.dart';
import 'package:nanoid/services/settings_manager.dart';

/// Scrobbles listens to ListenBrainz (https://listenbrainz.org).
///
/// ListenBrainz was chosen over Last.fm deliberately: it authenticates with a
/// single user token over HTTPS, whereas Last.fm requires an application API
/// key plus an MD5-signed session handshake, which would mean shipping a
/// shared secret inside an open-source APK where anyone can read it.
///
/// Everything here is opt-in and fails silently: a scrobble that does not land
/// must never interrupt playback.
class ListenBrainzService {
  factory ListenBrainzService() => _instance;
  ListenBrainzService._internal();
  static final ListenBrainzService _instance = ListenBrainzService._internal();

  static const String _endpoint =
      'https://api.listenbrainz.org/1/submit-listens';
  static const Duration _timeout = Duration(seconds: 12);

  /// ListenBrainz asks clients not to submit a listen until the track has been
  /// played for at least half its length, or four minutes, whichever is first.
  static const Duration _absoluteThreshold = Duration(minutes: 4);

  bool get isEnabled => listenBrainzToken.value.trim().isNotEmpty;

  /// True once [played] is far enough into a track of length [total] to count.
  bool shouldSubmit(Duration played, Duration? total) {
    if (played >= _absoluteThreshold) return true;
    if (total == null || total == Duration.zero) return false;
    return played.inMilliseconds >= total.inMilliseconds ~/ 2;
  }

  /// Marks a track as currently playing. Best-effort and non-blocking.
  Future<void> updateNowPlaying(Map song) =>
      _submit(song, listenType: 'playing_now', includeTimestamp: false);

  /// Records a completed listen.
  Future<void> submitListen(Map song) =>
      _submit(song, listenType: 'single', includeTimestamp: true);

  Future<void> _submit(
    Map song, {
    required String listenType,
    required bool includeTimestamp,
  }) async {
    if (!isEnabled) return;

    final artist = song['artist']?.toString().trim() ?? '';
    final title = song['title']?.toString().trim() ?? '';
    if (artist.isEmpty || title.isEmpty) return;

    try {
      final metadata = <String, dynamic>{
        'artist_name': artist,
        'track_name': title,
        if ((song['album']?.toString().trim() ?? '').isNotEmpty)
          'release_name': song['album'].toString().trim(),
        'additional_info': {
          'media_player': 'Nanoid',
          'submission_client': 'Nanoid',
          if (song['ytid'] != null)
            'origin_url': 'https://music.youtube.com/watch?v=${song['ytid']}',
        },
      };

      final listen = <String, dynamic>{
        if (includeTimestamp)
          'listened_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'track_metadata': metadata,
      };

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Token ${listenBrainzToken.value.trim()}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'listen_type': listenType,
              'payload': [listen],
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        logger.log(
          'ListenBrainz $listenType rejected (${response.statusCode})',
        );
      }
    } catch (e, stackTrace) {
      // Offline, bad token, rate limited - none of it should reach the user.
      logger.log('ListenBrainz submit failed', error: e, stackTrace: stackTrace);
    }
  }

  /// Verifies a token so the settings screen can give real feedback instead of
  /// silently accepting a typo.
  Future<String?> validateToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return null;
    try {
      final response = await http
          .get(
            Uri.parse('https://api.listenbrainz.org/1/validate-token'),
            headers: {'Authorization': 'Token $trimmed'},
          )
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['valid'] == true) return body['user_name']?.toString();
      return null;
    } catch (e) {
      logger.log('ListenBrainz token validation failed', error: e);
      return null;
    }
  }
}
