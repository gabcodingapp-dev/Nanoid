import 'package:flutter_test/flutter_test.dart';
import 'package:nanoid/models/lyrics.dart';
import 'package:nanoid/services/return_youtube_dislike_service.dart';

void main() {
  group('CommunityRating', () {
    test('parses numeric API fields and computes approval', () {
      final rating = CommunityRating.fromJson({
        'id': 'video-1',
        'likes': 900,
        'dislikes': '100',
        'viewCount': 12000.0,
        'rating': '4.5',
      });

      expect(rating.videoId, 'video-1');
      expect(rating.likes, 900);
      expect(rating.dislikes, 100);
      expect(rating.viewCount, 12000);
      expect(rating.totalVotes, 1000);
      expect(rating.approvalPercent, 90);
      expect(rating.rating, 4.5);
    });

    test('handles an empty vote total', () {
      final rating = CommunityRating.fromJson(
        const <String, dynamic>{},
        fallbackVideoId: 'fallback',
      );

      expect(rating.videoId, 'fallback');
      expect(rating.totalVotes, 0);
      expect(rating.approvalPercent, 0);
    });
  });

  test('synced transcript-style LRC remains seekable', () {
    final lyrics = Lyrics.synced(
      '[00:01.25]First line\n[00:04.50]Second line',
      source: 'YouTube transcript',
    );

    final lines = lyrics.parseSynced();
    expect(lines, hasLength(2));
    expect(lines.first.time, const Duration(milliseconds: 1250));
    expect(lines.last.text, 'Second line');
    expect(lyrics.source, 'YouTube transcript');
  });
}
