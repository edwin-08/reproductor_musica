import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MusicPlayerApp());
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reproductor de Música',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const SongListPage(),
    );
  }
}

class SongListPage extends StatefulWidget {
  const SongListPage({super.key});

  @override
  State<SongListPage> createState() => _SongListPageState();
}

class _SongListPageState extends State<SongListPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _player = AudioPlayer();

  List<SongModel> _songs = [];
  int _currentIndex = -1;

  @override
  void initState() {
    super.initState();
    _requestPermission();

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _playNext();
      }
    });
  }

  Future<void> _requestPermission() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (Platform.isAndroid) {
      if (sdkInt >= 30) {
        
        // Android 11, 12 (API 30-32): MANAGE_EXTERNAL_STORAGE
        if (sdkInt <= 32) {
          if (!await Permission.storage.isGranted) {
            final status = await Permission.storage.request();
            if (!status.isGranted) {
              _showError("Se requiere permiso para acceder a tus archivos de música.");
              return;
            }
          }

          if (!await Permission.manageExternalStorage.isGranted) {
            final status = await Permission.manageExternalStorage.request();
            if (!status.isGranted) {
              _showError("Se requiere permiso para gestionar el almacenamiento.");
              return;
            }
          }
        }

        if (sdkInt >= 33) {
          // Android 13+ requiere READ_MEDIA_AUDIO en vez de READ_EXTERNAL_STORAGE
          if (!await Permission.audio.isGranted) {
            final status = await Permission.audio.request();
            if (!status.isGranted) {
              _showError("Se requiere permiso para acceder a tus archivos de audio.");
              return;
            }
          }
        }

      } else {
        // Android 10 o menor: READ/WRITE_EXTERNAL_STORAGE
        if (!await Permission.storage.isGranted) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            _showError("Se requiere permiso para leer/escribir en almacenamiento.");
            return;
          }
        }
      }
    }

    _loadSongs();
  }

  Future<bool> _checkStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    } else {
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
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
      await _player.setAudioSource(AudioSource.uri(Uri.parse(_songs[index].uri!)));
      _player.play();
      setState(() {
        _currentIndex = index;
      });
    } catch (e) {
      debugPrint("Error al reproducir: $e");
    }
  }

  void _deleteSong(SongModel song) async {
    if (!await _checkStoragePermission()) {
      _showError("No tienes permiso para eliminar archivos");
      return;
    }

    final filePath = song.data;
    if (filePath.isEmpty) {
      _showError("No se pudo obtener la ruta del archivo");
      return;
    }

    final file = File(filePath);
    if (await file.exists()) {
      try {
        await file.delete();
        _loadSongs();
        _showMessage("Archivo eliminado");
      } catch (e) {
        _showError("No se pudo eliminar el archivo: $e");
      }
    } else {
      _showError("El archivo no existe");
    }
  }

  void _renameSong(SongModel song) async {
    if (!await _checkStoragePermission()) {
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

                if (!await _checkStoragePermission()) {
                  _showError("No tienes permiso para renombrar archivos");
                  return;
                }

                final oldFile = File(song.data);
                final newPath = '${oldFile.parent.path}/$newName.${song.fileExtension}';

                try {
                  await oldFile.rename(newPath);
                  await _loadSongs();
                  _showMessage("Archivo renombrado");
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                } catch (e) {
                  _showError("No se pudo renombrar el archivo: $e");
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

  @override
  void dispose() {
    _player.dispose();
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
              const PopupMenuItem(
                value: 'refresh',
                child: Text('Actualizar'),
              ),
            ],
          )
        ],
      ),
      body: _songs.isEmpty
          ? const Center(child: Text('No se encontraron canciones'))
          : ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return ListTile(
                  leading: QueryArtworkWidget(
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    nullArtworkWidget: const Icon(Icons.music_note),
                  ),
                  title: Text(song.displayNameWOExt),
                  subtitle: Text(song.artist ?? "Desconocido"),
                  onTap: () => _playSong(index),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteSong(song);
                      } else if (value == 'rename') {
                        _renameSong(song);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar'),
                      ),
                      const PopupMenuItem(
                        value: 'rename',
                        child: Text('Renombrar'),
                      ),
                    ],
                  ),
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
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: _playPrevious,
                  ),
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snapshot) {
                      final state = snapshot.data;
                      final playing = state?.playing ?? false;
                      if (playing) {
                        return IconButton(
                          icon: const Icon(Icons.pause),
                          onPressed: _player.pause,
                        );
                      } else {
                        return IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: _player.play,
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: _playNext,
                  ),
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