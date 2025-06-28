import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:reproductor_musica/app/services/audio_service.dart';
import 'package:reproductor_musica/app/services/permission_service.dart';
import 'package:reproductor_musica/app/widgets/song_tile.dart';

class SongListPage extends StatefulWidget {
  const SongListPage({super.key});

  @override
  State<SongListPage> createState() => _SongListPageState();
}

class _SongListPageState extends State<SongListPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioService _audioService = AudioService();

  List<SongModel> _songs = [];
  int _currentIndex = -1;

  @override
  void initState() {
    super.initState();
    _init();
    _audioService.player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _playNext();
      }
    });
  }

  Future<void> _init() async {
    final granted = await PermissionService.requestPermissions();
    if (granted) {
      _loadSongs();
    } else {
      _showError("Permisos no otorgados");
    }
  }

  Future<void> _loadSongs() async {
    final songs = await _audioQuery.querySongs();
    setState(() {
      _songs = songs.where((s) => s.isMusic!).toList();
    });
  }

  Future<void> _playSong(int index) async {
    try {
      await _audioService.play(_songs[index].uri!);
      setState(() {
        _currentIndex = index;
      });
    } catch (e) {
      _showError("Error al reproducir: $e");
    }
  }

  Future<void> _deleteSong(SongModel song) async {
    if (!await PermissionService.checkStoragePermission()) {
      _showError("No tienes permiso para eliminar archivos");
      return;
    }

    final file = File(song.data);
    if (await file.exists()) {
      try {
        await file.delete();
        _loadSongs();
        _showMessage("Archivo eliminado");
      } catch (e) {
        _showError("No se pudo eliminar: $e");
      }
    } else {
      _showError("El archivo no existe");
    }
  }

  Future<void> _renameSong(SongModel song) async {
    if (!await PermissionService.checkStoragePermission()) {
      _showError("No tienes permiso para renombrar archivos");
      return;
    }

    final controller = TextEditingController(text: song.displayNameWOExt);
    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Renombrar canción"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nuevo nombre"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty || newName.contains(RegExp(r'[\/:*?"<>|]'))) {
                _showError("Nombre inválido");
                return;
              }

              final oldFile = File(song.data);
              final newPath =
                  '${oldFile.parent.path}/$newName.${song.fileExtension}';
              try {
                await oldFile.rename(newPath);
                _loadSongs();
                _showMessage("Archivo renombrado");
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              } catch (e) {
                _showError("No se pudo renombrar: $e");
              }
            },
            child: const Text("Renombrar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
        ],
      ),
    );
  }

  void _playNext() {
    if (_currentIndex + 1 < _songs.length) {
      _playSong(_currentIndex + 1);
    } else {
      _playSong(0);
    }
  }

  void _playPrevious() {
    if (_currentIndex - 1 >= 0) {
      _playSong(_currentIndex - 1);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis canciones', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.red[900],
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app, color: Colors.white),
          onPressed: () {
            if (Platform.isAndroid) {
              SystemNavigator.pop();
            }
          },
        ),
        actions: [
          PopupMenuButton<String>(
            iconColor: Colors.white,
            onSelected: (value) {
              if (value == 'refresh') {
                _loadSongs();
                _showMessage("Lista actualizada");
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'refresh', child: Text('Actualizar')),
            ],
          ),
        ],
      ),
      body: _songs.isEmpty ? const Center(child: Text('No se encontraron canciones'))
          : ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                return SongTile(
                  song: _songs[index],
                  onTap: () => _playSong(index),
                  onDelete: () => _deleteSong(_songs[index]),
                  onRename: () => _renameSong(_songs[index]),
                );
              },
            ),
      bottomNavigationBar: _currentIndex != -1
          ? Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blueGrey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(icon: const Icon(Icons.skip_previous), onPressed: _playPrevious),
                  StreamBuilder<PlayerState>(
                    stream: _audioService.player.playerStateStream,
                    builder: (context, snapshot) {
                      final playing = snapshot.data?.playing ?? false;
                      return IconButton(
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                        onPressed: playing ? _audioService.player.pause : _audioService.player.play,
                      );
                    },
                  ),
                  IconButton(icon: const Icon(Icons.skip_next), onPressed: _playNext),
                  Expanded(
                    child: Text(
                      _songs[_currentIndex].title,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
