import 'package:tagify/models/song.dart';
import 'package:tagify/models/tag.dart';
import 'package:tagify/models/user.dart';
import 'package:tagify/services/auth_service.dart';
import 'package:tagify/services/spotify_service.dart';
import 'package:tagify/services/database_service.dart';

class MockAuthService extends AuthService {
  @override
  String? get accessToken => 'mock_token';

  @override
  bool get isAuthenticated => true;

  @override
  User? get user => User(id: 'user1', displayName: 'Test User');
}

class MockSpotifyService extends SpotifyService {
  List<Song> likedSongs = [];
  List<Tag> playlists = [];
  Map<String, List<Song>> playlistTracks = {};
  List<Tag> createdTags = [];
  List<String> deletedPlaylistIds = [];
  Map<String, Map<String, String?>> updatedPlaylists = {};
  Map<String, List<String>> addedTracks = {};
  Map<String, List<String>> removedTracks = {};
  bool shouldFail = false;

  MockSpotifyService() : super(MockAuthService());

  @override
  Future<int> getLikedSongsTotal() async {
    if (shouldFail) throw Exception('API Error');
    return likedSongs.length;
  }

  @override
  Future<List<Song>> getLikedSongs({int limit = 50, int offset = 0}) async {
    if (shouldFail) throw Exception('API Error');
    final end = (offset + limit).clamp(0, likedSongs.length);
    if (offset >= likedSongs.length) return [];
    return likedSongs.sublist(offset, end);
  }

  @override
  Future<List<Song>> getAllLikedSongs() async {
    if (shouldFail) throw Exception('API Error');
    return likedSongs;
  }

  @override
  Future<List<Tag>> getUserPlaylists({int limit = 50, int offset = 0}) async {
    if (shouldFail) throw Exception('API Error');
    final end = (offset + limit).clamp(0, playlists.length);
    if (offset >= playlists.length) return [];
    return playlists.sublist(offset, end);
  }

  @override
  Future<List<Tag>> getAllUserPlaylists() async {
    if (shouldFail) throw Exception('API Error');
    return playlists;
  }

  @override
  Future<List<Song>> getPlaylistTracks(String playlistId, {int limit = 50, int offset = 0}) async {
    if (shouldFail) throw Exception('API Error');
    return playlistTracks[playlistId] ?? [];
  }

  @override
  Future<List<Song>> getAllPlaylistTracks(String playlistId) async {
    if (shouldFail) throw Exception('API Error');
    return playlistTracks[playlistId] ?? [];
  }

  @override
  Future<Tag> createTagifyTag(String tagName) async {
    if (shouldFail) throw Exception('API Error');
    final tag = Tag(
      spotifyId: 'spotify_${tagName.hashCode}',
      name: tagName,
      description: 'Created by Tagify',
      type: TagType.tag,
    );
    createdTags.add(tag);
    return tag;
  }

  @override
  Future<void> updatePlaylist(String playlistId,
      {String? name, String? description}) async {
    if (shouldFail) throw Exception('API Error');
    updatedPlaylists[playlistId] = {'name': name, 'description': description};
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    if (shouldFail) throw Exception('API Error');
    deletedPlaylistIds.add(playlistId);
  }

  @override
  Future<void> addTracksToPlaylist(String playlistId, List<String> trackUris) async {
    if (shouldFail) throw Exception('API Error');
    addedTracks.putIfAbsent(playlistId, () => []);
    addedTracks[playlistId]!.addAll(trackUris);
  }

  @override
  Future<void> removeTracksFromPlaylist(String playlistId, List<String> trackUris) async {
    if (shouldFail) throw Exception('API Error');
    removedTracks.putIfAbsent(playlistId, () => []);
    removedTracks[playlistId]!.addAll(trackUris);
  }

  @override
  Future<User> getCurrentUser() async {
    return User(id: 'user1', displayName: 'Test User');
  }
}

class MockDatabaseService extends DatabaseService {
  final List<Song> _songs = [];
  final List<Tag> _tags = [];
  final Map<int, Set<int>> _songTags = {}; // tagId -> set of songIds
  int _nextSongId = 1;
  int _nextTagId = 1;

  @override
  Future<void> init() async {}

  @override
  Future<int> insertSong(Song song) async {
    final existing = _songs.where((s) => s.spotifyId == song.spotifyId);
    if (existing.isNotEmpty) {
      throw Exception('Song already exists');
    }
    final id = _nextSongId++;
    _songs.add(Song(
      id: id,
      spotifyId: song.spotifyId,
      title: song.title,
      artist: song.artist,
      album: song.album,
      durationMs: song.durationMs,
      uri: song.uri,
    ));
    return id;
  }

  @override
  Future<List<Song>> getAllSongs() async => List.from(_songs);

  @override
  Future<Song?> getSongBySpotifyId(String spotifyId) async {
    try {
      return _songs.firstWhere((s) => s.spotifyId == spotifyId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> insertTag(Tag tag) async {
    final id = _nextTagId++;
    _tags.add(Tag(
      id: id,
      spotifyId: tag.spotifyId,
      name: tag.name,
      description: tag.description,
      type: tag.type,
      isPublic: tag.isPublic,
    ));
    return id;
  }

  @override
  Future<List<Tag>> getAllTags() async => List.from(_tags);

  @override
  Future<List<Tag>> getTagsByType(TagType type) async =>
      _tags.where((t) => t.type == type).toList();

  @override
  Future<Tag?> getTagBySpotifyId(String spotifyId) async {
    try {
      return _tags.firstWhere((t) => t.spotifyId == spotifyId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateTag(Tag tag) async {
    final index = _tags.indexWhere((t) => t.id == tag.id);
    if (index != -1) {
      _tags[index] = tag;
    }
  }

  @override
  Future<void> deleteTag(int tagId) async {
    _tags.removeWhere((t) => t.id == tagId);
    _songTags.remove(tagId);
  }

  @override
  Future<void> addSongToTag(int songId, int tagId) async {
    _songTags.putIfAbsent(tagId, () => {});
    if (_songTags[tagId]!.contains(songId)) {
      throw Exception('Relationship already exists');
    }
    _songTags[tagId]!.add(songId);
  }

  @override
  Future<void> removeSongFromTag(int songId, int tagId) async {
    _songTags[tagId]?.remove(songId);
  }

  @override
  Future<List<Tag>> getTagsForSong(int songId) async {
    final tagIds = <int>[];
    for (final entry in _songTags.entries) {
      if (entry.value.contains(songId)) {
        tagIds.add(entry.key);
      }
    }
    return _tags.where((t) => tagIds.contains(t.id)).toList();
  }

  @override
  Future<int> getSongCount() async => _songs.length;

  @override
  Future<int> getTagCount() async => _tags.length;

  @override
  Future<Map<String, int>> getTagSongCounts() async {
    final Map<String, int> counts = {};
    for (final tag in _tags) {
      counts[tag.name] = _songTags[tag.id]?.length ?? 0;
    }
    return counts;
  }

  @override
  Future<void> clearAllData() async {
    _songs.clear();
    _tags.clear();
    _songTags.clear();
  }
}
