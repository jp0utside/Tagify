import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../models/tag.dart';
import '../models/user.dart';
import 'auth_service.dart';

class SpotifyService {
  final AuthService _authService;

  SpotifyService(this._authService);

  Map<String, String> _buildHeaders() {
    final token = _authService.accessToken;
    if (token == null) {
      throw Exception('No access token available');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<http.Response> _request(
    String method,
    String url, {
    String? body,
  }) async {
    var headers = _buildHeaders();
    var response = await _sendRequest(method, url, headers, body);

    if (response.statusCode == 401) {
      await _authService.refreshAccessToken();
      if (_authService.accessToken == null) {
        throw Exception('Session expired. Please log in again.');
      }
      headers = _buildHeaders();
      response = await _sendRequest(method, url, headers, body);
    }

    return response;
  }

  Future<http.Response> _sendRequest(
    String method,
    String url,
    Map<String, String> headers,
    String? body,
  ) async {
    final uri = Uri.parse(url);
    switch (method) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(uri, headers: headers, body: body);
      case 'PUT':
        return await http.put(uri, headers: headers, body: body);
      case 'DELETE':
        return await http.delete(uri, headers: headers, body: body);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  Future<User> getCurrentUser() async {
    final response = await _request('GET', 'https://api.spotify.com/v1/me');

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch user: ${response.statusCode}');
    }
  }

  Future<List<Song>> getLikedSongs({int limit = 50, int offset = 0}) async {
    final response = await _request(
      'GET',
      'https://api.spotify.com/v1/me/tracks?limit=$limit&offset=$offset',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? [];

      return items.map((item) {
        return Song.fromSpotifyTrack(item['track']);
      }).toList();
    } else {
      throw Exception('Failed to fetch liked songs: ${response.statusCode}');
    }
  }

  Future<int> getLikedSongsTotal() async {
    final response = await _request(
      'GET',
      'https://api.spotify.com/v1/me/tracks?limit=1&offset=0',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['total'] ?? 0;
    } else {
      throw Exception('Failed to fetch liked songs total: ${response.statusCode}');
    }
  }

  Future<List<Song>> getAllLikedSongs() async {
    final List<Song> allSongs = [];
    int offset = 0;
    const int limit = 50;

    while (true) {
      final songs = await getLikedSongs(limit: limit, offset: offset);
      allSongs.addAll(songs);

      if (songs.length < limit) {
        break;
      }

      offset += limit;
    }

    return allSongs;
  }

  Future<List<Tag>> getUserPlaylists({int limit = 50, int offset = 0}) async {
    final response = await _request(
      'GET',
      'https://api.spotify.com/v1/me/playlists?limit=$limit&offset=$offset',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? [];

      return items.map((playlist) {
        return Tag.fromSpotifyPlaylist(playlist);
      }).toList();
    } else {
      throw Exception('Failed to fetch playlists: ${response.statusCode}');
    }
  }

  Future<List<Tag>> getAllUserPlaylists() async {
    final List<Tag> allPlaylists = [];
    int offset = 0;
    const int limit = 50;

    while (true) {
      final playlists = await getUserPlaylists(limit: limit, offset: offset);
      allPlaylists.addAll(playlists);

      if (playlists.length < limit) {
        break;
      }

      offset += limit;
    }

    return allPlaylists;
  }

  Future<List<Song>> getPlaylistTracks(String playlistId, {int limit = 50, int offset = 0}) async {
    final response = await _request(
      'GET',
      'https://api.spotify.com/v1/playlists/$playlistId/tracks?limit=$limit&offset=$offset',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? [];

      return items
          .where((item) => item['track'] != null)
          .map((item) => Song.fromSpotifyTrack(item['track']))
          .toList();
    } else {
      throw Exception('Failed to fetch playlist tracks: ${response.statusCode}');
    }
  }

  Future<List<Song>> getAllPlaylistTracks(String playlistId) async {
    final List<Song> allTracks = [];
    int offset = 0;
    const int limit = 50;

    while (true) {
      final tracks = await getPlaylistTracks(playlistId, limit: limit, offset: offset);
      allTracks.addAll(tracks);

      if (tracks.length < limit) {
        break;
      }

      offset += limit;
    }

    return allTracks;
  }

  Future<Tag> createPlaylist(String name, {String? description, bool isPublic = false}) async {
    final user = await getCurrentUser();

    final response = await _request(
      'POST',
      'https://api.spotify.com/v1/users/${user.id}/playlists',
      body: jsonEncode({
        'name': name,
        'description': description ?? 'Created by Tagify',
        'public': isPublic,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Tag.fromSpotifyPlaylist(data);
    } else {
      throw Exception('Failed to create playlist: ${response.statusCode}');
    }
  }

  Future<void> updatePlaylist(String playlistId, {String? name, String? description}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;

    final response = await _request(
      'PUT',
      'https://api.spotify.com/v1/playlists/$playlistId',
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update playlist: ${response.statusCode}');
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    final response = await _request(
      'DELETE',
      'https://api.spotify.com/v1/playlists/$playlistId/followers',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete playlist: ${response.statusCode}');
    }
  }

  Future<void> addTracksToPlaylist(String playlistId, List<String> trackUris) async {
    final response = await _request(
      'POST',
      'https://api.spotify.com/v1/playlists/$playlistId/tracks',
      body: jsonEncode({'uris': trackUris}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add tracks to playlist: ${response.statusCode}');
    }
  }

  Future<void> removeTracksFromPlaylist(String playlistId, List<String> trackUris) async {
    final response = await _request(
      'DELETE',
      'https://api.spotify.com/v1/playlists/$playlistId/tracks',
      body: jsonEncode({
        'tracks': trackUris.map((uri) => {'uri': uri}).toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove tracks from playlist: ${response.statusCode}');
    }
  }

  Future<void> addTrackToQueue(String trackUri) async {
    final response = await _request(
      'POST',
      'https://api.spotify.com/v1/me/player/queue?uri=$trackUri',
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to add track to queue: ${response.statusCode}');
    }
  }

  Future<void> addTracksToQueue(List<String> trackUris) async {
    for (final uri in trackUris) {
      await addTrackToQueue(uri);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<List<Tag>> getTagifyTags() async {
    final allPlaylists = await getAllUserPlaylists();
    return allPlaylists.where((playlist) =>
      playlist.name.startsWith('#tag:')
    ).toList();
  }

  Future<Tag> createTagifyTag(String tagName) async {
    final playlistName = '#tag:$tagName';
    return await createPlaylist(
      playlistName,
      description: 'Created by Tagify - ${DateTime.now().toIso8601String()}',
    );
  }

  Future<void> ensureTagifyFolder() async {
    // Spotify doesn't have folders in the API
    // We use the #tag: prefix to identify Tagify tags
  }
}
