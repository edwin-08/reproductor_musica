import 'package:flutter_test/flutter_test.dart';
import 'package:reproductor_musica/app/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AudioService', () {
    late AudioService audioService;

    setUp(() {
      audioService = AudioService();
    });

    test('player is initialized', () {
      expect(audioService.player, isNotNull);
    });

    test('dispose cleans up the player', () async {
      audioService.dispose();
      expect(() => audioService.dispose(), returnsNormally);
    });
  });
}