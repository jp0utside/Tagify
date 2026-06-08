import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/tag.dart';
import 'spotify_service.dart';
import 'database_service.dart';

enum ImportStatus { idle, importing, completed, failed, cancelled }

class ImportProgress {
  final int totalSongs;
  final int importedSongs;
  final int totalPlaylists;
  final int importedPlaylists;
  final String currentStep;

  ImportProgress({
    this.totalSongs = 0,
    this.importedSongs = 0,
    this.totalPlaylists = 0,
    this.importedPlaylists = 0,
    this.currentStep = '',
  });

  double get songProgress =>
      totalSongs == 0 ? 0.0 : importedSongs / totalSongs;
  double get playlistProgress =>
      totalPlaylists == 0 ? 0.0 : importedPlaylists / totalPlaylists;
  double get overallProgress {
    if (totalSongs == 0 && totalPlaylists == 0) return 0.0;
    final total = totalSongs + totalPlaylists;
    final imported = importedSongs + importedPlaylists;
    return imported / total;
  }
}

class ImportService extends ChangeNotifier {
  final SpotifyService _spotifyService;
  final DatabaseService _databaseService;

  ImportStatus _status = ImportStatus.idle;
  ImportProgress _progress = ImportProgress();
  String? _errorMessage;
  bool _cancelRequested = false;

  ImportStatus get status => _status;
  ImportProgress get progress => _progress;
  String? get errorMessage => _errorMessage;

  ImportService({
    required SpotifyService spotifyService,
    required DatabaseService databaseService,
  })  : _spotifyService = spotifyService,
        _databaseService = databaseService;

  Future<bool> importLibrary() async {
    if (_status == ImportStatus.importing) return false;

    _status = ImportStatus.importing;
    _errorMessage = null;
    _cancelRequested = false;
    _progress = ImportProgress(currentStep: 'Starting import...');
    notifyListeners();

    try {
      await _importLikedSongs();
      if (_cancelRequested) {
        _status = ImportStatus.cancelled;
        notifyListeners();
        return false;
      }

      await _importPlaylists();
      if (_cancelRequested) {
        _status = ImportStatus.cancelled;
        notifyListeners();
        return false;
      }

      _status = ImportStatus.completed;
      notifyListeners();
      return true;
    } catch (e) {
      _status = ImportStatus.failed;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void cancelImport() {
    _cancelRequested = true;
  }

  void reset() {
    _status = ImportStatus.idle;
    _progress = ImportProgress();
    _errorMessage = null;
    _cancelRequested = false;
    notifyListeners();
  }

  Future<void> _importLikedSongs() async {
    _progress = ImportProgress(currentStep: 'Fetching liked songs...');
    notifyListeners();

    int totalSongs = 0;
    try {
      totalSongs = await _spotifyService.getLikedSongsTotal();
    } catch (_) {
      // If we can't get total, we'll update as we go
    }

    int offset = 0;
    const int limit = 50;
    int totalFetched = 0;
    bool hasMore = true;

    while (hasMore && !_cancelRequested) {
      final songs =
          await _spotifyService.getLikedSongs(limit: limit, offset: offset);

      for (final song in songs) {
        if (_cancelRequested) return;
        await _insertSongIfNew(song);
        totalFetched++;
      }

      _progress = ImportProgress(
        totalSongs: totalSongs > 0 ? totalSongs : totalFetched,
        importedSongs: totalFetched,
        totalPlaylists: _progress.totalPlaylists,
        importedPlaylists: _progress.importedPlaylists,
        currentStep: 'Importing liked songs ($totalFetched'
            '${totalSongs > 0 ? '/$totalSongs' : ''})...',
      );
      notifyListeners();

      hasMore = songs.length == limit;
      offset += limit;

      if (hasMore) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    _progress = ImportProgress(
      totalSongs: totalFetched,
      importedSongs: totalFetched,
      totalPlaylists: _progress.totalPlaylists,
      importedPlaylists: _progress.importedPlaylists,
      currentStep: 'Liked songs imported ($totalFetched songs)',
    );
    notifyListeners();
  }

  Future<void> _importPlaylists() async {
    _progress = ImportProgress(
      totalSongs: _progress.totalSongs,
      importedSongs: _progress.importedSongs,
      currentStep: 'Fetching playlists...',
    );
    notifyListeners();

    final playlists = await _spotifyService.getAllUserPlaylists();
    final nonTagPlaylists =
        playlists.where((p) => !p.name.startsWith('#tag:')).toList();
    final tagPlaylists =
        playlists.where((p) => p.name.startsWith('#tag:')).toList();

    final totalPlaylists = nonTagPlaylists.length + tagPlaylists.length;
    int importedPlaylists = 0;

    // Import regular playlists as read-only
    for (final playlist in nonTagPlaylists) {
      if (_cancelRequested) return;

      await _insertTagIfNew(playlist);
      await _importPlaylistTracks(playlist);
      importedPlaylists++;

      _progress = ImportProgress(
        totalSongs: _progress.totalSongs,
        importedSongs: _progress.importedSongs,
        totalPlaylists: totalPlaylists,
        importedPlaylists: importedPlaylists,
        currentStep:
            'Importing playlist "${playlist.name}" ($importedPlaylists/$totalPlaylists)...',
      );
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Import Tagify tag playlists
    for (final tag in tagPlaylists) {
      if (_cancelRequested) return;

      await _insertTagIfNew(tag);
      await _importPlaylistTracks(tag);
      importedPlaylists++;

      _progress = ImportProgress(
        totalSongs: _progress.totalSongs,
        importedSongs: _progress.importedSongs,
        totalPlaylists: totalPlaylists,
        importedPlaylists: importedPlaylists,
        currentStep:
            'Importing tag "${tag.name}" ($importedPlaylists/$totalPlaylists)...',
      );
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 100));
    }

    _progress = ImportProgress(
      totalSongs: _progress.totalSongs,
      importedSongs: _progress.importedSongs,
      totalPlaylists: totalPlaylists,
      importedPlaylists: totalPlaylists,
      currentStep: 'Import complete!',
    );
    notifyListeners();
  }

  Future<void> _importPlaylistTracks(Tag playlist) async {
    try {
      final songs =
          await _spotifyService.getAllPlaylistTracks(playlist.spotifyId);
      final tag = await _databaseService.getTagBySpotifyId(playlist.spotifyId);
      if (tag == null) return;

      for (final song in songs) {
        final insertedId = await _insertSongIfNew(song);
        if (insertedId != null && tag.id != null) {
          try {
            await _databaseService.addSongToTag(insertedId, tag.id!);
          } catch (_) {
            // Relationship may already exist
          }
        }
      }
    } catch (e) {
      debugPrint('Error importing tracks for playlist ${playlist.name}: $e');
    }
  }

  Future<int?> _insertSongIfNew(Song song) async {
    final existing =
        await _databaseService.getSongBySpotifyId(song.spotifyId);
    if (existing != null) return existing.id;

    try {
      return await _databaseService.insertSong(song);
    } catch (e) {
      debugPrint('Error inserting song ${song.title}: $e');
      return null;
    }
  }

  Future<void> _insertTagIfNew(Tag tag) async {
    final existing =
        await _databaseService.getTagBySpotifyId(tag.spotifyId);
    if (existing != null) return;

    try {
      await _databaseService.insertTag(tag);
    } catch (e) {
      debugPrint('Error inserting tag ${tag.name}: $e');
    }
  }
}
