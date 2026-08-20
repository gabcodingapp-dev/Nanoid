/*
 *     Copyright (C) 2026 Valeri Gokadze
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

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nanoid/constants/app_constants.dart';
import 'package:nanoid/extensions/l10n.dart';
import 'package:nanoid/main.dart';
import 'package:nanoid/services/common_services.dart';
import 'package:nanoid/services/listening_stats_service.dart';
import 'package:nanoid/services/playlists_manager.dart';
import 'package:nanoid/services/settings_manager.dart';
import 'package:nanoid/utilities/app_utils.dart';
import 'package:nanoid/utilities/async_loader.dart';
import 'package:nanoid/utilities/listening_stats_utils.dart';
import 'package:nanoid/widgets/announcement_box.dart';
import 'package:nanoid/widgets/listening_recap_card.dart';
import 'package:nanoid/widgets/mini_player_bottom_space.dart';
import 'package:nanoid/widgets/playlist_cube.dart';
import 'package:nanoid/widgets/section_header.dart';
import 'package:nanoid/widgets/song_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<List> _suggestedPlaylistsFuture;
  late Future<List> _recommendedSongsFuture;

  @override
  void initState() {
    super.initState();
    _suggestedPlaylistsFuture = getPlaylists(
      playlistsNum: recommendedCubesNumber,
    );
    _recommendedSongsFuture = getRecommendedSongs();
    externalRecommendations.addListener(_refreshRecommendedSongs);
  }

  @override
  void dispose() {
    externalRecommendations.removeListener(_refreshRecommendedSongs);
    super.dispose();
  }

  void _refreshRecommendedSongs() {
    if (!mounted) return;
    setState(() {
      _recommendedSongsFuture = getRecommendedSongs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final playlistHeight = MediaQuery.sizeOf(context).height * 0.25 / 1.1;
    return Scaffold(
      appBar: AppBar(title: const Text('Nanoid.')),
      body: SingleChildScrollView(
        padding: commonSingleChildScrollViewPadding,
        child: Column(
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: announcementURL,
              builder: (_, _url, __) {
                if (_url == null) return const SizedBox.shrink();
                final isSponsorshipAnnouncement = isSponsorshipAnnouncementUrl(
                  _url,
                );
                final _message = isSponsorshipAnnouncement
                    ? context.l10n!.sponsorProject
                    : context.l10n!.newAnnouncement;
                final _icon = isSponsorshipAnnouncement
                    ? FluentIcons.heart_24_filled
                    : FluentIcons.megaphone_24_filled;

                return AnnouncementBox(
                  message: _message,
                  url: _url,
                  icon: _icon,
                  onDismiss: () async {
                    announcementURL.value = null;
                  },
                );
              },
            ),
            _buildSuggestedPlaylists(playlistHeight),
            _buildSuggestedPlaylists(playlistHeight, showOnlyLiked: true),
            _buildRecentlyPlayedSection(),
            _buildCurrentMonthRecapSection(),
            _buildRecommendedSongsSection(),
            const MiniPlayerBottomSpace(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedPlaylists(
    double playlistHeight, {
    bool showOnlyLiked = false,
  }) {
    if (showOnlyLiked) {
      return ValueListenableBuilder<List<Map>>(
        valueListenable: userLikedPlaylists,
        builder: (_, likedPlaylists, __) => _buildSuggestedPlaylistsSection(
          playlistHeight,
          likedPlaylists
              .where((playlist) => !isArtistPlaylist(playlist))
              .take(recommendedCubesNumber)
              .toList(),
          showOnlyLiked: true,
        ),
      );
    }

    return AsyncLoader<List<dynamic>>(
      future: _suggestedPlaylistsFuture,
      builder: (context, playlists) =>
          _buildSuggestedPlaylistsSection(playlistHeight, playlists),
    );
  }

  Widget _buildSuggestedPlaylistsSection(
    double playlistHeight,
    List<dynamic> playlists, {
    bool showOnlyLiked = false,
  }) {
    if (playlists.isEmpty) return const SizedBox.shrink();

    final sectionTitle = showOnlyLiked
        ? context.l10n!.backToFavorites
        : context.l10n!.suggestedPlaylists;
    final itemsNumber = playlists.length.clamp(0, recommendedCubesNumber);
    final isLargeScreen = MediaQuery.of(context).size.width > 480;

    return Column(
      children: [
        SectionHeader(
          title: sectionTitle,
          icon: showOnlyLiked
              ? FluentIcons.heart_24_filled
              : FluentIcons.list_24_filled,
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: playlistHeight),
          child: isLargeScreen
              ? _buildHorizontalList(playlists, itemsNumber, playlistHeight)
              : _buildCarouselView(playlists, itemsNumber, playlistHeight),
        ),
      ],
    );
  }

  Widget _buildHorizontalList(
    List<dynamic> playlists,
    int itemCount,
    double height,
  ) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GestureDetector(
            onTap: () => context.push('/home/playlist/${playlist['ytid']}'),
            child: PlaylistCube(playlist, size: height),
          ),
        );
      },
    );
  }

  Widget _buildCarouselView(
    List<dynamic> playlists,
    int itemCount,
    double height,
  ) {
    return CarouselView.weighted(
      flexWeights: const <int>[3, 2, 1],
      itemSnapping: true,
      onTap: (index) =>
          context.push('/home/playlist/${playlists[index]['ytid']}'),
      children: List.generate(itemCount, (index) {
        return PlaylistCube(playlists[index], size: height * 2);
      }),
    );
  }

  /// Quick "pick up where you left off" list.
  ///
  /// Capped at [_recentlyPlayedLimit] so the home screen stays scannable; the
  /// full history already has its own page. Hidden entirely when empty so new
  /// installs don't show a dead section.
  static const int _recentlyPlayedLimit = 5;

  Widget _buildRecentlyPlayedSection() {
    return ValueListenableBuilder<List>(
      valueListenable: userRecentlyPlayed,
      builder: (context, recentlyPlayed, _) {
        if (recentlyPlayed.isEmpty) return const SizedBox.shrink();

        final songs = recentlyPlayed.length > _recentlyPlayedLimit
            ? recentlyPlayed.sublist(0, _recentlyPlayedLimit)
            : recentlyPlayed;
        final title = context.l10n!.recentlyPlayed;

        return Column(
          children: [
            SectionHeader(
              title: title,
              icon: FluentIcons.history_24_filled,
              actionButton: IconButton(
                tooltip: title,
                onPressed: () async {
                  await audioHandler.playPlaylistSong(
                    playlist: {'title': title, 'list': songs},
                    songIndex: 0,
                  );
                },
                icon: Icon(
                  FluentIcons.play_circle_24_filled,
                  color: Theme.of(context).colorScheme.primary,
                  size: 30,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final borderRadius = getItemBorderRadius(index, songs.length);
                return RepaintBoundary(
                  key: listItemKey('home_recent', index, songs[index]),
                  child: SongBar(
                    songs[index],
                    true,
                    isRecentSong: true,
                    borderRadius: borderRadius,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendedSongsSection() {
    return AsyncLoader<List<dynamic>>(
      future: _recommendedSongsFuture,
      builder: (context, data) {
        if (data.isEmpty) return const SizedBox.shrink();
        return _buildRecommendedForYouSection(context, data);
      },
    );
  }

  Widget _buildCurrentMonthRecapSection() {
    return ValueListenableBuilder<bool>(
      valueListenable: wrappedEnabled,
      builder: (_, isEnabled, __) {
        if (!isEnabled) return const SizedBox.shrink();

        final currentMonthKey = listeningStatsMonthKey(DateTime.now());
        final monthStats = listeningStatsService.monthStats(currentMonthKey);
        final songs = listeningStatsService.monthTopSongs(currentMonthKey);
        final displayMinutes = monthDisplayMinutes(monthStats);
        if (displayMinutes <= 0 && songs.isEmpty) {
          return const SizedBox.shrink();
        }

        final previewSongs = songs.take(wrappedShareSongsLimit).toList();
        final periodLabel = formatMonthPeriodLabel(
          Localizations.localeOf(context),
          currentMonthKey,
        );

        return Column(
          children: [
            SectionHeader(
              title: context.l10n!.timeMachine,
              icon: FluentIcons.data_trending_24_filled,
            ),
            ListeningRecapCard(
              periodLabel: periodLabel,
              minutes: displayMinutes,
              songs: previewSongs,
              onSongTap: (index) => _playRecapSongs(previewSongs, index),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => context.push('/home/timeMachine'),
                  icon: const Icon(FluentIcons.arrow_right_24_regular),
                  label: Text(context.l10n!.listeningStats),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _playRecapSongs(
    List<Map<String, dynamic>> songs,
    int index,
  ) async {
    if (songs.isEmpty) return;
    await audioHandler.playPlaylistSong(
      playlist: {'title': context.l10n!.timeMachine, 'list': songs},
      songIndex: index,
    );
  }

  Widget _buildRecommendedForYouSection(
    BuildContext context,
    List<dynamic> data,
  ) {
    final recommendedTitle = context.l10n!.recommendedForYou;

    return Column(
      children: [
        SectionHeader(
          title: recommendedTitle,
          icon: FluentIcons.sparkle_24_filled,
          actionButton: IconButton(
            onPressed: () async {
              await audioHandler.playPlaylistSong(
                playlist: {'title': recommendedTitle, 'list': data},
                songIndex: 0,
              );
            },
            icon: Icon(
              FluentIcons.play_circle_24_filled,
              color: Theme.of(context).colorScheme.primary,
              size: 30,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.length,
          padding: commonListViewBottomPadding,
          itemBuilder: (context, index) {
            final borderRadius = getItemBorderRadius(index, data.length);
            return RepaintBoundary(
              key: listItemKey('home_recommended', index, data[index]),
              child: SongBar(data[index], true, borderRadius: borderRadius),
            );
          },
        ),
      ],
    );
  }
}
