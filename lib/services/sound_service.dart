import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays the bundled completion chime (assets/sounds/chime.wav).
class SoundService {
  SoundService._();

  static final instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();

  Future<void> init() async {
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setPlayerMode(PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('Sound init failed: $e');
    }
  }

  Future<void> playChime() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/chime.wav'));
    } catch (e) {
      debugPrint('Chime failed: $e');
    }
  }
}
