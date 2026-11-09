import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

class EmergencyAlertService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> trigger() async {
    debugPrint("🚨 Emergency alert triggered");

    // 🔊 Play loud looping sound
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(
      AssetSource('sounds/emergency.mp3'),
      volume: 1.0,
    );

    // 📳 Strong vibration pattern
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(
        pattern: [0, 1000, 500, 1000, 500, 1000],
        repeat: 0,
      );
    }
  }

  static Future<void> stop() async {
    await _player.stop();
    Vibration.cancel();
  }
}
