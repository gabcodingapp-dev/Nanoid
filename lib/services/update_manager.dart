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

import 'dart:convert';
import 'dart:io';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:nanoid/constants/version.dart';
import 'package:nanoid/extensions/l10n.dart';
import 'package:nanoid/main.dart';
import 'package:nanoid/services/data_manager.dart';
import 'package:nanoid/services/router_service.dart';
import 'package:nanoid/services/settings_manager.dart';
import 'package:nanoid/utilities/url_launcher.dart';
import 'package:nanoid/widgets/auto_format_text.dart';

/// Update checks read the GitHub Releases API directly.
///
/// The previous implementation first fetched a hand-maintained `check.json`
/// from an `update` branch. That branch was never created for this repo, so
/// every launch logged a 404 and update checks silently never worked. The
/// Releases API is already the source of truth for the APK, so there is no
/// reason to maintain a second manifest.
const String releasesUrl =
    'https://api.github.com/repos/gabcodingapp-dev/Nanoid/releases/latest';
const String downloadFilename = 'Nanoid.apk';

Future<void> checkAppUpdates() async {
  try {
    final releasesRequest = await http.get(Uri.parse(releasesUrl));

    // 404 simply means no release has been published yet, which is a normal
    // state for a young repo rather than an error worth surfacing.
    if (releasesRequest.statusCode == 404) return;

    if (releasesRequest.statusCode != 200) {
      logger.log(
        'Fetch releases API returned status code '
        '${releasesRequest.statusCode}',
      );
      return;
    }

    final releasesResponse =
        json.decode(releasesRequest.body) as Map<String, dynamic>;

    if (releasesResponse['draft'] == true ||
        releasesResponse['prerelease'] == true) {
      return;
    }

    // Tags are conventionally 'v1.2.3'; compare on the bare number.
    final latestVersion = (releasesResponse['tag_name'] ?? '')
        .toString()
        .replaceFirst(RegExp('^v', caseSensitive: false), '')
        .trim();

    if (latestVersion.isEmpty ||
        !isLatestVersionHigher(appVersion, latestVersion)) {
      return;
    }

    await showDialog(
      context: NavigationManager().context,
      builder: (BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;

        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FluentIcons.arrow_download_24_regular,
                  color: colorScheme.onPrimaryContainer,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n!.appUpdateIsAvailable,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'V$latestVersion',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height / 2.5,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: AutoFormatText(text: releasesResponse['body']),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(context.l10n!.cancel),
            ),
            FilledButton.icon(
              onPressed: () {
                getDownloadUrl(releasesResponse).then(
                  (url) => {launchURL(Uri.parse(url)), Navigator.pop(context)},
                );
              },
              icon: const Icon(FluentIcons.arrow_download_20_regular),
              label: Text(context.l10n!.download),
            ),
          ],
        );
      },
    );
  } catch (e, stackTrace) {
    logger.log('Error in checkAppUpdates', error: e, stackTrace: stackTrace);
  }
}

void showUpdateCheckDialog(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        icon: Icon(
          FluentIcons.arrow_sync_circle_24_regular,
          color: colorScheme.primary,
          size: 40,
        ),
        title: Text(
          context.l10n!.checkForUpdates,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          context.l10n!.enableUpdateChecksDescription,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () {
              shouldWeCheckUpdates.value = false;
              addOrUpdateData<bool>('settings', 'shouldWeCheckUpdates', false);
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(context.l10n!.no),
          ),
          FilledButton(
            onPressed: () {
              shouldWeCheckUpdates.value = true;
              addOrUpdateData<bool>('settings', 'shouldWeCheckUpdates', true);
              if (!isFdroidBuild && kReleaseMode && !offlineMode.value) {
                checkAppUpdates();
                isUpdateChecked = true;
              }
              Navigator.of(context).pop();
            },
            child: Text(context.l10n!.yes),
          ),
        ],
      );
    },
  );
}

bool isLatestVersionHigher(String appVersion, String latestVersion) {
  final parsedAppVersion = appVersion.split('.');
  final parsedAppLatestVersion = latestVersion.split('.');
  final length = parsedAppVersion.length > parsedAppLatestVersion.length
      ? parsedAppVersion.length
      : parsedAppLatestVersion.length;
  for (var i = 0; i < length; i++) {
    final value1 = i < parsedAppVersion.length
        ? int.parse(parsedAppVersion[i])
        : 0;
    final value2 = i < parsedAppLatestVersion.length
        ? int.parse(parsedAppLatestVersion[i])
        : 0;
    if (value2 > value1) {
      return true;
    } else if (value2 < value1) {
      return false;
    }
  }

  return false;
}

Future<String> getCPUArchitecture() async {
  final info = await Process.run('uname', ['-m']);
  final cpu = info.stdout.toString().replaceAll('\n', '');

  return cpu;
}

/// Picks the best APK asset from a GitHub release payload.
///
/// Prefers an arm64-specific build on aarch64 devices, then any APK, and
/// finally falls back to the release page so the button is never a dead end.
Future<String> getDownloadUrl(Map<String, dynamic> release) async {
  final assets = (release['assets'] as List?) ?? const [];
  final apks = assets
      .whereType<Map<String, dynamic>>()
      .where((a) => a['name'].toString().toLowerCase().endsWith('.apk'))
      .toList();

  if (apks.isEmpty) {
    return (release['html_url'] ?? releasesUrl).toString();
  }

  final cpuArchitecture = await getCPUArchitecture();
  if (cpuArchitecture == 'aarch64') {
    for (final asset in apks) {
      final name = asset['name'].toString().toLowerCase();
      if (name.contains('arm64')) {
        return asset['browser_download_url'].toString();
      }
    }
  }

  return apks.first['browser_download_url'].toString();
}

/// Announcements were served from the same `check.json` manifest that no
/// longer exists, so this is now a no-op kept for call-site compatibility.
///
/// Nanoid has no announcement channel; if one is ever added it should read
/// from a real endpoint rather than a branch-hosted JSON file.
Future<void> fetchAnnouncementOnly() async {}
