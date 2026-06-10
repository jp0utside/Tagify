import 'package:flutter_test/flutter_test.dart';
import 'package:tagify/models/song.dart';
import 'package:tagify/models/tag.dart';
import 'package:tagify/services/export_service.dart';
import 'mock_services.dart';

void main() {
  late MockSpotifyService mockSpotify;
  late MockDatabaseService mockDb;
  late ExportService exportService;

  final testSongs = [
    Song(id: 1, spotifyId: 's1', title: 'Song 1', artist: 'Artist', album: 'Album', uri: 'spotify:track:s1'),
    Song(id: 2, spotifyId: 's2', title: 'Song 2', artist: 'Artist', album: 'Album', uri: 'spotify:track:s2'),
    Song(id: 3, spotifyId: 's3', title: 'Song 3', artist: 'Artist', album: 'Album', uri: 'spotify:track:s3'),
  ];

  setUp(() {
    mockSpotify = MockSpotifyService();
    mockDb = MockDatabaseService();
    exportService = ExportService(
      spotifyService: mockSpotify,
      databaseService: mockDb,
    );
  });

  group('ExportService initial state', () {
    test('starts in idle state', () {
      expect(exportService.state, ExportState.idle);
      expect(exportService.progress, 0.0);
    });
  });

  group('exportToQueue', () {
    test('queues all songs successfully', () async {
      final result = await exportService.exportToQueue(testSongs);

      expect(result.success, true);
      expect(result.type, ExportType.queue);
      expect(result.songsExported, 3);
      expect(result.totalSongs, 3);
      expect(mockSpotify.queuedTracks, [
        'spotify:track:s1',
        'spotify:track:s2',
        'spotify:track:s3',
      ]);
      expect(exportService.state, ExportState.completed);
    });

    test('reports progress via callback', () async {
      final progress = <List<int>>[];
      await exportService.exportToQueue(
        testSongs,
        onProgress: (completed, total) => progress.add([completed, total]),
      );

      expect(progress, [
        [1, 3],
        [2, 3],
        [3, 3],
      ]);
    });

    test('skips songs without URI', () async {
      final songs = [
        Song(id: 1, spotifyId: 's1', title: 'Song 1', artist: 'A', album: 'A', uri: 'spotify:track:s1'),
        Song(id: 2, spotifyId: 's2', title: 'Song 2', artist: 'A', album: 'A', uri: null),
      ];

      final result = await exportService.exportToQueue(songs);

      expect(result.songsExported, 1);
      expect(result.totalSongs, 1);
      expect(mockSpotify.queuedTracks, ['spotify:track:s1']);
    });

    test('handles API failure', () async {
      mockSpotify.shouldFail = true;

      final result = await exportService.exportToQueue(testSongs);

      expect(result.success, false);
      expect(result.error, contains('API Error'));
      expect(exportService.state, ExportState.failed);
    });

    test('handles cancellation', () async {
      mockSpotify.queuedTracks = [];

      final songs = List.generate(
        20,
        (i) => Song(id: i + 1, spotifyId: 's$i', title: 'Song $i', artist: 'A', album: 'A', uri: 'spotify:track:s$i'),
      );

      exportService.cancelExport();

      final result = await exportService.exportToQueue(songs);

      expect(result.success, false);
      expect(result.error, 'Export cancelled');
      expect(exportService.state, ExportState.cancelled);
    });

    test('handles empty song list', () async {
      final result = await exportService.exportToQueue([]);

      expect(result.success, true);
      expect(result.songsExported, 0);
      expect(result.totalSongs, 0);
    });
  });

  group('exportAsPlaylist', () {
    test('creates playlist and adds all songs', () async {
      final result = await exportService.exportAsPlaylist('My Playlist', testSongs);

      expect(result.success, true);
      expect(result.type, ExportType.playlist);
      expect(result.songsExported, 3);
      expect(result.createdTag, isNotNull);
      expect(result.createdTag!.name, 'My Playlist');
      expect(mockSpotify.createdPlaylists.length, 1);
      expect(mockSpotify.createdPlaylists[0]['name'], 'My Playlist');
      expect(mockSpotify.addedTracks[result.createdTag!.spotifyId]!.length, 3);
      expect(exportService.state, ExportState.completed);
    });

    test('reports progress', () async {
      final progress = <List<int>>[];
      await exportService.exportAsPlaylist(
        'Test',
        testSongs,
        onProgress: (completed, total) => progress.add([completed, total]),
      );

      expect(progress.last, [3, 3]);
    });

    test('handles API failure on playlist creation', () async {
      mockSpotify.shouldFail = true;

      final result = await exportService.exportAsPlaylist('Fail', testSongs);

      expect(result.success, false);
      expect(result.error, contains('API Error'));
      expect(exportService.state, ExportState.failed);
    });

    test('batches large playlists in groups of 100', () async {
      final manySongs = List.generate(
        250,
        (i) => Song(id: i + 1, spotifyId: 's$i', title: 'Song $i', artist: 'A', album: 'A', uri: 'spotify:track:s$i'),
      );

      final result = await exportService.exportAsPlaylist('Big Playlist', manySongs);

      expect(result.success, true);
      expect(result.songsExported, 250);
      final tracks = mockSpotify.addedTracks[result.createdTag!.spotifyId]!;
      expect(tracks.length, 250);
    });
  });

  group('exportAsTag', () {
    test('creates tag, adds songs to DB and Spotify', () async {
      for (final song in testSongs) {
        await mockDb.insertSong(song);
      }

      final result = await exportService.exportAsTag('chill', testSongs);

      expect(result.success, true);
      expect(result.type, ExportType.tag);
      expect(result.songsExported, 3);
      expect(result.createdTag, isNotNull);
      expect(result.createdTag!.name, 'chill');
      expect(mockSpotify.createdTags.length, 1);
      expect(mockSpotify.createdTags[0].name, 'chill');
      expect(exportService.state, ExportState.completed);

      final dbTags = await mockDb.getAllTags();
      expect(dbTags.length, 1);
      expect(dbTags[0].name, 'chill');
      expect(dbTags[0].type, TagType.tag);
    });

    test('syncs tracks to Spotify playlist', () async {
      for (final song in testSongs) {
        await mockDb.insertSong(song);
      }

      final result = await exportService.exportAsTag('workout', testSongs);

      final spotifyId = result.createdTag!.spotifyId;
      expect(mockSpotify.addedTracks[spotifyId]!.length, 3);
    });

    test('handles API failure', () async {
      mockSpotify.shouldFail = true;

      final result = await exportService.exportAsTag('fail', testSongs);

      expect(result.success, false);
      expect(result.error, contains('API Error'));
      expect(exportService.state, ExportState.failed);
    });

    test('skips songs without DB id', () async {
      final songs = [
        Song(id: null, spotifyId: 's1', title: 'Song 1', artist: 'A', album: 'A', uri: 'spotify:track:s1'),
        Song(id: 2, spotifyId: 's2', title: 'Song 2', artist: 'A', album: 'A', uri: 'spotify:track:s2'),
      ];
      await mockDb.insertSong(songs[1]);

      final result = await exportService.exportAsTag('test', songs);

      expect(result.songsExported, 1);
    });
  });

  group('reset', () {
    test('resets state to idle', () async {
      await exportService.exportToQueue(testSongs);
      expect(exportService.state, ExportState.completed);

      exportService.reset();
      expect(exportService.state, ExportState.idle);
      expect(exportService.progress, 0.0);
    });
  });
}
