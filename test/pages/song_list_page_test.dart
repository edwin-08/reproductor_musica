import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reproductor_musica/app/pages/song_list_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('SongListPage shows AppBar and empty message', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SongListPage()));

    expect(find.text('Mis canciones'), findsOneWidget);
    expect(find.text('No se encontraron canciones'), findsOneWidget);
  });
}