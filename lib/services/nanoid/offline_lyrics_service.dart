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

import 'dart:io';

import 'package:nanoid/main.dart';
import 'package:nanoid/models/lyrics.dart';
import 'package:nanoid/services/io_service.dart';
import 'package:nanoid/services/lyrics_manager.dart';

/// Persists lyrics next to downloaded audio so they are readable with no
/// network connection.
///
/// Storage is plain files keyed by track id, mirroring how audio and artwork
/// are already stored by [FilePaths]:
///
///   * `lyrics/<id>.lrc`  - synchronised (LRC), preferred
///   * `lyrics/<id>.txt`  - plain text fallback
///   * `lyrics/<id>.none` - negative marker: we looked, there was nothing
///
/// The negative marker matters because without it every play of a track with no
/// lyrics would hit the network again. Files (rather than a database) keep the
/// `.lrc` portable and make removing a download a simple file delete.
class OfflineLyricsService {
  factory OfflineLyricsService() => _instance;
  OfflineLyricsService._internal();
  static final OfflineLyricsService _instance =
      OfflineLyricsService._internal();

  /// Upper bound on how long a download will wait for lyrics. Lyrics are a
  /// nice-to-have; they must never hold up or fail an audio download.
  static const Duration fetchBudget = Duration(seconds: 12);

  /// Reads cached lyrics for [songId]. Never touches the network.
  Future<Lyrics?> read(String songId) async {
    if (songId.isEmpty) return null;
    try {
      final syncedFile = File(FilePaths.getSyncedLyricsPath(songId));
      if (await syncedFile.exists()) {
        final content = await syncedFile.readAsString();
        if (content.trim().isNotEmpty) {
          return Lyrics.synced(content, source: 'offline');
        }
      }

      final plainFile = File(FilePaths.getPlainLyricsPath(songId));
      if (await plainFile.exists()) {
        final content = await plainFile.readAsString();
        if (content.trim().isNotEmpty) {
          return Lyrics.plain(content, source: 'offline');
        }
      }
    } catch (e, stackTrace) {
      logger.log(
        'Failed reading offline lyrics',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  /// True once a lookup has been performed for [songId], whether or not it
  /// found anything. Used to avoid repeat network calls.
  Future<bool> hasResolved(String songId) async {
    if (songId.isEmpty) return false;
    try {
      return await File(FilePaths.getSyncedLyricsPath(songId)).exists() ||
          await File(FilePaths.getPlainLyricsPath(songId)).exists() ||
          await File(FilePaths.getNoLyricsMarkerPath(songId)).exists();
    } catch (_) {
      return false;
    }
  }

  /// Fetches lyrics for a track and caches them alongside its audio.
  ///
  /// Safe to call from a download pipeline: it swallows every error, is bounded
  /// by [fetchBudget], and returns `null` instead of throwing when nothing is
  /// found, so a track with no lyrics still counts as a successful download.
  Future<Lyrics?> cacheForSong({
    required String songId,
    required String artist,
    required String title,
    String? album,
    Duration? duration,
    bool force = false,
  }) async {
    if (songId.isEmpty) return null;

    try {
      if (!force && await hasResolved(songId)) {
        return read(songId);
      }

      final lyrics = await LyricsManager()
          .fetchStructuredLyrics(
            artist: artist,
            title: title,
            album: album,
            duration: duration,
          )
          .timeout(fetchBudget, onTimeout: () => null);

      await _write(songId, lyrics);
      return lyrics;
    } catch (e, stackTrace) {
      logger.log(
        'Failed caching offline lyrics for $songId',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Deletes every lyrics artefact for [songId], so removing a download leaves
  /// nothing orphaned on disk.
  Future<void> remove(String songId) async {
    if (songId.isEmpty) return;
    for (final path in [
      FilePaths.getSyncedLyricsPath(songId),
      FilePaths.getPlainLyricsPath(songId),
      FilePaths.getNoLyricsMarkerPath(songId),
    ]) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (e) {
        logger.log('Failed deleting offline lyrics file $path', error: e);
      }
    }
  }

  Future<void> _write(String songId, Lyrics? lyrics) async {
    final directory = Directory(FilePaths.getLyricsDirectory());
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    // Clear previous state so a re-fetch can't leave both a .lrc and a stale
    // .none behind.
    await remove(songId);

    if (lyrics == null || lyrics.isEmpty) {
      await File(FilePaths.getNoLyricsMarkerPath(songId)).writeAsString('');
      return;
    }

    final path = lyrics.isSynced
        ? FilePaths.getSyncedLyricsPath(songId)
        : FilePaths.getPlainLyricsPath(songId);
    await File(path).writeAsString(lyrics.content);
  }
}
