import 'package:flutter_test/flutter_test.dart';
import 'package:tagify/models/song.dart';
import 'package:tagify/models/tag.dart';
import 'package:tagify/services/import_service.dart';
import 'mock_services.dart';

void main() {
  late MockSpotifyService mockSpotify;
  late MockDatabaseService mockDb;
  late ImportService importService;

  setUp(() {
    mockSpotify = MockSpotifyService();
    mockDb = MockDatabaseService();
    importService = ImportService(
      spotifyService: mockSpotify,
      databaseService: mockDb,
    );
  });

  group('ImportService', () {
    test('initial state is idle', () {
      expect(importService.status, ImportStatus.idle);
      expect(importService.errorMessage, isNull);
    });

    test('imports liked songs successfully', () async {
      mockSpotify.likedSongs = [
        Song(
            spotifyId: 's1',
            title: 'Song 1',
            artist: 'Artist 1',
            album: 'Album 1'),
        Song(
            spotifyId: 's2',
            title: 'Song 2',
            artist: 'Artist 2',
            album: 'Album 2'),
      ];
      mockSpotify.playlists = [];

      final result = await importService.importLibrary();

      expect(result, true);
      expect(importService.status, ImportStatus.completed);
      final songs = await mockDb.getAllSongs();
      expect(songs.length, 2);
    });

    test('imports playlists and their tracks', () async {
      mockSpotify.likedSongs = [];
      mockSpotify.playlists = [
        Tag(
            spotifyId: 'pl1',
            name: 'My Playlist',
            type: TagType.playlist),
      ];
      mockSpotify.playlistTracks = {
        'pl1': [
          Song(
              spotifyId: 's1',
              title: 'Song 1',
              artist: 'Artist',
              album: 'Album'),
        ],
      };

      await importService.importLibrary();

      expect(importService.status, ImportStatus.completed);
      final songs = await mockDb.getAllSongs();
      expect(songs.length, 1);
      final tags = await mockDb.getAllTags();
      expect(tags.length, 1);
      expect(tags.first.type, TagType.playlist);
    });

    test('separates tagify tags from regular playlists', () async {
      mockSpotify.likedSongs = [];
      mockSpotify.playlists = [
        Tag(
            spotifyId: 'pl1',
            name: 'Regular Playlist',
            type: TagType.playlist),
        Tag(
            spotifyId: 'tag1',
            name: '#tag:workout',
            type: TagType.tag),
      ];
      // The Tag.fromSpotifyPlaylist constructor handles the #tag: prefix parsing
      // In the mock, we set up the tags as they would come from the API

      await importService.importLibrary();

      expect(importService.status, ImportStatus.completed);
      final tags = await mockDb.getAllTags();
      expect(tags.length, 2);
    });

    test('handles API failure', () async {
      mockSpotify.shouldFail = true;

      final result = await importService.importLibrary();

      expect(result, false);
      expect(importService.status, ImportStatus.failed);
      expect(importService.errorMessage, isNotNull);
    });

    test('does not duplicate songs on re-import', () async {
      mockSpotify.likedSongs = [
        Song(
            spotifyId: 's1',
            title: 'Song 1',
            artist: 'Artist',
            album: 'Album'),
      ];
      mockSpotify.playlists = [];

      await importService.importLibrary();
      importService.reset();
      await importService.importLibrary();

      final songs = await mockDb.getAllSongs();
      expect(songs.length, 1);
    });

    test('cancel stops import', () async {
      mockSpotify.likedSongs = List.generate(
        200,
        (i) => Song(
            spotifyId: 's$i',
            title: 'Song $i',
            artist: 'Artist',
            album: 'Album'),
      );
      mockSpotify.playlists = [];

      // Start import and immediately cancel
      final future = importService.importLibrary();
      importService.cancelImport();
      await future;

      expect(importService.status, ImportStatus.cancelled);
    });

    test('reset returns to idle state', () async {
      mockSpotify.likedSongs = [
        Song(
            spotifyId: 's1',
            title: 'Song',
            artist: 'Artist',
            album: 'Album'),
      ];
      mockSpotify.playlists = [];

      await importService.importLibrary();
      expect(importService.status, ImportStatus.completed);

      importService.reset();
      expect(importService.status, ImportStatus.idle);
      expect(importService.progress.importedSongs, 0);
    });

    test('progress updates during import', () async {
      mockSpotify.likedSongs = [
        Song(
            spotifyId: 's1',
            title: 'Song 1',
            artist: 'A',
            album: 'B'),
        Song(
            spotifyId: 's2',
            title: 'Song 2',
            artist: 'A',
            album: 'B'),
      ];
      mockSpotify.playlists = [];

      await importService.importLibrary();

      expect(importService.progress.importedSongs, 2);
      expect(importService.progress.totalSongs, 2);
    });
  });
}
