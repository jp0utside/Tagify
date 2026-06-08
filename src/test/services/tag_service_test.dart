import 'package:flutter_test/flutter_test.dart';
import 'package:tagify/models/tag.dart';
import 'package:tagify/models/song.dart';
import 'package:tagify/services/tag_service.dart';
import 'mock_services.dart';

void main() {
  late MockSpotifyService mockSpotify;
  late MockDatabaseService mockDb;
  late TagService tagService;

  setUp(() {
    mockSpotify = MockSpotifyService();
    mockDb = MockDatabaseService();
    tagService = TagService(
      spotifyService: mockSpotify,
      databaseService: mockDb,
    );
  });

  group('TagService - Validation', () {
    test('rejects empty name', () {
      final result = tagService.validateTagName('');
      expect(result.isValid, false);
      expect(result.errorMessage, contains('empty'));
    });

    test('rejects whitespace-only name', () {
      final result = tagService.validateTagName('   ');
      expect(result.isValid, false);
      expect(result.errorMessage, contains('empty'));
    });

    test('rejects names over 95 characters', () {
      final longName = 'a' * 96;
      final result = tagService.validateTagName(longName);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('95'));
    });

    test('accepts valid name', () {
      final result = tagService.validateTagName('workout');
      expect(result.isValid, true);
      expect(result.errorMessage, isNull);
    });

    test('accepts name at 95 characters', () {
      final name = 'a' * 95;
      final result = tagService.validateTagName(name);
      expect(result.isValid, true);
    });

    test('rejects duplicate names (case-insensitive)', () async {
      await tagService.createTag('Workout');
      final result = tagService.validateTagName('workout');
      expect(result.isValid, false);
      expect(result.errorMessage, contains('already exists'));
    });
  });

  group('TagService - Create', () {
    test('creates tag locally and in Spotify', () async {
      final tag = await tagService.createTag('chill');

      expect(tag, isNotNull);
      expect(tag!.name, 'chill');
      expect(tag.type, TagType.tag);
      expect(mockSpotify.createdTags.length, 1);
      expect(mockSpotify.createdTags.first.name, 'chill');
    });

    test('trims whitespace from tag name', () async {
      final tag = await tagService.createTag('  workout  ');

      expect(tag, isNotNull);
      expect(tag!.name, 'workout');
    });

    test('throws on empty name', () async {
      expect(
        () => tagService.createTag(''),
        throwsException,
      );
    });

    test('throws on duplicate name', () async {
      await tagService.createTag('chill');
      expect(
        () => tagService.createTag('chill'),
        throwsException,
      );
    });

    test('throws on Spotify API failure', () async {
      mockSpotify.shouldFail = true;
      expect(
        () => tagService.createTag('test'),
        throwsException,
      );
    });

    test('updates tag list after creation', () async {
      await tagService.createTag('chill');

      expect(tagService.userTags.length, 1);
      expect(tagService.userTags.first.name, 'chill');
    });
  });

  group('TagService - Rename', () {
    test('renames tag locally and in Spotify', () async {
      await tagService.createTag('old name');
      final tag = tagService.userTags.first;

      await tagService.renameTag(tag, 'new name');

      expect(tagService.userTags.first.name, 'new name');
      expect(mockSpotify.updatedPlaylists[tag.spotifyId]!['name'],
          '#tag:new name');
    });

    test('trims whitespace from new name', () async {
      await tagService.createTag('original');
      final tag = tagService.userTags.first;

      await tagService.renameTag(tag, '  trimmed  ');

      expect(tagService.userTags.first.name, 'trimmed');
    });

    test('throws on empty new name', () async {
      await tagService.createTag('test');
      final tag = tagService.userTags.first;

      expect(
        () => tagService.renameTag(tag, ''),
        throwsException,
      );
    });

    test('throws on duplicate new name', () async {
      await tagService.createTag('first');
      await tagService.createTag('second');
      final firstTag = tagService.userTags.firstWhere((t) => t.name == 'first');

      expect(
        () => tagService.renameTag(firstTag, 'second'),
        throwsException,
      );
    });

    test('throws when renaming a playlist', () async {
      await mockDb.insertTag(Tag(
        spotifyId: 'pl1',
        name: 'My Playlist',
        type: TagType.playlist,
      ));
      await tagService.loadTags();
      final playlist = tagService.playlists.first;

      expect(
        () => tagService.renameTag(playlist, 'new name'),
        throwsException,
      );
    });

    test('throws on name over 95 characters', () async {
      await tagService.createTag('test');
      final tag = tagService.userTags.first;

      expect(
        () => tagService.renameTag(tag, 'a' * 96),
        throwsException,
      );
    });
  });

  group('TagService - Delete', () {
    test('deletes tag locally and in Spotify', () async {
      await tagService.createTag('to delete');
      final tag = tagService.userTags.first;

      await tagService.deleteTag(tag);

      expect(tagService.userTags, isEmpty);
      expect(mockSpotify.deletedPlaylistIds, contains(tag.spotifyId));
    });

    test('throws when deleting a playlist', () async {
      await mockDb.insertTag(Tag(
        spotifyId: 'pl1',
        name: 'My Playlist',
        type: TagType.playlist,
      ));
      await tagService.loadTags();
      final playlist = tagService.playlists.first;

      expect(
        () => tagService.deleteTag(playlist),
        throwsException,
      );
    });

    test('throws on Spotify API failure', () async {
      await tagService.createTag('test');
      final tag = tagService.userTags.first;
      mockSpotify.shouldFail = true;

      expect(
        () => tagService.deleteTag(tag),
        throwsException,
      );
    });
  });

  group('TagService - Load', () {
    test('loads tags from database', () async {
      await mockDb.insertTag(
          Tag(spotifyId: 't1', name: 'chill', type: TagType.tag));
      await mockDb.insertTag(
          Tag(spotifyId: 'p1', name: 'My Playlist', type: TagType.playlist));

      await tagService.loadTags();

      expect(tagService.tags.length, 2);
      expect(tagService.userTags.length, 1);
      expect(tagService.playlists.length, 1);
    });

    test('separates tags and playlists', () async {
      await mockDb.insertTag(
          Tag(spotifyId: 't1', name: 'workout', type: TagType.tag));
      await mockDb.insertTag(
          Tag(spotifyId: 't2', name: 'chill', type: TagType.tag));
      await mockDb.insertTag(
          Tag(spotifyId: 'p1', name: 'Favorites', type: TagType.playlist));

      await tagService.loadTags();

      expect(tagService.userTags.length, 2);
      expect(tagService.playlists.length, 1);
    });

    test('loads song counts', () async {
      final songId = await mockDb.insertSong(Song(
          spotifyId: 's1', title: 'Song', artist: 'A', album: 'B'));
      await mockDb.insertTag(
          Tag(spotifyId: 't1', name: 'chill', type: TagType.tag));
      final tags = await mockDb.getAllTags();
      await mockDb.addSongToTag(songId, tags.first.id!);

      await tagService.loadTags();

      expect(tagService.songCountForTag(tagService.userTags.first), 1);
    });
  });

  group('TagService - Song Tagging', () {
    late Song testSong;
    late Tag testTag;

    setUp(() async {
      final songId = await mockDb.insertSong(Song(
        spotifyId: 's1',
        title: 'Test Song',
        artist: 'Artist',
        album: 'Album',
        uri: 'spotify:track:s1',
      ));
      final songs = await mockDb.getAllSongs();
      testSong = songs.first;

      await tagService.createTag('workout');
      testTag = tagService.userTags.first;
    });

    test('getTagsForSong returns empty for untagged song', () async {
      final tags = await tagService.getTagsForSong(testSong);
      expect(tags, isEmpty);
    });

    test('addTagToSong adds tag locally and syncs to Spotify', () async {
      await tagService.addTagToSong(testSong, testTag);

      final tags = await tagService.getTagsForSong(testSong);
      expect(tags.length, 1);
      expect(tags.first.name, 'workout');
      expect(mockSpotify.addedTracks[testTag.spotifyId], ['spotify:track:s1']);
    });

    test('removeTagFromSong removes tag locally and syncs to Spotify', () async {
      await tagService.addTagToSong(testSong, testTag);
      await tagService.removeTagFromSong(testSong, testTag);

      final tags = await tagService.getTagsForSong(testSong);
      expect(tags, isEmpty);
      expect(mockSpotify.removedTracks[testTag.spotifyId], ['spotify:track:s1']);
    });

    test('addTagToSong rolls back on Spotify failure', () async {
      await tagService.addTagToSong(testSong, testTag);
      mockSpotify.addedTracks.clear();

      // Create a second tag and make Spotify fail
      await tagService.createTag('chill');
      final chillTag = tagService.userTags.firstWhere((t) => t.name == 'chill');
      mockSpotify.shouldFail = true;

      expect(
        () => tagService.addTagToSong(testSong, chillTag),
        throwsException,
      );

      // The chill tag should have been rolled back
      final tags = await tagService.getTagsForSong(testSong);
      expect(tags.length, 1);
      expect(tags.first.name, 'workout');
    });

    test('removeTagFromSong rolls back on Spotify failure', () async {
      await tagService.addTagToSong(testSong, testTag);
      mockSpotify.shouldFail = true;

      expect(
        () => tagService.removeTagFromSong(testSong, testTag),
        throwsException,
      );

      // The tag should still be there after rollback
      final tags = await tagService.getTagsForSong(testSong);
      expect(tags.length, 1);
      expect(tags.first.name, 'workout');
    });

    test('addTagToSong throws for unsaved song', () async {
      final unsavedSong = Song(
        spotifyId: 'x1',
        title: 'Unsaved',
        artist: 'A',
        album: 'B',
      );

      expect(
        () => tagService.addTagToSong(unsavedSong, testTag),
        throwsException,
      );
    });

    test('updates song counts after tagging', () async {
      await tagService.addTagToSong(testSong, testTag);

      expect(tagService.songCountForTag(testTag), 1);
    });
  });

  group('TagService - Batch Tagging', () {
    late List<Song> testSongs;
    late Tag testTag;

    setUp(() async {
      for (int i = 0; i < 5; i++) {
        await mockDb.insertSong(Song(
          spotifyId: 's$i',
          title: 'Song $i',
          artist: 'Artist',
          album: 'Album',
          uri: 'spotify:track:s$i',
        ));
      }
      testSongs = await mockDb.getAllSongs();

      await tagService.createTag('batch-tag');
      testTag = tagService.userTags.first;
    });

    test('batchAddTagToSongs tags all songs', () async {
      final count = await tagService.batchAddTagToSongs(
        songs: testSongs,
        tag: testTag,
      );

      expect(count, 5);
      expect(tagService.songCountForTag(testTag), 5);
      expect(mockSpotify.addedTracks[testTag.spotifyId]?.length, 5);
    });

    test('batchAddTagToSongs reports progress', () async {
      final progressUpdates = <int>[];

      await tagService.batchAddTagToSongs(
        songs: testSongs,
        tag: testTag,
        onProgress: (completed, total) => progressUpdates.add(completed),
      );

      expect(progressUpdates, [1, 2, 3, 4, 5]);
    });

    test('batchRemoveTagFromSongs removes all', () async {
      await tagService.batchAddTagToSongs(songs: testSongs, tag: testTag);

      final count = await tagService.batchRemoveTagFromSongs(
        songs: testSongs,
        tag: testTag,
      );

      expect(count, 5);
      expect(tagService.songCountForTag(testTag), 0);
    });

    test('batchAddTagToSongs skips duplicates', () async {
      await tagService.addTagToSong(testSongs[0], testTag);
      mockSpotify.addedTracks.clear();

      final count = await tagService.batchAddTagToSongs(
        songs: testSongs,
        tag: testTag,
      );

      // First song was already tagged, so only 4 new
      expect(count, 4);
    });
  });
}
