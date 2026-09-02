import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

/// Режимы звонка Android: 0=беззвучный, 1=вибрация, 2=звук.
class RingMode {
  static const int silent = 0;
  static const int vibrate = 1;
  static const int normal = 2;
}

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  static const MethodChannel _deviceChannel = MethodChannel('dharana/device');

  final _nudgePlayer = AudioPlayer();
  final _gongPlayer = AudioPlayer();

  int _ringMode = RingMode.normal;
  bool _ringModeUnknown = true;

  Future<void> init() async {
    await _nudgePlayer.setAsset('assets/sounds/timer_nudge.wav');
    await _gongPlayer.setAsset('assets/sounds/timer_gong.wav');
    await _refreshRingMode();
  }

  /// Обновляет кэш ringer mode. Возвращает текущий режим.
  Future<int> _refreshRingMode() async {
    try {
      final mode = await _deviceChannel.invokeMethod<int>('getRingerMode');
      if (mode != null) {
        _ringMode = mode;
        _ringModeUnknown = false;
      }
    } catch (_) {
      // канал недоступен (например, тесты) — считаем режим звуковым
      _ringMode = RingMode.normal;
      _ringModeUnknown = true;
    }
    return _ringMode;
  }

  /// Прямая проверка: разрешён ли сейчас звук (память режима).
  bool get isSoundAllowed =>
      _ringModeUnknown || _ringMode == RingMode.normal;

  bool get isVibrationAllowed =>
      !_ringModeUnknown &&
      (_ringMode == RingMode.vibrate || _ringMode == RingMode.normal);

  Future<void> _play(AudioPlayer player) async {
    try {
      await player.seek(Duration.zero);
      await player.play();
    } catch (_) {}
  }

  /// Мягкий предупреждающий сигнал (обратный отсчёт 3-2-1).
  Future<void> playNudge() async {
    await _refreshRingMode();
    if (_ringMode == RingMode.silent) {
      // беззвучный режим — полная тишина
      return;
    }
    if (_ringMode == RingMode.vibrate) {
      HapticFeedback.lightImpact();
      return;
    }
    await _play(_nudgePlayer);
  }

  /// Гонг при смене позиции (асана -> отдых / отдых -> асана / завершение).
  Future<void> playGong() async {
    await _refreshRingMode();
    if (_ringMode == RingMode.silent) {
      return;
    }
    if (_ringMode == RingMode.vibrate) {
      HapticFeedback.mediumImpact();
      return;
    }
    await _play(_gongPlayer);
  }

  void dispose() {
    _nudgePlayer.dispose();
    _gongPlayer.dispose();
  }
}
