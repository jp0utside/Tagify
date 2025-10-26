import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import '../models/song.dart';
import '../models/tag.dart';
import '../models/song_tag.dart';
import 'web_database_service.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'tagify.db';
  static const int _databaseVersion = 1;
  static bool _initialized = false;
  static WebDatabaseService? _webService;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<void> init() async {
    if (!_initialized) {
      if (kIsWeb) {
        // Use web database service for web platform
        _webService = WebDatabaseService();
        await _webService!.init();
      } else {
        // For mobile/desktop platforms
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        await database;
      }
      _initialized = true;
    }
  }

  Future<Database> _initDatabase() async {
    String path;
    
    if (kIsWeb) {
      // For web, use a simple path
      path = _databaseName;
    } else {
      // For mobile/desktop, use the proper databases path
      final databasesPath = await getDatabasesPath();
      path = join(databasesPath, _databaseName);
    }

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create songs table
    await db.execute('''
      CREATE TABLE songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        spotify_id TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT NOT NULL,
        duration_ms INTEGER,
        uri TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create tags table
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        spotify_id TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL CHECK (type IN ('tag', 'playlist')),
        is_public BOOLEAN DEFAULT FALSE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create song_tags junction table
    await db.execute('''
      CREATE TABLE song_tags (
        song_id INTEGER,
        tag_id INTEGER,
        PRIMARY KEY (song_id, tag_id),
        FOREIGN KEY (song_id) REFERENCES songs (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_songs_spotify_id ON songs(spotify_id)');
    await db.execute('CREATE INDEX idx_tags_type ON tags(type)');
    await db.execute('CREATE INDEX idx_tags_spotify_id ON tags(spotify_id)');
    await db.execute('CREATE INDEX idx_song_tags_song_id ON song_tags(song_id)');
    await db.execute('CREATE INDEX idx_song_tags_tag_id ON song_tags(tag_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Example migration for version 2
      // await db.execute('ALTER TABLE songs ADD COLUMN new_field TEXT');
    }
  }

  // Song operations
  Future<int> insertSong(Song song) async {
    if (kIsWeb && _webService != null) {
      return await _webService!.insertSong(song);
    }
    final db = await database;
    return await db.insert('songs', song.toJson());
  }

  Future<List<Song>> getAllSongs() async {
    if (kIsWeb && _webService != null) {
      return await _webService!.getAllSongs();
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('songs');
    return List.generate(maps.length, (i) => Song.fromJson(maps[i]));
  }

  Future<Song?> getSongBySpotifyId(String spotifyId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'songs',
      where: 'spotify_id = ?',
      whereArgs: [spotifyId],
    );
    
    if (maps.isNotEmpty) {
      return Song.fromJson(maps.first);
    }
    return null;
  }

  Future<List<Song>> getSongsByTag(int tagId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN song_tags st ON s.id = st.song_id
      WHERE st.tag_id = ?
      ORDER BY s.title
    ''', [tagId]);
    
    return List.generate(maps.length, (i) => Song.fromJson(maps[i]));
  }

  Future<void> deleteSong(int songId) async {
    final db = await database;
    await db.delete('songs', where: 'id = ?', whereArgs: [songId]);
  }

  // Tag operations
  Future<int> insertTag(Tag tag) async {
    final db = await database;
    return await db.insert('tags', tag.toJson());
  }

  Future<List<Tag>> getAllTags() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tags',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Tag.fromJson(maps[i]));
  }

  Future<List<Tag>> getTagsByType(TagType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tags',
      where: 'type = ?',
      whereArgs: [type.toString().split('.').last],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Tag.fromJson(maps[i]));
  }

  Future<Tag?> getTagBySpotifyId(String spotifyId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tags',
      where: 'spotify_id = ?',
      whereArgs: [spotifyId],
    );
    
    if (maps.isNotEmpty) {
      return Tag.fromJson(maps.first);
    }
    return null;
  }

  Future<void> updateTag(Tag tag) async {
    final db = await database;
    await db.update(
      'tags',
      tag.toJson(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  Future<void> deleteTag(int tagId) async {
    final db = await database;
    await db.delete('tags', where: 'id = ?', whereArgs: [tagId]);
  }

  // Song-Tag relationship operations
  Future<void> addSongToTag(int songId, int tagId) async {
    final db = await database;
    await db.insert('song_tags', {
      'song_id': songId,
      'tag_id': tagId,
    });
  }

  Future<void> removeSongFromTag(int songId, int tagId) async {
    final db = await database;
    await db.delete(
      'song_tags',
      where: 'song_id = ? AND tag_id = ?',
      whereArgs: [songId, tagId],
    );
  }

  Future<List<Tag>> getTagsForSong(int songId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.* FROM tags t
      INNER JOIN song_tags st ON t.id = st.tag_id
      WHERE st.song_id = ?
      ORDER BY t.name
    ''', [songId]);
    
    return List.generate(maps.length, (i) => Tag.fromJson(maps[i]));
  }

  Future<List<Song>> getSongsForTags(List<int> tagIds) async {
    if (tagIds.isEmpty) return [];
    
    final db = await database;
    final placeholders = tagIds.map((_) => '?').join(',');
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT s.* FROM songs s
      INNER JOIN song_tags st ON s.id = st.song_id
      WHERE st.tag_id IN ($placeholders)
      ORDER BY s.title
    ''', tagIds);
    
    return List.generate(maps.length, (i) => Song.fromJson(maps[i]));
  }

  // Query operations
  Future<List<Song>> executeQuery({
    required List<int> andTags,
    required List<int> orTags,
    required List<int> notTags,
  }) async {
    final db = await database;
    
    // Build the query based on the logic
    String query = 'SELECT DISTINCT s.* FROM songs s';
    List<dynamic> args = [];
    
    if (andTags.isNotEmpty || orTags.isNotEmpty || notTags.isNotEmpty) {
      query += ' INNER JOIN song_tags st ON s.id = st.song_id';
      
      List<String> conditions = [];
      
      // AND logic: song must have ALL these tags
      if (andTags.isNotEmpty) {
        final andPlaceholders = andTags.map((_) => '?').join(',');
        conditions.add('''
          s.id IN (
            SELECT song_id FROM song_tags 
            WHERE tag_id IN ($andPlaceholders)
            GROUP BY song_id 
            HAVING COUNT(DISTINCT tag_id) = ${andTags.length}
          )
        ''');
        args.addAll(andTags);
      }
      
      // OR logic: song must have AT LEAST ONE of these tags
      if (orTags.isNotEmpty) {
        final orPlaceholders = orTags.map((_) => '?').join(',');
        conditions.add('st.tag_id IN ($orPlaceholders)');
        args.addAll(orTags);
      }
      
      // NOT logic: song must NOT have any of these tags
      if (notTags.isNotEmpty) {
        final notPlaceholders = notTags.map((_) => '?').join(',');
        conditions.add('''
          s.id NOT IN (
            SELECT song_id FROM song_tags 
            WHERE tag_id IN ($notPlaceholders)
          )
        ''');
        args.addAll(notTags);
      }
      
      if (conditions.isNotEmpty) {
        query += ' WHERE ${conditions.join(' AND ')}';
      }
    }
    
    query += ' ORDER BY s.title';
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    return List.generate(maps.length, (i) => Song.fromJson(maps[i]));
  }

  // Utility operations
  Future<int> getSongCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM songs');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTagCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM tags');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> getTagSongCounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.id, t.name, COUNT(st.song_id) as song_count
      FROM tags t
      LEFT JOIN song_tags st ON t.id = st.tag_id
      GROUP BY t.id, t.name
      ORDER BY t.name
    ''');
    
    final Map<String, int> counts = {};
    for (final map in maps) {
      counts[map['name']] = map['song_count'];
    }
    
    return counts;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('song_tags');
    await db.delete('tags');
    await db.delete('songs');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
