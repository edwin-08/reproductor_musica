import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:reproductor_musica/app/widgets/song_tile.dart';

void main() {
  testWidgets('SongTile renders correctly and responds to tap', (WidgetTester tester) async {
    final song = SongModel({
      '_id': 1,
      '_display_name_wo_ext': 'Test Song',
      '_artist': 'Test Artist',
      '_data': '',
      '_file_extension': 'mp3'
    });

    var tapped = false;
    var deleted = false;
    var renamed = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SongTile(
          song: song,
          onTap: () => tapped = true,
          onDelete: () => deleted = true,
          onRename: () => renamed = true,
        ),
      ),
    ));

    // Verifica que el texto está presente
    expect(find.text('Test Song'), findsOneWidget);

    // Toca el ListTile
    await tester.tap(find.byType(ListTile));
    expect(tapped, isTrue);

    // Abre el menú
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Toca eliminar
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });
}