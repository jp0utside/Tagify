import 'package:flutter/foundation.dart';
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
}
