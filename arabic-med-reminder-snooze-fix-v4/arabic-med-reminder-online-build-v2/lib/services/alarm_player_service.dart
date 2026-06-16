import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

import '../models/enums.dart';

class AlarmPlayerService {
  AlarmPlayerService();

  final AudioPlayer _player = AudioPlayer();

  Future<void> start({
    required ReminderRingtone ringtone,
    required bool vibrate,
  }) async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('sounds/${ringtone.assetName}'));
    if (vibrate && (await Vibration.hasVibrator() ?? false)) {
      await Vibration.vibrate(pattern: [0, 700, 450, 700, 450, 900], repeat: 1);
    }
  }

  Future<void> stop() async {
    await _player.stop();
    await Vibration.cancel();
  }
}
