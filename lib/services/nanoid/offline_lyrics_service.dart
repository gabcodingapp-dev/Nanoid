import 'package:hive/hive.dart';
import '../lyrics_manager.dart';

/// Nanoid by Gab — Offline Lyrics
/// When a song is downloaded, we fetch its lyrics and cache them in Hive
/// so they can be read offline without network.
class OfflineLyricsService {
  static const String _boxName = 'offline_lyrics';
  final LyricsManager _lyricsManager = LyricsManager();

  Future<void> cacheLyricsForSong(String artist, String title) async {
    try {
      final key = _key(artist, title);
      final box = await Hive.openBox<String>(_boxName);
      if (box.containsKey(key)) return; // already cached

      final lyrics = await _lyricsManager.fetchLyrics(artist, title);
      if (lyrics != null && lyrics.trim().isNotEmpty) {
        await box.put(key, lyrics);
      }
    } catch (_) {
      // Silent fail - lyrics are optional
    }
  }

  Future<String?> getOfflineLyrics(String artist, String title) async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      return box.get(_key(artist, title));
    } catch (_) {
      return null;
    }
  }

  String _key(String artist, String title) =>
      '${artist.trim().toLowerCase()}::${title.trim().toLowerCase()}';
}
