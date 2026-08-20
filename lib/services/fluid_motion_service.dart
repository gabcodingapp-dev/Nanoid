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

import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:nanoid/main.dart';
import 'package:nanoid/services/settings_manager.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Drives the two Beta reactivity modes behind the Fluid theme.
///
/// Kept as one small singleton so the sensor subscription exists at most once,
/// regardless of how many widgets read from it, and is torn down the moment the
/// feature is switched off.
class FluidMotionService {
  factory FluidMotionService() => _instance;
  FluidMotionService._internal() {
    fluidGyroEnabled.addListener(_syncGyro);
    fluidRhythmEnabled.addListener(_syncRhythm);
  }
  static final FluidMotionService _instance = FluidMotionService._internal();

  // --- Fluid Motion (gyro) -------------------------------------------------

  /// Device lean, normalised to roughly -1..1 on each axis.
  final tilt = ValueNotifier<Offset>(Offset.zero);

  StreamSubscription<AccelerometerEvent>? _accelSub;

  /// Gravity is ~9.81 m/s^2 on one axis when the phone is on its side, so this
  /// maps a comfortable wrist-tilt range onto -1..1.
  static const double _tiltDivisor = 6;

  /// Low-pass factor. Raw accelerometer output is jittery; blending each sample
  /// into the previous one keeps the backdrop from vibrating.
  static const double _smoothing = 0.12;

  void _syncGyro() {
    if (fluidGyroEnabled.value) {
      _startGyro();
    } else {
      _stopGyro();
    }
  }

  void _startGyro() {
    if (_accelSub != null) return;
    try {
      _accelSub =
          accelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: 66),
          ).listen(
            (event) {
              final targetX = (event.x / _tiltDivisor).clamp(-1.0, 1.0);
              final targetY = (event.y / _tiltDivisor).clamp(-1.0, 1.0);
              final current = tilt.value;
              tilt.value = Offset(
                current.dx + (targetX - current.dx) * _smoothing,
                current.dy + (targetY - current.dy) * _smoothing,
              );
            },
            onError: (Object e) {
              // No accelerometer (emulator, desktop). Fail quiet and flat.
              logger.log('Fluid Motion unavailable', error: e);
              _stopGyro();
            },
            cancelOnError: true,
          );
    } catch (e, stackTrace) {
      logger.log(
        'Could not start accelerometer',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _stopGyro() {
    _accelSub?.cancel();
    _accelSub = null;
    tilt.value = Offset.zero;
  }

  // --- Fluid Rhythm --------------------------------------------------------

  /// 0..1 pulse that swells on each estimated beat.
  final beat = ValueNotifier<double>(0);

  Timer? _beatTimer;
  double _phase = 0;

  /// NOTE: this is a *tempo-estimated* pulse, not true onset detection.
  /// just_audio exposes no PCM buffer, and real beat tracking would need the
  /// Android Visualizer API behind a RECORD_AUDIO permission. This pulses at
  /// [fluidRhythmBpm] whenever playback is active, which reads convincingly
  /// for steady-tempo music and costs nothing.
  void _syncRhythm() {
    if (fluidRhythmEnabled.value) {
      _startRhythm();
    } else {
      _stopRhythm();
    }
  }

  void _startRhythm() {
    if (_beatTimer != null) return;
    const tick = Duration(milliseconds: 33);
    _beatTimer = Timer.periodic(tick, (_) {
      final isPlaying = audioHandler.playbackState.value.playing;
      if (!isPlaying) {
        if (beat.value != 0) beat.value = beat.value * 0.9;
        return;
      }

      final bpm = fluidRhythmBpm.value.clamp(40, 220);
      final beatSeconds = 60 / bpm;
      _phase += tick.inMilliseconds / 1000 / beatSeconds;
      if (_phase > 1) _phase -= 1;

      // Sharp attack, gentle decay - closer to how a kick actually feels than
      // a plain sine would be.
      final envelope = math.pow(1 - _phase, 2.4).toDouble();
      beat.value = envelope.clamp(0.0, 1.0);
    });
  }

  void _stopRhythm() {
    _beatTimer?.cancel();
    _beatTimer = null;
    _phase = 0;
    beat.value = 0;
  }

  /// Starts whichever modes are already enabled. Called once at boot.
  void initialise() {
    _syncGyro();
    _syncRhythm();
  }

  void dispose() {
    _stopGyro();
    _stopRhythm();
  }
}
