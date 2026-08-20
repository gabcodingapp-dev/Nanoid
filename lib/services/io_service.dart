/*
 *     Copyright (C) 2026 Gab Nikumura (Nanoid modifications)
 *     Copyright (C) 2026 Valeri Gokadze (original work)
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
 *
 *
 *     For more information about Nanoid, including how to contribute,
 *     please visit: https://github.com/gabcodingapp-dev/Nanoid
 */

import 'dart:io';

late String applicationDirPath;

class FilePaths {
  // File extensions
  static const String audioExtension = '.m4a';
  static const String artworkExtension = '.jpg';
  static const String syncedLyricsExtension = '.lrc';
  static const String plainLyricsExtension = '.txt';

  /// Marker written when a lyrics lookup completed but found nothing, so the
  /// same track isn't queried over and over.
  static const String noLyricsExtension = '.none';

  // Directory names
  static const String tracksDir = 'tracks';
  static const String artworksDir = 'artworks';
  static const String lyricsDir = 'lyrics';

  // Get full paths for various file types
  static String getAudioPath(String songId) {
    return '$applicationDirPath/$tracksDir/$songId$audioExtension';
  }

  static String getArtworkPath(String songId) {
    return '$applicationDirPath/$artworksDir/$songId$artworkExtension';
  }

  static String getLyricsDirectory() {
    return '$applicationDirPath/$lyricsDir';
  }

  static String getSyncedLyricsPath(String songId) {
    return '$applicationDirPath/$lyricsDir/$songId$syncedLyricsExtension';
  }

  static String getPlainLyricsPath(String songId) {
    return '$applicationDirPath/$lyricsDir/$songId$plainLyricsExtension';
  }

  static String getNoLyricsMarkerPath(String songId) {
    return '$applicationDirPath/$lyricsDir/$songId$noLyricsExtension';
  }

  // Ensure directories exist
  static Future<void> ensureDirectoriesExist() async {
    final directories = [
      Directory('$applicationDirPath/$tracksDir'),
      Directory('$applicationDirPath/$artworksDir'),
      Directory('$applicationDirPath/$lyricsDir'),
    ];

    for (final directory in directories) {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }
  }
}
