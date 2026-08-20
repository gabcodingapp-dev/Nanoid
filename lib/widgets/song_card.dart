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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nanoid/widgets/no_artwork_cube.dart';

/// Artwork-first song tile for the home shelves.
///
/// The old home screen was a single flat list of text rows, which gave the eye
/// nothing to land on. Leading with cover art is what makes a music library
/// feel browsable.
class SongCard extends StatelessWidget {
  const SongCard({
    super.key,
    required this.song,
    required this.onTap,
    this.size = 148,
  });

  final dynamic song;
  final VoidCallback onTap;
  final double size;

  static const double _radius = 14;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = song['title']?.toString() ?? '';
    final artist = song['artist']?.toString() ?? '';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Artwork(song: song, size: size),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (artist.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.song, required this.size});

  final dynamic song;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Downloaded tracks carry a local artwork path; everything else streams.
    final localPath = song['artworkPath']?.toString();
    if (localPath != null && localPath.isNotEmpty && File(localPath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(SongCard._radius),
        child: Image.file(
          File(localPath),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    final url = (song['highResImage'] ?? song['lowResImage'])?.toString();
    if (url == null || url.isEmpty) {
      return NullArtworkWidget(iconSize: size / 3, size: size);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(SongCard._radius),
      child: CachedNetworkImage(
        width: size,
        height: size,
        imageUrl: url,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) =>
            NullArtworkWidget(iconSize: size / 3, size: size),
      ),
    );
  }
}

/// Horizontal shelf of [SongCard]s with a section title and a play-all action.
class SongShelf extends StatelessWidget {
  const SongShelf({
    super.key,
    required this.songs,
    required this.onPlay,
    this.cardSize = 148,
  });

  final List<dynamic> songs;
  final void Function(int index) onPlay;
  final double cardSize;

  @override
  Widget build(BuildContext context) {
    // Card + title + artist. Fixed so the ListView never has to measure.
    final shelfHeight = cardSize + 52;

    return SizedBox(
      height: shelfHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        physics: const BouncingScrollPhysics(),
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => RepaintBoundary(
          child: SongCard(
            song: songs[index],
            size: cardSize,
            onTap: () => onPlay(index),
          ),
        ),
      ),
    );
  }
}
