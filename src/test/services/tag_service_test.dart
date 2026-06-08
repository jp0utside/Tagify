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
}
