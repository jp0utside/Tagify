import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/tag.dart';
import 'spotify_service.dart';
import 'database_service.dart';

class TagValidationResult {
  final bool isValid;
  final String? errorMessage;

  TagValidationResult({required this.isValid, this.errorMessage});
}

class TagService extends ChangeNotifier {
  final SpotifyService _spotifyService;
  final DatabaseService _databaseService;

  List<Tag> _tags = [];
  Map<int, int> _tagSongCounts = {};
  bool _isLoading = false;

  List<Tag> get tags => _tags;
  List<Tag> get userTags =>
      _tags.where((t) => t.type == TagType.tag).toList();
  List<Tag> get playlists =>
      _tags.where((t) => t.type == TagType.playlist).toList();
  Map<int, int> get tagSongCounts => _tagSongCounts;
  bool get isLoading => _isLoading;

  TagService({
    required SpotifyService spotifyService,
    required DatabaseService databaseService,
  })  : _spotifyService = spotifyService,
        _databaseService = databaseService;

  Future<void> loadTags() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tags = await _databaseService.getAllTags();
      await _loadSongCounts();
    } catch (e) {
      debugPrint('Error loading tags: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSongCounts() async {
    final counts = await _databaseService.getTagSongCounts();
    _tagSongCounts = {};
    for (final tag in _tags) {
      if (tag.id != null) {
        _tagSongCounts[tag.id!] = counts[tag.name] ?? 0;
      }
    }
  }

  int songCountForTag(Tag tag) {
    if (tag.id == null) return 0;
    return _tagSongCounts[tag.id!] ?? 0;
  }

  TagValidationResult validateTagName(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return TagValidationResult(
        isValid: false,
        errorMessage: 'Tag name cannot be empty',
      );
    }

    if (trimmed.length > 95) {
      return TagValidationResult(
        isValid: false,
        errorMessage: 'Tag name must be 95 characters or less',
      );
    }

    final duplicate = _tags.any(
      (t) =>
          t.type == TagType.tag &&
          t.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) {
      return TagValidationResult(
        isValid: false,
        errorMessage: 'A tag with this name already exists',
      );
    }

    return TagValidationResult(isValid: true);
  }

  Future<Tag?> createTag(String name) async {
    final trimmed = name.trim();
    final validation = validateTagName(trimmed);
    if (!validation.isValid) {
      throw Exception(validation.errorMessage);
    }

    try {
      final spotifyTag = await _spotifyService.createTagifyTag(trimmed);

      final tag = Tag(
        spotifyId: spotifyTag.spotifyId,
        name: trimmed,
        description: spotifyTag.description,
        type: TagType.tag,
      );

      await _databaseService.insertTag(tag);
      await loadTags();
      return tag;
    } catch (e) {
      debugPrint('Error creating tag: $e');
      rethrow;
    }
  }

  Future<void> renameTag(Tag tag, String newName) async {
    final trimmed = newName.trim();

    if (trimmed.isEmpty) {
      throw Exception('Tag name cannot be empty');
    }

    if (trimmed.length > 95) {
      throw Exception('Tag name must be 95 characters or less');
    }

    if (tag.type != TagType.tag) {
      throw Exception('Cannot rename imported playlists');
    }

    final duplicate = _tags.any(
      (t) =>
          t.type == TagType.tag &&
          t.id != tag.id &&
          t.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) {
      throw Exception('A tag with this name already exists');
    }

    try {
      await _spotifyService.updatePlaylist(
        tag.spotifyId,
        name: '#tag:$trimmed',
      );

      final updatedTag = Tag(
        id: tag.id,
        spotifyId: tag.spotifyId,
        name: trimmed,
        description: tag.description,
        type: tag.type,
        isPublic: tag.isPublic,
        createdAt: tag.createdAt,
      );

      await _databaseService.updateTag(updatedTag);
      await loadTags();
    } catch (e) {
      debugPrint('Error renaming tag: $e');
      rethrow;
    }
  }

  Future<void> deleteTag(Tag tag) async {
    if (tag.type != TagType.tag) {
      throw Exception('Cannot delete imported playlists');
    }

    try {
      await _spotifyService.deletePlaylist(tag.spotifyId);
      await _databaseService.deleteTag(tag.id!);
      await loadTags();
    } catch (e) {
      debugPrint('Error deleting tag: $e');
      rethrow;
    }
  }

  // Song tagging operations

  Future<List<Tag>> getTagsForSong(Song song) async {
    if (song.id == null) return [];
    return await _databaseService.getTagsForSong(song.id!);
  }

  Future<void> addTagToSong(Song song, Tag tag) async {
    if (song.id == null || tag.id == null) {
      throw Exception('Song and tag must be saved to database first');
    }

    await _databaseService.addSongToTag(song.id!, tag.id!);
    notifyListeners();

    try {
      if (song.uri != null) {
        await _spotifyService.addTracksToPlaylist(
          tag.spotifyId,
          [song.uri!],
        );
      }
      await _loadSongCounts();
      notifyListeners();
    } catch (e) {
      await _databaseService.removeSongFromTag(song.id!, tag.id!);
      notifyListeners();
      debugPrint('Error adding tag to song, rolled back: $e');
      rethrow;
    }
  }

  Future<void> removeTagFromSong(Song song, Tag tag) async {
    if (song.id == null || tag.id == null) {
      throw Exception('Song and tag must be saved to database first');
    }

    await _databaseService.removeSongFromTag(song.id!, tag.id!);
    notifyListeners();

    try {
      if (song.uri != null) {
        await _spotifyService.removeTracksFromPlaylist(
          tag.spotifyId,
          [song.uri!],
        );
      }
      await _loadSongCounts();
      notifyListeners();
    } catch (e) {
      await _databaseService.addSongToTag(song.id!, tag.id!);
      notifyListeners();
      debugPrint('Error removing tag from song, rolled back: $e');
      rethrow;
    }
  }

  Future<int> batchAddTagToSongs({
    required List<Song> songs,
    required Tag tag,
    void Function(int completed, int total)? onProgress,
  }) async {
    if (tag.id == null) throw Exception('Tag must be saved to database first');

    int successCount = 0;
    final urisToAdd = <String>[];

    for (int i = 0; i < songs.length; i++) {
      final song = songs[i];
      if (song.id == null) continue;

      try {
        await _databaseService.addSongToTag(song.id!, tag.id!);
        if (song.uri != null) urisToAdd.add(song.uri!);
        successCount++;
      } catch (e) {
        debugPrint('Skipping duplicate song-tag: ${song.title}');
      }
      onProgress?.call(i + 1, songs.length);
    }

    if (urisToAdd.isNotEmpty) {
      try {
        for (int i = 0; i < urisToAdd.length; i += 100) {
          final batch = urisToAdd.sublist(
            i,
            i + 100 > urisToAdd.length ? urisToAdd.length : i + 100,
          );
          await _spotifyService.addTracksToPlaylist(tag.spotifyId, batch);
        }
      } catch (e) {
        debugPrint('Spotify batch sync failed (local DB still updated): $e');
      }
    }

    await _loadSongCounts();
    notifyListeners();
    return successCount;
  }

  Future<int> batchRemoveTagFromSongs({
    required List<Song> songs,
    required Tag tag,
    void Function(int completed, int total)? onProgress,
  }) async {
    if (tag.id == null) throw Exception('Tag must be saved to database first');

    int successCount = 0;
    final urisToRemove = <String>[];

    for (int i = 0; i < songs.length; i++) {
      final song = songs[i];
      if (song.id == null) continue;

      try {
        await _databaseService.removeSongFromTag(song.id!, tag.id!);
        if (song.uri != null) urisToRemove.add(song.uri!);
        successCount++;
      } catch (e) {
        debugPrint('Error removing song-tag: ${song.title}');
      }
      onProgress?.call(i + 1, songs.length);
    }

    if (urisToRemove.isNotEmpty) {
      try {
        for (int i = 0; i < urisToRemove.length; i += 100) {
          final batch = urisToRemove.sublist(
            i,
            i + 100 > urisToRemove.length ? urisToRemove.length : i + 100,
          );
          await _spotifyService.removeTracksFromPlaylist(tag.spotifyId, batch);
        }
      } catch (e) {
        debugPrint('Spotify batch sync failed (local DB still updated): $e');
      }
    }

    await _loadSongCounts();
    notifyListeners();
    return successCount;
  }
}
