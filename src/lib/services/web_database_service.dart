import 'dart:async';
import 'dart:convert';
import '../models/song.dart';
import '../models/tag.dart';
import '../models/song_tag.dart';

/// Web-compatible database service that uses in-memory storage
class WebDatabaseService {
  static final WebDatabaseService _instance = WebDatabaseService._internal();
  factory WebDatabaseService() => _instance;
  WebDatabaseService._internal();

  // In-memory storage
  final List<Map<String, dynamic>> _songs = [];
  final List<Map<String, dynamic>> _tags = [];
  final List<Map<String, dynamic>> _songTags = [];
  
  int _songIdCounter = 1;
  int _tagIdCounter = 1;

  Future<void> init() async {
    // Initialize with sample data for web
    await _initializeSampleData();
  }

  Future<void> _initializeSampleData() async {
    // Add some sample songs
    await insertSong(Song(
      id: _songIdCounter++,
      spotifyId: 'sample1',
      title: 'Sample Song 1',
      artist: 'Sample Artist',
      album: 'Sample Album',
      durationMs: 180000,
      uri: 'spotify:track:sample1',
    ));

    await insertSong(Song(
      id: _songIdCounter++,
      spotifyId: 'sample2',
      title: 'Sample Song 2',
      artist: 'Sample Artist 2',
      album: 'Sample Album 2',
      durationMs: 200000,
      uri: 'spotify:track:sample2',
    ));

    // Add some sample tags
    await insertTag(Tag(
      id: _tagIdCounter++,
      spotifyId: 'tag1',
      name: 'Rock',
      description: 'Rock music',
      type: TagType.tag,
      isPublic: false,
    ));

    await insertTag(Tag(
      id: _tagIdCounter++,
      spotifyId: 'tag2',
      name: 'Chill',
      description: 'Chill music',
      type: TagType.tag,
      isPublic: false,
    ));
  }

  // Song operations
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
      final songData = _songs.firstWhere((song) => song['spotify_id'] == spotifyId);
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

  // Tag operations
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
      final tagData = _tags.firstWhere((tag) => tag['spotify_id'] == spotifyId);
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

  // Song-Tag relationship operations
  Future<void> addSongToTag(int songId, int tagId) async {
    _songTags.add({
      'song_id': songId,
      'tag_id': tagId,
    });
  }

  Future<void> removeSongFromTag(int songId, int tagId) async {
    _songTags.removeWhere((st) => st['song_id'] == songId && st['tag_id'] == tagId);
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

  // Query operations
  Future<List<Song>> executeQuery({
    required List<int> andTags,
    required List<int> orTags,
    required List<int> notTags,
  }) async {
    List<int> candidateSongIds = [];
    
    // Get songs that match OR tags
    if (orTags.isNotEmpty) {
      final orSongIds = _songTags
          .where((st) => orTags.contains(st['tag_id']))
          .map((st) => st['song_id'] as int)
          .toSet()
          .toList();
      candidateSongIds.addAll(orSongIds);
    }
    
    // Filter by AND tags
    if (andTags.isNotEmpty) {
      final andSongIds = <int>[];
      for (final songId in candidateSongIds) {
        final songTagIds = _songTags
            .where((st) => st['song_id'] == songId)
            .map((st) => st['tag_id'] as int)
            .toSet();
        
        if (andTags.every((tagId) => songTagIds.contains(tagId))) {
          andSongIds.add(songId);
        }
      }
      candidateSongIds = andSongIds;
    }
    
    // Remove songs with NOT tags
    if (notTags.isNotEmpty) {
      final notSongIds = _songTags
          .where((st) => notTags.contains(st['tag_id']))
          .map((st) => st['song_id'] as int)
          .toSet();
      
      candidateSongIds = candidateSongIds
          .where((songId) => !notSongIds.contains(songId))
          .toList();
    }
    
    return _songs
        .where((song) => candidateSongIds.contains(song['id']))
        .map((data) => Song.fromJson(data))
        .toList();
  }

  // Utility operations
  Future<int> getSongCount() async {
    return _songs.length;
  }

  Future<int> getTagCount() async {
    return _tags.length;
  }

  Future<Map<String, int>> getTagSongCounts() async {
    final Map<String, int> counts = {};
    for (final tag in _tags) {
      final count = _songTags.where((st) => st['tag_id'] == tag['id']).length;
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

  Future<void> close() async {
    // No-op for in-memory storage
  }
}
