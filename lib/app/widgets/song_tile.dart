import 'dart:io';

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongTile extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: QueryArtworkWidget(
        id: song.id,
        type: ArtworkType.AUDIO,
        nullArtworkWidget: const Icon(Icons.music_note),
      ),
      title: Text(song.displayNameWOExt),
      subtitle: Text(song.artist ?? "Desconocido"),
      onTap: onTap,
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'delete') {
            onDelete();
          } else if (value == 'rename') {
            onRename();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          const PopupMenuItem(value: 'rename', child: Text('Renombrar')),
        ],
      ),
    );
  }
}
