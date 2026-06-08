import 'dart:async';
import '../models/song.dart';
import '../models/tag.dart';

class WebDatabaseService {
  static final WebDatabaseService _instance = WebDatabaseService._internal();
  factory WebDatabaseService() => _instance;
  WebDatabaseService._internal();

  final List<Map<String, dynamic>> _songs = [];
  final List<Map<String, dynamic>> _tags = [];
  final List<Map<String, dynamic>> _songTags = [];

  int _songIdCounter = 1;
  int _tagIdCounter = 1;

  Future<void> init() async {}

  Future<int> insertSong(Song song) async {
    final songData = song.toJson();
    songData['id'] = _songIdCounter++;
    _songs.add(songData);
    return songData['id'];
  }

  Future<List<Song>> getAllSongs() async {
    return _songs.map((data) => Song.fromJson(data)).toList();
  }

  Future<Song?> getSongBySpotifyId(String spotifyId) async {
    try {
      final songData =
          _songs.firstWhere((song) => song['spotify_id'] == spotifyId);
      return Song.fromJson(songData);
    } catch (e) {
      return null;
    }
  }

  Future<List<Song>> getSongsByTag(int tagId) async {
    final songIds = _songTags
        .where((st) => st['tag_id'] == tagId)
        .map((st) => st['song_id'] as int)
        .toList();

    return _songs
        .where((song) => songIds.contains(song['id']))
        .map((data) => Song.fromJson(data))
        .toList();
  }

  Future<void> deleteSong(int songId) async {
    _songs.removeWhere((song) => song['id'] == songId);
    _songTags.removeWhere((st) => st['song_id'] == songId);
  }

  Future<int> insertTag(Tag tag) async {
    final tagData = tag.toJson();
    tagData['id'] = _tagIdCounter++;
    _tags.add(tagData);
    return tagData['id'];
  }

  Future<List<Tag>> getAllTags() async {
    return _tags.map((data) => Tag.fromJson(data)).toList();
  }

  Future<List<Tag>> getTagsByType(TagType type) async {
    return _tags
        .where((tag) => tag['type'] == type.toString().split('.').last)
        .map((data) => Tag.fromJson(data))
        .toList();
  }

  Future<Tag?> getTagBySpotifyId(String spotifyId) async {
    try {
      final tagData =
          _tags.firstWhere((tag) => tag['spotify_id'] == spotifyId);
      return Tag.fromJson(tagData);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateTag(Tag tag) async {
    final index = _tags.indexWhere((t) => t['id'] == tag.id);
    if (index != -1) {
      _tags[index] = tag.toJson();
    }
  }

  Future<void> deleteTag(int tagId) async {
    _tags.removeWhere((tag) => tag['id'] == tagId);
    _songTags.removeWhere((st) => st['tag_id'] == tagId);
  }

  Future<void> addSongToTag(int songId, int tagId) async {
    _songTags.add({
      'song_id': songId,
      'tag_id': tagId,
    });
  }

  Future<void> removeSongFromTag(int songId, int tagId) async {
    _songTags
        .removeWhere((st) => st['song_id'] == songId && st['tag_id'] == tagId);
  }

  Future<List<Tag>> getTagsForSong(int songId) async {
    final tagIds = _songTags
        .where((st) => st['song_id'] == songId)
        .map((st) => st['tag_id'] as int)
        .toList();

    return _tags
        .where((tag) => tagIds.contains(tag['id']))
        .map((data) => Tag.fromJson(data))
        .toList();
  }

  Future<List<Song>> getSongsForTags(List<int> tagIds) async {
    if (tagIds.isEmpty) return [];

    final songIds = _songTags
        .where((st) => tagIds.contains(st['tag_id']))
        .map((st) => st['song_id'] as int)
        .toSet()
        .toList();

    return _songs
        .where((song) => songIds.contains(song['id']))
        .map((data) => Song.fromJson(data))
        .toList();
  }

  Future<List<Song>> executeQuery({
    required List<int> andTags,
    required List<int> orTags,
    required List<int> notTags,
  }) async {
    Set<int> candidateSongIds = {};

    if (andTags.isNotEmpty) {
      final allSongIds = _songs.map((s) => s['id'] as int).toSet();
      candidateSongIds = allSongIds;
      for (final tagId in andTags) {
        final tagSongIds = _songTags
            .where((st) => st['tag_id'] == tagId)
            .map((st) => st['song_id'] as int)
            .toSet();
        candidateSongIds = candidateSongIds.intersection(tagSongIds);
      }
    }

    if (orTags.isNotEmpty) {
      final orSongIds = _songTags
          .where((st) => orTags.contains(st['tag_id']))
          .map((st) => st['song_id'] as int)
          .toSet();
      if (andTags.isNotEmpty) {
        candidateSongIds = candidateSongIds.union(orSongIds);
      } else {
        candidateSongIds = orSongIds;
      }
    }

    if (notTags.isNotEmpty) {
      final notSongIds = _songTags
          .where((st) => notTags.contains(st['tag_id']))
          .map((st) => st['song_id'] as int)
          .toSet();
      candidateSongIds =
          candidateSongIds.difference(notSongIds);
    }

    return _songs
        .where((song) => candidateSongIds.contains(song['id']))
        .map((data) => Song.fromJson(data))
        .toList();
  }

  Future<int> getSongCount() async => _songs.length;

  Future<int> getTagCount() async => _tags.length;

  Future<Map<String, int>> getTagSongCounts() async {
    final Map<String, int> counts = {};
    for (final tag in _tags) {
      final count =
          _songTags.where((st) => st['tag_id'] == tag['id']).length;
      counts[tag['name'] as String] = count;
    }
    return counts;
  }

  Future<void> clearAllData() async {
    _songs.clear();
    _tags.clear();
    _songTags.clear();
    _songIdCounter = 1;
    _tagIdCounter = 1;
  }

  Future<void> close() async {}
}
