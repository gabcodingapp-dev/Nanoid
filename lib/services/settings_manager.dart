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

import 'package:audio_service/audio_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nanoid/screens/playlist_page.dart';
import 'package:nanoid/screens/user_songs_page.dart';
import 'package:nanoid/utilities/language_utils.dart';

// Preferences

final shouldWeCheckUpdates = ValueNotifier<bool?>(
  Hive.box('settings').get('shouldWeCheckUpdates', defaultValue: null),
);

final playNextSongAutomatically = ValueNotifier<bool>(
  Hive.box('settings').get('playNextSongAutomatically', defaultValue: false),
);

final useSystemColor = ValueNotifier<bool>(
  Hive.box('settings').get('useSystemColor', defaultValue: true),
);

final usePureBlackColor = ValueNotifier<bool>(
  Hive.box('settings').get('usePureBlackColor', defaultValue: false),
);

/// Liquid Glass (Beta). Off by default: BackdropFilter forces a compositor
/// read-back, so it is opt-in rather than something every device pays for.
final liquidGlassEnabled = ValueNotifier<bool>(
  Hive.box('settings').get('liquidGlassEnabled', defaultValue: false),
);

/// Playback speed multiplier, 0.5x - 2.0x.
final playbackSpeed = ValueNotifier<double>(
  (Hive.box('settings').get('playbackSpeed', defaultValue: 1.0) as num)
      .toDouble(),
);

/// Trims silent passages during playback (ExoPlayer feature, Android only).
final skipSilenceEnabled = ValueNotifier<bool>(
  Hive.box('settings').get('skipSilenceEnabled', defaultValue: false),
);

/// Shake the device to jump to the next track.
final shakeToSkipEnabled = ValueNotifier<bool>(
  Hive.box('settings').get('shakeToSkipEnabled', defaultValue: false),
);

/// Double-tap the left/right edge of the artwork to seek.
final doubleTapSeekEnabled = ValueNotifier<bool>(
  Hive.box('settings').get('doubleTapSeekEnabled', defaultValue: true),
);

/// Seek step used by double-tap, in seconds.
final doubleTapSeekSeconds = ValueNotifier<int>(
  Hive.box('settings').get('doubleTapSeekSeconds', defaultValue: 10),
);

/// Rebuild the previous queue when the app starts.
final restoreQueueEnabled = ValueNotifier<bool>(
  Hive.box('settings').get('restoreQueueEnabled', defaultValue: true),
);

/// Pitch multiplier, independent of tempo. Android only.
final playbackPitch = ValueNotifier<double>(
  (Hive.box('settings').get('playbackPitch', defaultValue: 1.0) as num)
      .toDouble(),
);

/// Volume fade applied on play, pause and manual track changes, in ms.
/// 0 disables it.
final fadeTransitionMs = ValueNotifier<int>(
  Hive.box('settings').get('fadeTransitionMs', defaultValue: 0),
);

/// Ramp the volume down over the last few seconds before the sleep timer
/// stops playback, instead of cutting out abruptly.
final sleepTimerFadeEnabled = ValueNotifier<bool>(
  Hive.box('settings').get('sleepTimerFadeEnabled', defaultValue: true),
);

/// Shuffle weighted by play count and recency instead of uniformly random.
final smartShuffleEnabled = ValueNotifier<bool>(
  Hive.box('settings').get('smartShuffleEnabled', defaultValue: false),
);

/// Tapping a synced lyric line seeks playback to that line.
final lyricsTapToSeekEnabled = ValueNotifier<bool>(
  Hive.box('settings').get('lyricsTapToSeekEnabled', defaultValue: true),
);

/// Extra output gain in decibels, on top of the system volume ceiling.
/// 0 disables the effect entirely.
final volumeBoostDb = ValueNotifier<double>(
  (Hive.box('settings').get('volumeBoostDb', defaultValue: 0.0) as num)
      .toDouble(),
);

/// ListenBrainz user token. Empty means scrobbling is off.
final listenBrainzToken = ValueNotifier<String>(
  Hive.box('settings').get('listenBrainzToken', defaultValue: ''),
);

/// Fluid: an exclusive monochrome theme with a slow-moving liquid backdrop.
/// Overrides the accent colour entirely while active.
final fluidThemeEnabled = ValueNotifier<bool>(
  Hive.box('settings').get('fluidThemeEnabled', defaultValue: true),
);

/// Fluid Motion (Beta): the backdrop leans with the device via the
/// accelerometer. Requires the Fluid theme.
final fluidGyroEnabled = ValueNotifier<bool>(
  Hive.box('settings').get('fluidGyroEnabled', defaultValue: false),
);

/// Fluid Rhythm (Beta): the backdrop pulses in time with playback.
/// Requires the Fluid theme.
final fluidRhythmEnabled = ValueNotifier<bool>(
  Hive.box('settings').get('fluidRhythmEnabled', defaultValue: false),
);

/// Estimated tempo used by Fluid Rhythm, in beats per minute.
final fluidRhythmBpm = ValueNotifier<int>(
  Hive.box('settings').get('fluidRhythmBpm', defaultValue: 120),
);

/// Per-track lyric timing nudge, in milliseconds. Applied on top of any
/// [offset:] tag already present in the LRC file.
final lyricsOffsetMs = ValueNotifier<int>(
  Hive.box('settings').get('lyricsOffsetMs', defaultValue: 0),
);

final offlineMode = ValueNotifier<bool>(
  Hive.box('settings').get('offlineMode', defaultValue: false),
);

final wrappedEnabled = ValueNotifier<bool>(
  Hive.box('settings').get('wrappedEnabled', defaultValue: true),
);

final sponsorBlockSupport = ValueNotifier<bool>(
  Hive.box('settings').get('sponsorBlockSupport', defaultValue: false),
);

/// SponsorBlock segment kinds Nanoid can skip. Point-of-interest highlights
/// are intentionally excluded because they mark a moment rather than a range.
const Map<String, String> sponsorBlockCategoryLabels = {
  'sponsor': 'Sponsors',
  'selfpromo': 'Self promotion',
  'interaction': 'Interaction reminders',
  'intro': 'Intros',
  'outro': 'Outros',
  'preview': 'Previews / recaps',
  'music_offtopic': 'Off-topic music sections',
  'filler': 'Filler',
};

Set<String> _readSponsorBlockCategories() {
  final stored = Hive.box('settings').get(
    'sponsorBlockCategories',
    defaultValue: const <dynamic>[
      'sponsor',
      'selfpromo',
      'interaction',
      'intro',
      'outro',
      'music_offtopic',
    ],
  );
  if (stored is! List) return {'sponsor'};
  final supported = sponsorBlockCategoryLabels.keys.toSet();
  final selected = stored.map((value) => value.toString()).toSet()
    ..removeWhere((value) => !supported.contains(value));
  return selected.isEmpty ? {'sponsor'} : selected;
}

final sponsorBlockCategories = ValueNotifier<Set<String>>(
  _readSponsorBlockCategories(),
);

String get sponsorBlockCategorySignature {
  final values = sponsorBlockCategories.value.toList()..sort();
  return values.join(',');
}

/// Show read-only community like/dislike estimates in Now Playing.
final communityRatingsEnabled = ValueNotifier<bool>(
  Hive.box('settings').get('communityRatingsEnabled', defaultValue: true),
);

/// Use a video's caption track only when dedicated lyrics providers have no
/// result. Captions are clearly labelled as a YouTube transcript in the player.
final youtubeTranscriptFallbackEnabled = ValueNotifier<bool>(
  Hive.box('settings')
      .get('youtubeTranscriptFallbackEnabled', defaultValue: true),
);

final externalRecommendations = ValueNotifier<bool>(
  Hive.box('settings').get('externalRecommendations', defaultValue: false),
);

final useProxy = ValueNotifier<bool>(
  Hive.box('settings').get('useProxy', defaultValue: false),
);

final audioQualitySetting = ValueNotifier<String>(
  Hive.box('settings').get('audioQuality', defaultValue: 'high'),
);

final showAudioQualityBadge = ValueNotifier<bool>(
  Hive.box('settings').get('showAudioQualityBadge', defaultValue: false),
);

List<double> _readEqualizerGains() {
  final raw = Hive.box('settings')
      .get('equalizerBandGains', defaultValue: const <dynamic>[]);

  if (raw is List) {
    return raw.map((value) => value is num ? value.toDouble() : 0.0).toList();
  }

  return <double>[];
}

final equalizerEnabled = ValueNotifier<bool>(
  Hive.box('settings').get('equalizerEnabled', defaultValue: false),
);

final equalizerBandGains = ValueNotifier<List<double>>(_readEqualizerGains());

Locale languageSetting = getLocaleFromLanguageCode(
  Hive.box('settings').get('languageCode', defaultValue: 'en') as String,
);

int themeModeSetting =
    Hive.box('settings').get('themeIndex', defaultValue: 0) as int;

String playlistSortSetting = Hive.box('settings')
    .get('playlistSortType', defaultValue: PlaylistSortType.default_.name);

String offlineSortSetting = Hive.box('settings')
    .get('offlineSortType', defaultValue: OfflineSortType.default_.name);

Color primaryColorSetting = Color(
  Hive.box('settings').get('accentColor', defaultValue: 0xFF8B5CF6),
);

final shuffleNotifier = ValueNotifier<bool>(
  Hive.box('settings').get('shuffleEnabled', defaultValue: false),
);

final repeatNotifier = ValueNotifier<AudioServiceRepeatMode>(
  AudioServiceRepeatMode.values[Hive.box('settings')
      .get('repeatMode', defaultValue: 0)],
);

// Non-storage notifiers

var sleepTimerNotifier = ValueNotifier<Duration?>(null);

// Server-Notifiers

final announcementURL = ValueNotifier<String?>(null);

void reloadSettingsFromStorage() {
  final settings = Hive.box('settings');

  shouldWeCheckUpdates.value = settings.get(
    'shouldWeCheckUpdates',
    defaultValue: null,
  );
  playNextSongAutomatically.value = settings.get(
    'playNextSongAutomatically',
    defaultValue: false,
  );
  useSystemColor.value = settings.get('useSystemColor', defaultValue: true);
  usePureBlackColor.value = settings.get(
    'usePureBlackColor',
    defaultValue: false,
  );
  offlineMode.value = settings.get('offlineMode', defaultValue: false);
  wrappedEnabled.value = settings.get('wrappedEnabled', defaultValue: true);
  sponsorBlockSupport.value = settings.get(
    'sponsorBlockSupport',
    defaultValue: false,
  );
  sponsorBlockCategories.value = _readSponsorBlockCategories();
  communityRatingsEnabled.value = settings.get(
    'communityRatingsEnabled',
    defaultValue: true,
  );
  youtubeTranscriptFallbackEnabled.value = settings.get(
    'youtubeTranscriptFallbackEnabled',
    defaultValue: true,
  );
  externalRecommendations.value = settings.get(
    'externalRecommendations',
    defaultValue: false,
  );
  useProxy.value = settings.get('useProxy', defaultValue: false);
  audioQualitySetting.value = settings.get(
    'audioQuality',
    defaultValue: 'high',
  );
  showAudioQualityBadge.value = settings.get(
    'showAudioQualityBadge',
    defaultValue: false,
  );
  equalizerEnabled.value = settings.get(
    'equalizerEnabled',
    defaultValue: false,
  );
  equalizerBandGains.value = _readEqualizerGains();

  final restoredThemeIndex = settings.get('themeIndex', defaultValue: 0);
  if (restoredThemeIndex is int) themeModeSetting = restoredThemeIndex;

  final restoredLanguageCode = settings.get('languageCode', defaultValue: 'en');
  if (restoredLanguageCode is String) {
    languageSetting = getLocaleFromLanguageCode(restoredLanguageCode);
  }

  final restoredPlaylistSort = settings.get(
    'playlistSortType',
    defaultValue: PlaylistSortType.default_.name,
  );
  if (restoredPlaylistSort is String) {
    playlistSortSetting = restoredPlaylistSort;
  }

  final restoredOfflineSort = settings.get(
    'offlineSortType',
    defaultValue: OfflineSortType.default_.name,
  );
  if (restoredOfflineSort is String) {
    offlineSortSetting = restoredOfflineSort;
  }

  final restoredAccentColor = settings.get(
    'accentColor',
    defaultValue: 0xff91cef4,
  );
  if (restoredAccentColor is int) {
    primaryColorSetting = Color(restoredAccentColor);
  }

  shuffleNotifier.value = settings.get('shuffleEnabled', defaultValue: false);
  final restoredRepeatIndex = settings.get('repeatMode', defaultValue: 0);
  if (restoredRepeatIndex is int &&
      restoredRepeatIndex >= 0 &&
      restoredRepeatIndex < AudioServiceRepeatMode.values.length) {
    repeatNotifier.value = AudioServiceRepeatMode.values[restoredRepeatIndex];
  }
}
