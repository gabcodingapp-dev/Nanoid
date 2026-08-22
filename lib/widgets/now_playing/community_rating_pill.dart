/*
 *     Copyright (C) 2026 Gab Nikumura
 *
 *     Nanoid is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nanoid/services/return_youtube_dislike_service.dart';
import 'package:nanoid/services/settings_manager.dart';
import 'package:nanoid/utilities/url_launcher.dart';

/// A deliberately small, read-only community rating for Now Playing.
class CommunityRatingPill extends StatefulWidget {
  const CommunityRatingPill({super.key, required this.videoId});

  final String videoId;

  @override
  State<CommunityRatingPill> createState() => _CommunityRatingPillState();
}

class _CommunityRatingPillState extends State<CommunityRatingPill> {
  late Future<CommunityRating?> _ratingFuture;

  @override
  void initState() {
    super.initState();
    _ratingFuture = ReturnYouTubeDislikeService().fetch(widget.videoId);
  }

  @override
  void didUpdateWidget(CommunityRatingPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videoId != oldWidget.videoId) {
      _ratingFuture = ReturnYouTubeDislikeService().fetch(widget.videoId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: communityRatingsEnabled,
      builder: (context, enabled, _) {
        if (!enabled || offlineMode.value) return const SizedBox.shrink();

        return FutureBuilder<CommunityRating?>(
          future: _ratingFuture,
          builder: (context, snapshot) {
            final rating = snapshot.data;
            if (rating == null || rating.totalVotes == 0) {
              return const SizedBox.shrink();
            }

            final colorScheme = Theme.of(context).colorScheme;
            return Semantics(
              button: true,
              label:
                  '${_compact(rating.likes)} likes, ${_compact(rating.dislikes)} dislikes',
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _showDetails(context, rating),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.7,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FluentIcons.thumb_like_16_regular,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _compact(rating.likes),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        FluentIcons.thumb_dislike_16_regular,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _compact(rating.dislikes),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDetails(
    BuildContext context,
    CommunityRating rating,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Community rating',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                '${rating.approvalPercent.toStringAsFixed(1)}% positive from '
                '${_compact(rating.totalVotes)} estimated votes',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: FluentIcons.thumb_like_24_filled,
                      label: 'Likes',
                      value: _compact(rating.likes),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: FluentIcons.thumb_dislike_24_filled,
                      label: 'Dislikes',
                      value: _compact(rating.dislikes),
                    ),
                  ),
                ],
              ),
              if (rating.viewCount > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '${_compact(rating.viewCount)} video views',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Estimates provided by Return YouTube Dislike. Nanoid does not '
                'submit votes or personal data to this service.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      launchURL(Uri.parse('https://returnyoutubedislike.com/')),
                  icon: const Icon(FluentIcons.open_16_regular, size: 16),
                  label: const Text('Learn more'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _compact(int value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(value >= 10000000000 ? 0 : 1)}B';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
    }
    return '$value';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
