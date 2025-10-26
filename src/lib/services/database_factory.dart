import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'web_database_service.dart';

/// Factory class to create the appropriate database service based on platform
class DatabaseFactory {
  static DatabaseService? _databaseService;
  static WebDatabaseService? _webDatabaseService;

  static Future<void> init() async {
    if (kIsWeb) {
      _webDatabaseService = WebDatabaseService();
      await _webDatabaseService!.init();
    } else {
      _databaseService = DatabaseService();
      await _databaseService!.init();
    }
  }

  // Song operations
  static Future<int> insertSong(dynamic song) async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.insertSong(song);
    } else if (_databaseService != null) {
      return await _databaseService!.insertSong(song);
    }
    throw Exception('Database not initialized');
  }

  static Future<List<dynamic>> getAllSongs() async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.getAllSongs();
    } else if (_databaseService != null) {
      return await _databaseService!.getAllSongs();
    }
    throw Exception('Database not initialized');
  }

  static Future<dynamic> getSongBySpotifyId(String spotifyId) async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.getSongBySpotifyId(spotifyId);
    } else if (_databaseService != null) {
      return await _databaseService!.getSongBySpotifyId(spotifyId);
    }
    throw Exception('Database not initialized');
  }

  static Future<List<dynamic>> getSongsByTag(int tagId) async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.getSongsByTag(tagId);
    } else if (_databaseService != null) {
      return await _databaseService!.getSongsByTag(tagId);
    }
    throw Exception('Database not initialized');
  }

  static Future<void> deleteSong(int songId) async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.deleteSong(songId);
    } else if (_databaseService != null) {
      return await _databaseService!.deleteSong(songId);
    }
    throw Exception('Database not initialized');
  }

  // Tag operations
  static Future<int> insertTag(dynamic tag) async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.insertTag(tag);
    } else if (_databaseService != null) {
      return await _databaseService!.insertTag(tag);
    }
    throw Exception('Database not initialized');
  }

  static Future<List<dynamic>> getAllTags() async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.getAllTags();
    } else if (_databaseService != null) {
      return await _databaseService!.getAllTags();
    }
    throw Exception('Database not initialized');
  }

  static Future<List<dynamic>> getTagsByType(dynamic type) async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.getTagsByType(type);
    } else if (_databaseService != null) {
      return await _databaseService!.getTagsByType(type);
    }
    throw Exception('Database not initialized');
  }

  static Future<dynamic> getTagBySpotifyId(String spotifyId) async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.getTagBySpotifyId(spotifyId);
    } else if (_databaseService != null) {
      return await _databaseService!.getTagBySpotifyId(spotifyId);
    }
    throw Exception('Database not initialized');
  }

  static Future<void> updateTag(dynamic tag) async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.updateTag(tag);
    } else if (_databaseService != null) {
      return await _databaseService!.updateTag(tag);
    }
    throw Exception('Database not initialized');
  }

  static Future<void> deleteTag(int tagId) async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.deleteTag(tagId);
    } else if (_databaseService != null) {
      return await _databaseService!.deleteTag(tagId);
    }
    throw Exception('Database not initialized');
  }

  // Song-Tag relationship operations
  static Future<void> addSongToTag(int songId, int tagId) async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.addSongToTag(songId, tagId);
    } else if (_databaseService != null) {
      return await _databaseService!.addSongToTag(songId, tagId);
    }
    throw Exception('Database not initialized');
  }

  static Future<void> removeSongFromTag(int songId, int tagId) async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.removeSongFromTag(songId, tagId);
    } else if (_databaseService != null) {
      return await _databaseService!.removeSongFromTag(songId, tagId);
    }
    throw Exception('Database not initialized');
  }

  static Future<List<dynamic>> getTagsForSong(int songId) async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.getTagsForSong(songId);
    } else if (_databaseService != null) {
      return await _databaseService!.getTagsForSong(songId);
    }
    throw Exception('Database not initialized');
  }

  static Future<List<dynamic>> getSongsForTags(List<int> tagIds) async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.getSongsForTags(tagIds);
    } else if (_databaseService != null) {
      return await _databaseService!.getSongsForTags(tagIds);
    }
    throw Exception('Database not initialized');
  }

  // Query operations
  static Future<List<dynamic>> executeQuery({
    required List<int> andTags,
    required List<int> orTags,
    required List<int> notTags,
  }) async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.executeQuery(
        andTags: andTags,
        orTags: orTags,
        notTags: notTags,
      );
    } else if (_databaseService != null) {
      return await _databaseService!.executeQuery(
        andTags: andTags,
        orTags: orTags,
        notTags: notTags,
      );
    }
    throw Exception('Database not initialized');
  }

  // Utility operations
  static Future<int> getSongCount() async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.getSongCount();
    } else if (_databaseService != null) {
      return await _databaseService!.getSongCount();
    }
    throw Exception('Database not initialized');
  }

  static Future<int> getTagCount() async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.getTagCount();
    } else if (_databaseService != null) {
      return await _databaseService!.getTagCount();
    }
    throw Exception('Database not initialized');
  }

  static Future<Map<String, int>> getTagSongCounts() async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.getTagSongCounts();
    } else if (_databaseService != null) {
      return await _databaseService!.getTagSongCounts();
    }
    throw Exception('Database not initialized');
  }

  static Future<void> clearAllData() async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.clearAllData();
    } else if (_databaseService != null) {
      return await _databaseService!.clearAllData();
    }
    throw Exception('Database not initialized');
  }

  static Future<void> close() async {
    if (kIsWeb && _webDatabaseService != null) {
      return await _webDatabaseService!.close();
    } else if (_databaseService != null) {
      return await _databaseService!.close();
    }
  }
}
