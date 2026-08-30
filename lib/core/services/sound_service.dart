import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final _beepPlayer = AudioPlayer();
  final _donePlayer = AudioPlayer();

  Future<void> init() async {
    await _beepPlayer.setAsset('assets/sounds/timer_beep.wav');
    await _donePlayer.setAsset('assets/sounds/timer_done.wav');
  }

  Future<void> playBeep() async {
    HapticFeedback.vibrate();
    await _beepPlayer.seek(Duration.zero);
    await _beepPlayer.play();
  }

  Future<void> playDone() async {
    HapticFeedback.heavyImpact();
    await _donePlayer.seek(Duration.zero);
    await _donePlayer.play();
  }

  void dispose() {
    _beepPlayer.dispose();
    _donePlayer.dispose();
  }
}
