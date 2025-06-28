import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer player = AudioPlayer();

  Future<void> play(String uri) async {
    await player.setAudioSource(AudioSource.uri(Uri.parse(uri)));
    await player.play();
  }

  void dispose() {
    player.dispose();
  }
}
