/*
 *     Copyright (C) 2026 Gab Nikumura
 *
 *     Nanoid is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 */

import 'dart:convert';

import 'package:nanoid/main.dart' show logger;
import 'package:nanoid/services/data_manager.dart';
import 'package:nanoid/services/proxy_manager.dart';

/// Read-only community rating returned by Return YouTube Dislike.
class CommunityRating {
  const CommunityRating({
    required this.videoId,
    required this.likes,
    required this.dislikes,
    required this.viewCount,
    required this.rating,
  });

  factory CommunityRating.fromJson(
    Map<String, dynamic> json, {
    String? fallbackVideoId,
  }) {
    return CommunityRating(
      videoId: json['id']?.toString() ?? fallbackVideoId ?? '',
      likes: _asInt(json['likes'] ?? json['rawLikes']),
      dislikes: _asInt(json['dislikes'] ?? json['rawDislikes']),
      viewCount: _asInt(json['viewCount']),
      rating: _asDouble(json['rating']),
    );
  }

  final String videoId;
  final int likes;
  final int dislikes;
  final int viewCount;
  final double rating;

  int get totalVotes => likes + dislikes;

  double get approvalPercent =>
      totalVotes == 0 ? 0 : (likes / totalVotes) * 100;

  Map<String, dynamic> toJson() => {
    'id': videoId,
    'likes': likes,
    'dislikes': dislikes,
    'viewCount': viewCount,
    'rating': rating,
  };

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return num.tryParse(value?.toString() ?? '')?.round() ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

/// Fetches estimated like/dislike totals without collecting or submitting votes.
///
/// Responses are cached for six hours to avoid hitting a community-funded API
/// every time the player is opened for the same song.
class ReturnYouTubeDislikeService {
  factory ReturnYouTubeDislikeService() => _instance;
  ReturnYouTubeDislikeService._();

  static final ReturnYouTubeDislikeService _instance =
      ReturnYouTubeDislikeService._();

  static const _cacheDuration = Duration(hours: 6);
  static const _requestTimeout = Duration(seconds: 8);

  Future<CommunityRating?> fetch(String videoId, {bool force = false}) async {
    final id = videoId.trim();
    if (id.isEmpty) return null;

    final cacheKey = 'ryd_$id';
    if (!force) {
      final cached = await getData(
        'cache',
        cacheKey,
        cachingDuration: _cacheDuration,
      );
      if (cached is Map) {
        return CommunityRating.fromJson(
          Map<String, dynamic>.from(cached),
          fallbackVideoId: id,
        );
      }
    }

    try {
      final response = await ProxyManager()
          .getProxiedResponse(
            Uri.https('returnyoutubedislikeapi.com', '/Votes', {'videoId': id}),
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'Nanoid/1.1 (Flutter; Android)',
            },
          )
          .timeout(_requestTimeout);
      if (response.statusCode != 200) {
        logger.log(
          'Return YouTube Dislike responded ${response.statusCode} for $id',
        );
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      final rating = CommunityRating.fromJson(
        Map<String, dynamic>.from(decoded),
        fallbackVideoId: id,
      );
      await addOrUpdateData<Map<String, dynamic>>(
        'cache',
        cacheKey,
        rating.toJson(),
      );
      return rating;
    } catch (error, stackTrace) {
      logger.log(
        'Failed to load community rating for $id',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
