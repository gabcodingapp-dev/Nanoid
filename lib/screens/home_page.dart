/*
 *     Copyright (C) 2026 Gab Nikumura (Nanoid modifications)
 *     Copyright (C) 2026 Valeri Gokadze (original work)
 *
 *     Nanoid is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 */

import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nanoid/extensions/l10n.dart';
import 'package:nanoid/main.dart';
import 'package:nanoid/services/common_services.dart';
import 'package:nanoid/services/discovery_feed_service.dart';
import 'package:nanoid/services/listening_stats_service.dart';
import 'package:nanoid/services/playlists_manager.dart';
import 'package:nanoid/services/settings_manager.dart';
import 'package:nanoid/utilities/app_utils.dart';
import 'package:nanoid/utilities/listening_stats_utils.dart';
import 'package:nanoid/widgets/announcement_box.dart';
import 'package:nanoid/widgets/listening_recap_card.dart';
import 'package:nanoid/widgets/mini_player_bottom_space.dart';
import 'package:nanoid/widgets/playlist_artwork.dart';
import 'package:nanoid/widgets/section_header.dart';
import 'package:nanoid/widgets/song_card.dart';
import 'package:nanoid/widgets/spinner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _shelfLimit = 12;
  static const double _loadMoreThreshold = 900;

  final ScrollController _scrollController = ScrollController();
  final DiscoveryFeedService _discovery = DiscoveryFeedService();

  late Future<List> _suggestedPlaylistsFuture;
  late Future<List> _recommendedSongsFuture;

  DiscoveryFilter _filter = DiscoveryFilter.all;
  final List<DiscoveryShelf> _feedShelves = [];
  int _nextFeedPage = 0;
  bool _loadingFeed = false;
  bool _feedError = false;

  @override
  void initState() {
    super.initState();
    _resetCoreFutures();
    _scrollController.addListener(_onScroll);
    externalRecommendations.addListener(_refreshRecommendedSongs);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMoreFeed());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    externalRecommendations.removeListener(_refreshRecommendedSongs);
    super.dispose();
  }

  void _resetCoreFutures() {
    _suggestedPlaylistsFuture = getPlaylists(playlistsNum: 10);
    _recommendedSongsFuture = getRecommendedSongs();
  }

  void _refreshRecommendedSongs() {
    if (!mounted) return;
    setState(() => _recommendedSongsFuture = getRecommendedSongs());
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < _loadMoreThreshold) {
      unawaited(_loadMoreFeed());
    }
  }

  Future<void> _selectFilter(DiscoveryFilter filter) async {
    if (_filter == filter) return;
    setState(() {
      _filter = filter;
      _feedShelves.clear();
      _nextFeedPage = 0;
      _feedError = false;
    });
    await _loadMoreFeed();
  }

  Future<void> _loadMoreFeed({bool refresh = false}) async {
    if (_loadingFeed || !mounted) return;
    setState(() {
      _loadingFeed = true;
      _feedError = false;
      if (refresh) {
        _feedShelves.clear();
        _nextFeedPage = 0;
      }
    });

    final page = _nextFeedPage;
    try {
      final shelves = await _discovery.loadPage(
        page: page,
        filter: _filter,
        refresh: refresh,
      );
      if (!mounted) return;
      setState(() {
        final existing = _feedShelves.map((shelf) => shelf.id).toSet();
        _feedShelves.addAll(shelves.where((shelf) => existing.add(shelf.id)));
        // Advance even when a provider returns nothing. The next page uses a
        // different query and can recover instead of retrying one dead lane.
        _nextFeedPage = page + 1;
        _feedError = shelves.isEmpty;
      });
    } catch (error, stackTrace) {
      logger.log(
        'Failed to extend Home discovery feed',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) setState(() => _feedError = true);
    } finally {
      if (mounted) {
        setState(() => _loadingFeed = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _feedError || !_scrollController.hasClients) return;
          if (_scrollController.position.extentAfter < _loadMoreThreshold) {
            unawaited(_loadMoreFeed());
          }
        });
      }
    }
  }

  Future<void> _refreshEverything() async {
    setState(_resetCoreFutures);
    await _loadMoreFeed(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showMusicHome =
        _filter == DiscoveryFilter.all || _filter == DiscoveryFilter.music;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: const Alignment(0.25, 0.42),
            colors: [
              colorScheme.primary.withValues(alpha: 0.24),
              colorScheme.surface.withValues(alpha: 0.98),
              colorScheme.surface,
            ],
            stops: const [0, 0.30, 1],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshEverything,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              _buildAppBar(context),
              _sliverBox(_buildAnnouncement()),
              _sliverBox(_buildFilterBar()),
              if (showMusicHome) _sliverBox(_buildQuickAccess()),
              _sliverBox(_buildExploreCarousel()),
              if (showMusicHome) _sliverBox(_buildQuickPicksSection()),
              if (showMusicHome) _sliverBox(_buildRecentlyPlayedSection()),
              if (showMusicHome) _sliverBox(_buildSuggestedPlaylists()),
              if (_filter == DiscoveryFilter.all)
                _sliverBox(_buildCurrentMonthRecapSection()),
              ..._feedShelves.map(
                (shelf) => _sliverBox(_buildDiscoveryShelf(shelf)),
              ),
              _sliverBox(_buildFeedFooter()),
              const SliverToBoxAdapter(child: MiniPlayerBottomSpace()),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      pinned: true,
      floating: true,
      snap: true,
      backgroundColor: colorScheme.surface.withValues(alpha: 0.94),
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Text(
            'Nanoid · your music, always moving',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: context.l10n!.search,
          onPressed: () => context.go('/search'),
          icon: const Icon(FluentIcons.search_24_regular),
        ),
        IconButton(
          tooltip: context.l10n!.settings,
          onPressed: () => context.go('/settings'),
          icon: const Icon(FluentIcons.settings_24_regular),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Still listening?';
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  SliverToBoxAdapter _sliverBox(Widget child) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: child,
      ),
    );
  }

  Widget _buildAnnouncement() {
    return ValueListenableBuilder<String?>(
      valueListenable: announcementURL,
      builder: (_, url, __) {
        if (url == null) return const SizedBox.shrink();
        final sponsorship = isSponsorshipAnnouncementUrl(url);
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AnnouncementBox(
            message: sponsorship
                ? context.l10n!.sponsorProject
                : context.l10n!.newAnnouncement,
            url: url,
            icon: sponsorship
                ? FluentIcons.heart_24_filled
                : FluentIcons.megaphone_24_filled,
            onDismiss: () async => announcementURL.value = null,
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    const filters = <(DiscoveryFilter, String)>[
      (DiscoveryFilter.all, 'All'),
      (DiscoveryFilter.music, 'Music'),
      (DiscoveryFilter.podcasts, 'Podcasts'),
      (DiscoveryFilter.live, 'Live'),
    ];

    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          return ChoiceChip(
            label: Text(item.$2),
            selected: _filter == item.$1,
            showCheckmark: false,
            onSelected: (_) => _selectFilter(item.$1),
          );
        },
      ),
    );
  }

  Widget _buildQuickAccess() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        userRecentlyPlayed,
        userLikedSongsList,
        userOfflineSongs,
        userLikedPlaylists,
      ]),
      builder: (context, _) {
        final items = <_QuickAccessItem>[
          if (userLikedSongsList.value.isNotEmpty)
            _QuickAccessItem(
              title: context.l10n!.likedSongs,
              icon: FluentIcons.heart_24_filled,
              accent: const Color(0xFF6C4DFF),
              onTap: () => context.go('/library/userSongs/liked'),
            ),
          if (userOfflineSongs.value.isNotEmpty)
            _QuickAccessItem(
              title: 'Downloads',
              icon: FluentIcons.arrow_download_24_filled,
              accent: const Color(0xFF087E8B),
              onTap: () => context.go('/library/userSongs/offline'),
            ),
          for (var i = 0; i < userRecentlyPlayed.value.take(4).length; i++)
            _QuickAccessItem(
              title:
                  userRecentlyPlayed.value[i]['title']?.toString() ?? 'Track',
              image: _imageFor(userRecentlyPlayed.value[i]),
              icon: FluentIcons.music_note_2_24_filled,
              onTap: () => audioHandler.playPlaylistSong(
                playlist: {
                  'title': context.l10n!.recentlyPlayed,
                  'list': userRecentlyPlayed.value,
                },
                songIndex: i,
              ),
            ),
          for (final playlist
              in userLikedPlaylists.value
                  .where((item) => !isArtistPlaylist(item))
                  .take(2))
            _QuickAccessItem(
              title: playlist['title']?.toString() ?? 'Playlist',
              image: playlist['image']?.toString(),
              icon: FluentIcons.text_bullet_list_24_filled,
              onTap: () => context.push(
                '/home/playlist/${Uri.encodeComponent(playlist['ytid'].toString())}',
              ),
            ),
        ].take(8).toList();

        if (items.isEmpty) return const SizedBox.shrink();
        final columns = MediaQuery.sizeOf(context).width >= 720 ? 4 : 2;
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisExtent: 62,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _QuickAccessTile(item: items[index]),
          ),
        );
      },
    );
  }

  String? _imageFor(dynamic item) {
    if (item is! Map) return null;
    return (item['artworkPath'] ??
            item['image'] ??
            item['highResImage'] ??
            item['lowResImage'])
        ?.toString();
  }

  Widget _buildExploreCarousel() {
    final items = switch (_filter) {
      DiscoveryFilter.podcasts => const [
        ('Music stories', 'music podcast full episode', 0xFF8D5CF6),
        ('Comedy', 'comedy podcast full episode', 0xFFEF476F),
        ('Technology', 'technology podcast 2026', 0xFF118AB2),
        ('Filipino', 'Filipino podcast full episode', 0xFFF78C6B),
      ],
      DiscoveryFilter.live => const [
        ('Acoustic', 'live acoustic performance', 0xFF2A9D8F),
        ('Concerts', 'full live concert', 0xFFE76F51),
        ('Festivals', 'festival live set 2026', 0xFFF4A261),
        ('OPM live', 'OPM live concert', 0xFF577590),
      ],
      _ => const [
        ('Made for you', 'personalized music mix', 0xFF6C4DFF),
        ('Charts', 'Philippines top songs 2026', 0xFFE63946),
        ('New releases', 'new music releases 2026', 0xFF118AB2),
        ('OPM', 'OPM Filipino music 2026', 0xFFF4A261),
        ('Chill', 'chill music mix', 0xFF2A9D8F),
        ('Workout', 'workout music mix', 0xFFEF476F),
      ],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Explore',
          icon: FluentIcons.compass_northwest_24_filled,
        ),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return _ExploreCard(
                title: item.$1,
                color: Color(item.$3),
                onTap: () => context.go(
                  '/search?q=${Uri.encodeQueryComponent(item.$2)}',
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildQuickPicksSection() {
    return FutureBuilder<List>(
      future: _recommendedSongsFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const [];
        if (snapshot.connectionState == ConnectionState.waiting &&
            data.isEmpty) {
          return const SizedBox(height: 220, child: Center(child: Spinner()));
        }
        if (data.isEmpty) return const SizedBox.shrink();
        final songs = data.take(_shelfLimit).toList();
        return _SongShelfSection(
          title: 'Made for you',
          subtitle: 'Based on your likes and listening',
          icon: FluentIcons.flash_24_filled,
          songs: songs,
          cardSize: 164,
          onPlay: (index) => _playShelf('Made for you', songs, index),
          onPlayAll: () => _playShelf('Made for you', songs, 0),
        );
      },
    );
  }

  Widget _buildRecentlyPlayedSection() {
    return ValueListenableBuilder<List>(
      valueListenable: userRecentlyPlayed,
      builder: (context, recent, _) {
        if (recent.isEmpty) return const SizedBox.shrink();
        final songs = recent.take(_shelfLimit).toList();
        final title = context.l10n!.recentlyPlayed;
        return _SongShelfSection(
          title: title,
          subtitle: 'Jump back into your rotation',
          icon: FluentIcons.history_24_filled,
          songs: songs,
          onPlay: (index) => _playShelf(title, songs, index),
          onPlayAll: () => _playShelf(title, songs, 0),
        );
      },
    );
  }

  Widget _buildSuggestedPlaylists() {
    return FutureBuilder<List>(
      future: _suggestedPlaylistsFuture,
      builder: (context, snapshot) {
        final playlists = snapshot.data ?? const [];
        if (playlists.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: context.l10n!.suggestedPlaylists,
              icon: FluentIcons.collections_24_filled,
            ),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: playlists.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final playlist = playlists[index] as Map;
                  return _PlaylistHomeCard(
                    playlist: playlist,
                    onTap: () => context.push(
                      '/home/playlist/${Uri.encodeComponent(playlist['ytid'].toString())}',
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDiscoveryShelf(DiscoveryShelf shelf) {
    return _SongShelfSection(
      key: ValueKey(shelf.id),
      title: shelf.title,
      subtitle: shelf.subtitle,
      icon: FluentIcons.sparkle_24_filled,
      songs: shelf.songs,
      onPlay: (index) => _playShelf(shelf.title, shelf.songs, index),
      onPlayAll: () => _playShelf(shelf.title, shelf.songs, 0),
      onExplore: () =>
          context.go('/search?q=${Uri.encodeQueryComponent(shelf.query)}'),
    );
  }

  Future<void> _playShelf(String title, List<dynamic> songs, int index) async {
    if (songs.isEmpty) return;
    await audioHandler.playPlaylistSong(
      playlist: {'title': title, 'list': songs},
      songIndex: index,
    );
  }

  Widget _buildCurrentMonthRecapSection() {
    return ValueListenableBuilder<bool>(
      valueListenable: wrappedEnabled,
      builder: (_, enabled, __) {
        if (!enabled) return const SizedBox.shrink();
        final monthKey = listeningStatsMonthKey(DateTime.now());
        final stats = listeningStatsService.monthStats(monthKey);
        final songs = listeningStatsService.monthTopSongs(monthKey);
        final minutes = monthDisplayMinutes(stats);
        if (minutes <= 0 && songs.isEmpty) return const SizedBox.shrink();

        final preview = songs.take(wrappedShareSongsLimit).toList();
        return Column(
          children: [
            SectionHeader(
              title: context.l10n!.timeMachine,
              icon: FluentIcons.data_trending_24_filled,
            ),
            ListeningRecapCard(
              periodLabel: formatMonthPeriodLabel(
                Localizations.localeOf(context),
                monthKey,
              ),
              minutes: minutes,
              songs: preview,
              onSongTap: (index) =>
                  _playShelf(context.l10n!.timeMachine, preview, index),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => context.push('/home/timeMachine'),
                  icon: const Icon(FluentIcons.arrow_right_24_regular),
                  label: Text(context.l10n!.listeningStats),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildFeedFooter() {
    if (_loadingFeed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 34),
        child: Center(child: Spinner()),
      );
    }
    if (_feedError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: FilledButton.tonalIcon(
            onPressed: _loadMoreFeed,
            icon: const Icon(FluentIcons.arrow_clockwise_24_regular),
            label: const Text('Load more'),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Keep scrolling · more music is loading',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _SongShelfSection extends StatelessWidget {
  const _SongShelfSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.songs,
    required this.onPlay,
    required this.onPlayAll,
    this.onExplore,
    this.cardSize = 148,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<dynamic> songs;
  final void Function(int index) onPlay;
  final VoidCallback onPlayAll;
  final VoidCallback? onExplore;
  final double cardSize;

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            icon: icon,
            actionButton: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onExplore != null)
                  IconButton(
                    tooltip: 'Explore $title',
                    onPressed: onExplore,
                    icon: const Icon(FluentIcons.arrow_right_24_regular),
                  ),
                IconButton.filled(
                  tooltip: 'Play $title',
                  onPressed: onPlayAll,
                  icon: const Icon(FluentIcons.play_24_filled),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Text(
              subtitle,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12.5,
              ),
            ),
          ),
          SongShelf(songs: songs, onPlay: onPlay, cardSize: cardSize),
        ],
      ),
    );
  }
}

class _QuickAccessItem {
  const _QuickAccessItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.image,
    this.accent,
  });

  final String title;
  final String? image;
  final IconData icon;
  final Color? accent;
  final VoidCallback onTap;
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({required this.item});

  final _QuickAccessItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final image = item.image;
    return Material(
      color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.86),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.onTap,
        child: Row(
          children: [
            SizedBox(
              width: 62,
              height: 62,
              child: image == null || image.isEmpty
                  ? ColoredBox(
                      color: item.accent ?? colorScheme.primaryContainer,
                      child: Icon(item.icon, color: Colors.white, size: 25),
                    )
                  : PlaylistArtwork(
                      playlistArtwork: image,
                      cubeIcon: item.icon,
                      size: 62,
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.title,
    required this.color,
    required this.onTap,
  });

  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 142,
          child: Stack(
            children: [
              Positioned(
                right: -12,
                bottom: -18,
                child: Transform.rotate(
                  angle: -0.24,
                  child: Icon(
                    FluentIcons.music_note_2_24_filled,
                    size: 74,
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(13),
                child: Text(
                  title,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistHomeCard extends StatelessWidget {
  const _PlaylistHomeCard({required this.playlist, required this.onTap});

  final Map playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 154,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PlaylistArtwork(
                playlistArtwork: playlist['image']?.toString(),
                playlistTitle: playlist['title']?.toString(),
                size: 154,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              playlist['title']?.toString() ?? 'Playlist',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
