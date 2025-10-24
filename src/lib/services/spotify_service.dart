import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../models/tag.dart';
import '../models/user.dart';
import 'auth_service.dart';

class SpotifyService {
  final AuthService _authService;
  
  SpotifyService(this._authService);

  Future<Map<String, String>> _getHeaders() async {
    final token = _authService.accessToken;
    if (token == null) {
      throw Exception('No access token available');
    }
    
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<User> getCurrentUser() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch user: ${response.statusCode}');
    }
  }

  Future<List<Song>> getLikedSongs({int limit = 50, int offset = 0}) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me/tracks?limit=$limit&offset=$offset'),
      headers: headers,
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

  Future<List<Song>> getAllLikedSongs() async {
    final List<Song> allSongs = [];
    int offset = 0;
    const int limit = 50;
    
    while (true) {
      final songs = await getLikedSongs(limit: limit, offset: offset);
      allSongs.addAll(songs);
      
      if (songs.length < limit) {
        break; // No more songs
      }
      
      offset += limit;
    }
    
    return allSongs;
  }

  Future<List<Tag>> getUserPlaylists({int limit = 50, int offset = 0}) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me/playlists?limit=$limit&offset=$offset'),
      headers: headers,
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
        break; // No more playlists
      }
      
      offset += limit;
    }
    
    return allPlaylists;
  }

  Future<List<Song>> getPlaylistTracks(String playlistId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? [];
      
      return items.map((item) {
        return Song.fromSpotifyTrack(item['track']);
      }).toList();
    } else {
      throw Exception('Failed to fetch playlist tracks: ${response.statusCode}');
    }
  }

  Future<Tag> createPlaylist(String name, {String? description, bool isPublic = false}) async {
    final user = await getCurrentUser();
    final headers = await _getHeaders();
    
    final body = {
      'name': name,
      'description': description ?? 'Created by Tagify',
      'public': isPublic,
    };

    final response = await http.post(
      Uri.parse('https://api.spotify.com/v1/users/${user.id}/playlists'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Tag.fromSpotifyPlaylist(data);
    } else {
      throw Exception('Failed to create playlist: ${response.statusCode}');
    }
  }

  Future<void> updatePlaylist(String playlistId, {String? name, String? description}) async {
    final headers = await _getHeaders();
    final body = <String, dynamic>{};
    
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;

    final response = await http.put(
      Uri.parse('https://api.spotify.com/v1/playlists/$playlistId'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update playlist: ${response.statusCode}');
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/followers'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete playlist: ${response.statusCode}');
    }
  }

  Future<void> addTracksToPlaylist(String playlistId, List<String> trackUris) async {
    final headers = await _getHeaders();
    
    final body = {
      'uris': trackUris,
    };

    final response = await http.post(
      Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add tracks to playlist: ${response.statusCode}');
    }
  }

  Future<void> removeTracksFromPlaylist(String playlistId, List<String> trackUris) async {
    final headers = await _getHeaders();
    
    final body = {
      'tracks': trackUris.map((uri) => {'uri': uri}).toList(),
    };

    final response = await http.delete(
      Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove tracks from playlist: ${response.statusCode}');
    }
  }

  Future<void> addTrackToQueue(String trackUri) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('https://api.spotify.com/v1/me/player/queue?uri=$trackUri'),
      headers: headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to add track to queue: ${response.statusCode}');
    }
  }

  Future<void> addTracksToQueue(List<String> trackUris) async {
    for (final uri in trackUris) {
      await addTrackToQueue(uri);
      // Add small delay to respect rate limits
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
    // This is a placeholder - Spotify doesn't have folders in the API
    // We'll use the #tag: prefix to identify Tagify tags
    // In the future, we could create a special playlist to act as a folder
  }
}
