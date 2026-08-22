/*
 *     Copyright (C) 2026 Gab Nikumura
 *
 *     Nanoid is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 */

import 'package:nanoid/services/common_services.dart';

/// Top-level lanes available in the redesigned Home feed.
enum DiscoveryFilter { all, music, podcasts, live }

class DiscoveryShelf {
  const DiscoveryShelf({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.query,
    required this.songs,
  });

  final String id;
  final String title;
  final String subtitle;
  final String query;
  final List<dynamic> songs;
}

class _ShelfSpec {
  const _ShelfSpec(this.title, this.subtitle, this.query);

  final String title;
  final String subtitle;
  final String query;
}

/// Generates an endless, bounded-cost discovery feed.
///
/// Each page performs only two searches and every query is cached by
/// [fetchSongsList]. The catalogue rotates through a large set of useful lanes;
/// after a full rotation a cycle suffix asks YouTube for a different mix rather
/// than ending the page or repeating the exact same response.
class DiscoveryFeedService {
  factory DiscoveryFeedService() => _instance;
  DiscoveryFeedService._();

  static final DiscoveryFeedService _instance = DiscoveryFeedService._();

  static const int shelvesPerPage = 2;
  static const int songsPerShelf = 12;

  static const _all = <_ShelfSpec>[
    _ShelfSpec(
      'Trending in the Philippines',
      'What listeners near you are playing now',
      'Philippines top music hits 2026',
    ),
    _ShelfSpec(
      'Fresh finds',
      'New songs worth hearing',
      'best new music releases 2026',
    ),
    _ShelfSpec(
      'OPM right now',
      'Filipino voices, bands and new favorites',
      'OPM Filipino music hits 2026',
    ),
    _ShelfSpec(
      'Your late-night soundtrack',
      'Low-key songs for after dark',
      'late night chill music mix',
    ),
    _ShelfSpec(
      'Viral hits',
      'Songs moving fast across the internet',
      'viral music hits 2026',
    ),
    _ShelfSpec(
      'Throwback favorites',
      'Big songs that still sound good',
      '2000s 2010s throwback music hits',
    ),
    _ShelfSpec(
      'Mood booster',
      'Bright tracks for a better day',
      'feel good happy music mix',
    ),
    _ShelfSpec(
      'On repeat',
      'Current songs made for replaying',
      'most replayed songs this week',
    ),
    _ShelfSpec(
      'Music conversations',
      'Interviews, stories and deep dives',
      'music podcast full episodes',
    ),
    _ShelfSpec(
      'Live and unplugged',
      'Performances with the room left in',
      'best live acoustic music performances',
    ),
    _ShelfSpec(
      'Focus flow',
      'Instrumental sound for getting things done',
      'focus instrumental music playlist',
    ),
    _ShelfSpec(
      'Weekend energy',
      'Dance, pop and party starters',
      'weekend party dance music mix',
    ),
  ];

  static const _music = <_ShelfSpec>[
    _ShelfSpec('Pop rising', 'The next wave of pop', 'new pop music hits 2026'),
    _ShelfSpec(
      'Hip-hop now',
      'New rap and essential cuts',
      'hip hop hits 2026',
    ),
    _ShelfSpec(
      'R&B rotation',
      'Smooth voices and modern soul',
      'r&b hits 2026',
    ),
    _ShelfSpec(
      'Rock this',
      'New guitars and enduring anthems',
      'rock hits 2026',
    ),
    _ShelfSpec(
      'Electronic pulse',
      'Dance-floor energy and electronic discoveries',
      'electronic dance music 2026',
    ),
    _ShelfSpec(
      'Indie radar',
      'Independent artists to know',
      'indie music 2026',
    ),
    _ShelfSpec(
      'K-pop center',
      'New releases and fan favorites',
      'kpop hits 2026',
    ),
    _ShelfSpec(
      'Acoustic calm',
      'Stripped-back songs and soft performances',
      'acoustic chill songs',
    ),
    _ShelfSpec(
      'Workout drive',
      'High-energy tracks that keep moving',
      'workout gym music mix',
    ),
    _ShelfSpec('Sleep sounds', 'A softer landing', 'sleep ambient music'),
  ];

  static const _podcasts = <_ShelfSpec>[
    _ShelfSpec(
      'Music podcasts',
      'Artist interviews, scenes and stories',
      'best music podcast full episode',
    ),
    _ShelfSpec(
      'True stories',
      'Documentaries and real-life conversations',
      'true story podcast full episode',
    ),
    _ShelfSpec(
      'Comedy podcasts',
      'Long-form laughs and conversations',
      'comedy podcast full episode',
    ),
    _ShelfSpec(
      'Technology talks',
      'Ideas shaping apps, AI and the internet',
      'technology podcast full episode 2026',
    ),
    _ShelfSpec(
      'Filipino podcasts',
      'Local voices and conversations',
      'Filipino podcast full episode',
    ),
    _ShelfSpec(
      'Learn something',
      'Science, history and useful explainers',
      'educational podcast full episode',
    ),
  ];

  static const _live = <_ShelfSpec>[
    _ShelfSpec(
      'Live sessions',
      'Close-up performances from great artists',
      'live music session full performance',
    ),
    _ShelfSpec(
      'Tiny-stage energy',
      'Intimate sets and studio concerts',
      'intimate live concert session',
    ),
    _ShelfSpec(
      'Festival stages',
      'Big crowds and full live sets',
      'music festival live full set 2026',
    ),
    _ShelfSpec(
      'Acoustic performances',
      'Songs stripped down to their core',
      'live acoustic performance playlist',
    ),
    _ShelfSpec(
      'OPM live',
      'Filipino artists on stage',
      'OPM live concert performance',
    ),
    _ShelfSpec(
      'Live radio',
      'Continuous stations and music streams',
      'live music radio stream',
    ),
  ];

  Future<List<DiscoveryShelf>> loadPage({
    required int page,
    required DiscoveryFilter filter,
    bool refresh = false,
  }) async {
    final specs = _specsFor(filter);
    final start = page * shelvesPerPage;
    final selected = <({int absoluteIndex, _ShelfSpec spec})>[
      for (var i = 0; i < shelvesPerPage; i++)
        (absoluteIndex: start + i, spec: specs[(start + i) % specs.length]),
    ];

    final shelves = await Future.wait(
      selected.map((entry) async {
        final cycle = entry.absoluteIndex ~/ specs.length;
        final query = cycle == 0
            ? entry.spec.query
            : '${entry.spec.query} mix ${cycle + 1}';
        final raw = await fetchSongsList(
          query,
          limit: songsPerShelf + 6,
          refresh: refresh,
        );
        final seen = <String>{};
        final songs = <dynamic>[];
        for (final song in raw) {
          final id = song is Map ? song['ytid']?.toString() : null;
          if (id == null || id.isEmpty || !seen.add(id)) continue;
          songs.add(song);
          if (songs.length == songsPerShelf) break;
        }
        return DiscoveryShelf(
          id: '${filter.name}-${entry.absoluteIndex}',
          title: entry.spec.title,
          subtitle: entry.spec.subtitle,
          query: query,
          songs: songs,
        );
      }),
    );

    return shelves.where((shelf) => shelf.songs.isNotEmpty).toList();
  }

  List<_ShelfSpec> _specsFor(DiscoveryFilter filter) {
    return switch (filter) {
      DiscoveryFilter.all => _all,
      DiscoveryFilter.music => _music,
      DiscoveryFilter.podcasts => _podcasts,
      DiscoveryFilter.live => _live,
    };
  }
}
