import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/tag.dart';
import 'spotify_service.dart';
import 'database_service.dart';

enum ExportState { idle, exporting, completed, failed, cancelled }

enum ExportType { queue, playlist, tag }

class ExportResult {
  final ExportType type;
  final bool success;
  final int songsExported;
  final int totalSongs;
  final String? error;
  final Tag? createdTag;

  ExportResult({
    required this.type,
    required this.success,
    required this.songsExported,
    required this.totalSongs,
    this.error,
    this.createdTag,
  });
}

class ExportService extends ChangeNotifier {
  final SpotifyService _spotifyService;
  final DatabaseService _databaseService;

  ExportState _state = ExportState.idle;
  double _progress = 0.0;
  bool _cancelRequested = false;

  ExportState get state => _state;
  double get progress => _progress;

  ExportService({
    required SpotifyService spotifyService,
    required DatabaseService databaseService,
  })  : _spotifyService = spotifyService,
        _databaseService = databaseService;

  void cancelExport() {
    _cancelRequested = true;
  }

  Future<ExportResult> exportToQueue(
    List<Song> songs, {
    void Function(int completed, int total)? onProgress,
  }) async {
    _state = ExportState.exporting;
    _progress = 0.0;
    _cancelRequested = false;
    notifyListeners();

    int exported = 0;
    final songsWithUri = songs.where((s) => s.uri != null).toList();

    try {
      for (int i = 0; i < songsWithUri.length; i++) {
        if (_cancelRequested) {
          _state = ExportState.cancelled;
          notifyListeners();
          return ExportResult(
            type: ExportType.queue,
            success: false,
            songsExported: exported,
            totalSongs: songsWithUri.length,
            error: 'Export cancelled',
          );
        }

        await _spotifyService.addTrackToQueue(songsWithUri[i].uri!);
        exported++;
        _progress = exported / songsWithUri.length;
        onProgress?.call(exported, songsWithUri.length);
        notifyListeners();

        if (i < songsWithUri.length - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      _state = ExportState.completed;
      notifyListeners();
      return ExportResult(
        type: ExportType.queue,
        success: true,
        songsExported: exported,
        totalSongs: songsWithUri.length,
      );
    } catch (e) {
      _state = ExportState.failed;
      notifyListeners();
      return ExportResult(
        type: ExportType.queue,
        success: false,
        songsExported: exported,
        totalSongs: songsWithUri.length,
        error: e.toString(),
      );
    }
  }

  Future<ExportResult> exportAsPlaylist(
    String name,
    List<Song> songs, {
    void Function(int completed, int total)? onProgress,
  }) async {
    _state = ExportState.exporting;
    _progress = 0.0;
    _cancelRequested = false;
    notifyListeners();

    final songsWithUri = songs.where((s) => s.uri != null).toList();

    try {
      final playlist = await _spotifyService.createPlaylist(
        name,
        description: 'Created by Tagify query export',
      );

      if (_cancelRequested) {
        _state = ExportState.cancelled;
        notifyListeners();
        return ExportResult(
          type: ExportType.playlist,
          success: false,
          songsExported: 0,
          totalSongs: songsWithUri.length,
          error: 'Export cancelled',
        );
      }

      int exported = 0;
      for (int i = 0; i < songsWithUri.length; i += 100) {
        if (_cancelRequested) {
          _state = ExportState.cancelled;
          notifyListeners();
          return ExportResult(
            type: ExportType.playlist,
            success: false,
            songsExported: exported,
            totalSongs: songsWithUri.length,
            error: 'Export cancelled',
            createdTag: playlist,
          );
        }

        final end = (i + 100).clamp(0, songsWithUri.length);
        final batch = songsWithUri.sublist(i, end);
        final uris = batch.map((s) => s.uri!).toList();

        await _spotifyService.addTracksToPlaylist(playlist.spotifyId, uris);
        exported += batch.length;
        _progress = exported / songsWithUri.length;
        onProgress?.call(exported, songsWithUri.length);
        notifyListeners();
      }

      _state = ExportState.completed;
      notifyListeners();
      return ExportResult(
        type: ExportType.playlist,
        success: true,
        songsExported: exported,
        totalSongs: songsWithUri.length,
        createdTag: playlist,
      );
    } catch (e) {
      _state = ExportState.failed;
      notifyListeners();
      return ExportResult(
        type: ExportType.playlist,
        success: false,
        songsExported: 0,
        totalSongs: songsWithUri.length,
        error: e.toString(),
      );
    }
  }

  Future<ExportResult> exportAsTag(
    String name,
    List<Song> songs, {
    void Function(int completed, int total)? onProgress,
  }) async {
    _state = ExportState.exporting;
    _progress = 0.0;
    _cancelRequested = false;
    notifyListeners();

    try {
      final spotifyTag = await _spotifyService.createTagifyTag(name);

      final tag = Tag(
        spotifyId: spotifyTag.spotifyId,
        name: name,
        description: spotifyTag.description,
        type: TagType.tag,
      );

      final tagId = await _databaseService.insertTag(tag);
      final savedTag = Tag(
        id: tagId,
        spotifyId: tag.spotifyId,
        name: tag.name,
        description: tag.description,
        type: tag.type,
      );

      if (_cancelRequested) {
        _state = ExportState.cancelled;
        notifyListeners();
        return ExportResult(
          type: ExportType.tag,
          success: false,
          songsExported: 0,
          totalSongs: songs.length,
          error: 'Export cancelled',
          createdTag: savedTag,
        );
      }

      int exported = 0;
      final urisToAdd = <String>[];

      for (final song in songs) {
        if (song.id == null) continue;
        try {
          await _databaseService.addSongToTag(song.id!, savedTag.id!);
          if (song.uri != null) urisToAdd.add(song.uri!);
          exported++;
        } catch (e) {
          debugPrint('Skipping duplicate song-tag: ${song.title}');
        }
        _progress = exported / songs.length;
        onProgress?.call(exported, songs.length);
        notifyListeners();
      }

      if (urisToAdd.isNotEmpty) {
        for (int i = 0; i < urisToAdd.length; i += 100) {
          final end = (i + 100).clamp(0, urisToAdd.length);
          final batch = urisToAdd.sublist(i, end);
          await _spotifyService.addTracksToPlaylist(
              savedTag.spotifyId, batch);
        }
      }

      _state = ExportState.completed;
      notifyListeners();
      return ExportResult(
        type: ExportType.tag,
        success: true,
        songsExported: exported,
        totalSongs: songs.length,
        createdTag: savedTag,
      );
    } catch (e) {
      _state = ExportState.failed;
      notifyListeners();
      return ExportResult(
        type: ExportType.tag,
        success: false,
        songsExported: 0,
        totalSongs: songs.length,
        error: e.toString(),
      );
    }
  }

  void reset() {
    _state = ExportState.idle;
    _progress = 0.0;
    _cancelRequested = false;
    notifyListeners();
  }
}
