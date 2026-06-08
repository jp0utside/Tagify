# CLAUDE.md — Agent Context for Tagify

## What This Is

Tagify is a Flutter mobile app that adds a tagging system on top of Spotify. Users tag songs with multiple labels, then query using AND/OR/NOT boolean logic to find exactly what they want. Tags are stored as Spotify playlists (prefixed `#tag:`), and existing playlists are imported as read-only queryable entities.

See `docs/Tagify_PRD.md` for full product spec and `docs/Tagify_Development_Roadmap.md` for the phased plan.

## Project Layout

```
Tagify/
├── CLAUDE.md                              # This file
├── README.md                              # Project overview
├── docs/
│   ├── Tagify_PRD.md                      # Product requirements
│   └── Tagify_Development_Roadmap.md      # Development phases
├── .github/workflows/
│   └── deploy-web.yml                     # GitHub Pages deployment
└── src/                                   # Flutter app root
    ├── pubspec.yaml
    ├── lib/
    │   ├── main.dart                      # Entry point, provider wiring
    │   ├── app.dart                       # Root widget, OAuth callback handler
    │   ├── models/
    │   │   ├── song.dart                  # Song model (includes albumArtUrl)
    │   │   ├── tag.dart                   # Tag model (TagType: tag | playlist)
    │   │   ├── song_tag.dart              # Junction table model
    │   │   └── user.dart                  # Spotify user profile
    │   ├── services/
    │   │   ├── auth_service.dart           # Spotify OAuth PKCE + token refresh
    │   │   ├── spotify_service.dart        # Spotify Web API wrapper
    │   │   ├── database_service.dart       # SQLite (mobile) / delegates to web
    │   │   ├── web_database_service.dart   # In-memory DB for web platform
    │   │   ├── database_factory.dart       # Legacy — not used, can be removed
    │   │   ├── import_service.dart         # Library import with progress/cancel
    │   │   └── tag_service.dart            # Tag CRUD + validation
    │   ├── screens/
    │   │   ├── auth/login_screen.dart
    │   │   ├── main/main_screen.dart       # Bottom nav, IndexedStack
    │   │   ├── library/library_screen.dart # Song list, search, import trigger
    │   │   ├── import/import_screen.dart   # Import progress UI
    │   │   ├── query/query_screen.dart     # Placeholder — Phase 4
    │   │   ├── tags/tags_screen.dart       # Tags/Playlists tabs, CRUD dialogs
    │   │   └── settings/settings_screen.dart
    │   ├── theme/app_theme.dart            # Material 3, Spotify colors
    │   └── utils/
    │       ├── constants.dart
    │       └── helpers.dart
    └── test/
        ├── widget_test.dart               # Placeholder
        └── services/
            ├── mock_services.dart          # Manual mocks for Spotify/DB
            ├── import_service_test.dart    # 8 tests
            └── tag_service_test.dart       # 17 tests
```

## Completed Phases

### Phase 1: Foundation & Authentication
- Spotify OAuth 2.0 with proper PKCE (SHA256 + base64url)
- SQLite schema: `songs`, `tags`, `song_tags` with indexes
- Core models, services, Material 3 theme, bottom tab navigation

### Phase 2: Library Import & Tag Management
- **ImportService**: Paginated Spotify API fetch for liked songs + playlists, progress tracking, cancellation, deduplication
- **TagService**: Create/rename/delete tags with Spotify playlist sync, name validation (length, duplicates, case-insensitive)
- **UI**: Import screen (idle/importing/complete/failed/cancelled states), library with album art + search, tags screen with tabs (Tags/Playlists) and overflow menu
- **Web deployment**: GitHub Actions → GitHub Pages at `https://jp0utside.github.io/Tagify/`

## Next Phase: Phase 3 — Tagging System

Per the roadmap, this is the immediate next work:

### 3.1: Individual Song Tagging
- **Song detail screen**: Tap a song in the library → see full details, current tags as chips, "Add Tag" button
- **Tag selector**: Autocomplete search across existing tags, option to create new tag inline
- **Tag assignment**: Add/remove tags on a song. Optimistic UI update, then background Spotify API call (`POST /playlists/{id}/tracks` / `DELETE /playlists/{id}/tracks`). Rollback on failure.
- **Tag chips in library**: Show first 2-3 tag chips on each song row in the library list

### 3.2: Batch Tagging
- **Multi-select mode**: Long-press or edit button in library → checkboxes on songs
- **Batch apply/remove**: Select songs → pick a tag → apply to all selected
- **Progress indicator**: For large batch operations with rate limiting

### Key files to create
- `lib/screens/songs/song_detail_screen.dart`
- `lib/widgets/tag_selector.dart`
- `lib/widgets/tag_chip.dart`

### Key existing code to build on
- `SpotifyService.addTracksToPlaylist()` and `removeTracksFromPlaylist()` already exist
- `DatabaseService.addSongToTag()`, `removeSongFromTag()`, `getTagsForSong()` already exist
- `TagService` already manages tag state and can be extended

## Architecture Notes

### State Management
Provider with ChangeNotifier. Services are wired in `main.dart` via `MultiProvider`:
- `AuthService` (ChangeNotifier) — auth state
- `DatabaseService` (plain Provider) — DB operations
- `SpotifyService` (ProxyProvider) — depends on AuthService for token
- `ImportService` (ChangeNotifierProxyProvider2) — depends on Spotify + DB
- `TagService` (ChangeNotifierProxyProvider2) — depends on Spotify + DB

### Web vs Mobile
`DatabaseService` checks `kIsWeb` at the top of every method and delegates to `WebDatabaseService` (in-memory maps) on web. Mobile uses SQLite via sqflite. The web DB does not persist across page reloads.

`database_factory.dart` is a legacy file from Phase 1 that is no longer used — `main.dart` uses `DatabaseService` directly now. It can be safely deleted.

### Spotify Integration
- Tags are Spotify playlists named `#tag:tagname` (private, in user's account)
- Regular playlists are imported as read-only `TagType.playlist` entities
- `Tag.fromSpotifyPlaylist()` handles the `#tag:` prefix parsing
- Auth uses PKCE with SHA256 code challenge (crypto package)
- On web, OAuth redirects in the same tab via `webOnlyWindowName: '_self'`

### Database Schema (v2)
```sql
songs: id, spotify_id, title, artist, album, album_art_url, duration_ms, uri, created_at
tags: id, spotify_id, name, description, type('tag'|'playlist'), is_public, created_at
song_tags: song_id, tag_id (composite PK, foreign keys with CASCADE)
```

## Running Tests

```bash
cd src
flutter test
```

Tests use manual mocks in `test/services/mock_services.dart` (no mockito dependency). `MockSpotifyService` and `MockDatabaseService` cover all service methods.

## Web Deployment

GitHub Actions workflow (`.github/workflows/deploy-web.yml`) builds on push to `main` and deploys to GitHub Pages. Requires `SPOTIFY_CLIENT_ID` as a GitHub Secret. The Spotify redirect URI for web is `https://jp0utside.github.io/Tagify/`.

## Known Limitations / Tech Debt

- **Web storage is ephemeral**: In-memory DB resets on page refresh. A future improvement could use IndexedDB.
- **database_factory.dart**: Dead code, can be removed.
- **No token expiry handling in SpotifyService**: If a 401 is returned, it should call `authService.refreshAccessToken()` and retry. Currently the user must re-authenticate.
- **Import is not resumable**: If cancelled/failed midway, re-running re-fetches everything (though deduplication prevents duplicates in DB).
- **No search in Tags screen**: Tag list doesn't have a search/filter yet.
