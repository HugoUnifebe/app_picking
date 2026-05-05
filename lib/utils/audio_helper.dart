import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioHelper {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playBeepSimples() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('beep_simples.mp3'));
    } catch (e) {
      debugPrint('Erro ao reproduzir beep_simples: $e');
    }
  }

  static Future<void> playBeepLongo() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('beep_longo.mp3'));
    } catch (e) {
      debugPrint('Erro ao reproduzir beep_longo: $e');
    }
  }
}
