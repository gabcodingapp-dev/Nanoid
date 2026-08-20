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

import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nanoid/main.dart';
import 'package:nanoid/services/settings_manager.dart';

/// Playback speed picker.
///
/// Fixed steps rather than a free slider: on a phone a slider makes it very
/// easy to land on 1.03x and wonder why everything sounds slightly wrong.
/// 1.0x is always one tap away.
class PlaybackSpeedSheet extends StatelessWidget {
  const PlaybackSpeedSheet({super.key});

  static const List<double> speeds = [
    0.5,
    0.75,
    0.9,
    1,
    1.1,
    1.25,
    1.5,
    1.75,
    2,
  ];

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const PlaybackSpeedSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ValueListenableBuilder<double>(
        valueListenable: playbackSpeed,
        builder: (context, current, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Row(
                  children: [
                    Icon(
                      FluentIcons.top_speed_24_regular,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Playback speed',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (current != 1.0)
                      TextButton(
                        onPressed: () => audioHandler.setPlaybackSpeed(1),
                        child: const Text('Reset'),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final speed in speeds)
                      ChoiceChip(
                        label: Text(
                          speed == 1
                              ? 'Normal'
                              : '${speed.toString().replaceAll(RegExp(r'\.0$'), '')}x',
                        ),
                        selected: (current - speed).abs() < 0.001,
                        onSelected: (_) => audioHandler.setPlaybackSpeed(speed),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Row(
                  children: [
                    Icon(
                      FluentIcons.music_note_2_24_regular,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Pitch',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    ValueListenableBuilder<double>(
                      valueListenable: playbackPitch,
                      builder: (context, pitch, _) => pitch == 1.0
                          ? const SizedBox.shrink()
                          : TextButton(
                              onPressed: () =>
                                  audioHandler.setPlaybackPitch(1),
                              child: const Text('Reset'),
                            ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                child: Text(
                  'Changes key without changing tempo. Android only.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: ValueListenableBuilder<double>(
                  valueListenable: playbackPitch,
                  builder: (context, pitch, _) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final semitones in const [-4, -2, -1, 0, 1, 2, 4])
                        ChoiceChip(
                          label: Text(
                            semitones == 0
                                ? 'Original'
                                : '${semitones > 0 ? '+' : ''}$semitones',
                          ),
                          selected:
                              (pitch - _pitchFor(semitones)).abs() < 0.005,
                          onSelected: (_) => audioHandler.setPlaybackPitch(
                            _pitchFor(semitones),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Equal temperament: each semitone is a factor of 2^(1/12).
  static double _pitchFor(int semitones) =>
      math.pow(2, semitones / 12).toDouble();
}
