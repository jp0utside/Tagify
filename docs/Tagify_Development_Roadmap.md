# Tagify: Development Roadmap

**Version:** 1.0  
**Created:** January 2025  
**Based on:** Tagify PRD v1.0  
**Timeline:** 6 weeks MVP development

---

## Overview

This roadmap outlines the development plan for Tagify, a mobile app that adds a powerful tagging system to Spotify. The plan is structured around the MVP requirements defined in the PRD, with a focus on rapid iteration and validation of the core concept.

**Key Principles:**
- Mobile-first Flutter development
- Spotify Web API integration (no native SDK)
- SQLite for local caching and fast queries
- Spotify playlists as backend storage
- 6-week MVP timeline with clear milestones

---

## Development Phases

### Phase 1: Foundation & Authentication (Week 1)
**Goal:** Establish core infrastructure and user authentication

#### 1.1: Project Setup (Days 1-2)
**Deliverables:**
- [ ] Flutter project initialization with proper structure
- [ ] Core dependencies installed and configured
- [ ] Development environment setup
- [ ] Basic app navigation structure

**Technical Tasks:**
- Initialize Flutter project with iOS/Android support
- Add core dependencies: `http`, `sqflite`, `flutter_secure_storage`, `provider`
- Set up project structure (models, services, screens, widgets)
- Configure app icons and splash screen
- Set up basic bottom navigation (Library, Query, Tags, Settings)

**Dependencies:**
- Flutter SDK 3.16+
- Xcode 15+ (iOS development)
- Android Studio (Android development)

#### 1.2: Spotify Authentication (Days 3-4)
**Deliverables:**
- [ ] Spotify OAuth flow working
- [ ] Secure token storage and refresh
- [ ] User profile display

**Technical Tasks:**
- Implement Authorization Code Flow with PKCE
- Create Spotify service for API communication
- Set up secure token storage using `flutter_secure_storage`
- Implement automatic token refresh logic
- Create authentication screens (login, loading states)
- Add error handling for auth failures

**Key Files:**
- `lib/services/spotify_service.dart`
- `lib/services/auth_service.dart`
- `lib/screens/auth/login_screen.dart`

#### 1.3: Database Setup (Days 5-7)
**Deliverables:**
- [ ] SQLite database schema implemented
- [ ] Database service layer created
- [ ] Basic CRUD operations working

**Technical Tasks:**
- Design and implement SQLite schema:
  - `songs` table (id, spotify_id, title, artist, album, duration, uri)
  - `tags` table (id, spotify_id, name, description, type, is_public, created_at)
  - `song_tags` table (song_id, collection_id) - junction table
- Create database service with migration support
- Implement song and tag models with type handling
- Add database indexes for performance (especially on type column)
- Create unit tests for database operations

**Key Files:**
- `lib/services/database_service.dart`
- `lib/models/song.dart`
- `lib/models/tag.dart`
- `lib/models/song_tag.dart`

---

### Phase 2: Library Import & Data Management (Week 2)
**Goal:** Import user's Spotify library and establish data sync

#### 2.1: Library Import (Days 8-10)
**Deliverables:**
- [ ] Import liked songs from Spotify
- [ ] Import user playlists (read-only entities)
- [ ] Progress indicators and error handling
- [ ] Local database population with tags and playlists separation

**Technical Tasks:**
- Implement batch API requests respecting rate limits (180 req/min)
- Create import service with progress tracking
- Handle large libraries (5k+ songs) efficiently
- Implement resumable import (handle interruptions)
- Add comprehensive error handling and retry logic
- Create import progress UI with accurate status
- Import tags with appropriate type designation ('tag' or 'playlist')
- Store tag metadata with type handling

**Key Files:**
- `lib/services/import_service.dart`
- `lib/screens/import/import_progress_screen.dart`
- `lib/widgets/progress_indicator.dart`

#### 2.2: Tag Management Foundation (Days 11-14)
**Deliverables:**
- [ ] Create/delete tags locally and in Spotify
- [ ] Tag list UI with song counts
- [ ] Basic tag operations working
- [ ] Clear separation between tags and imported playlists in UI

**Technical Tasks:**
- Implement tag creation (local DB + Spotify playlist in "Tagify Tags" folder)
- Implement tag deletion with confirmation
- Create "Tagify Tags" folder in Spotify
- Implement tag renaming functionality
- Create tag management UI with search/filter
- Add validation for tag names (length, duplicates)
- Implement tag sync between local and Spotify
- Ensure tags are properly typed ('tag' vs 'playlist')
- Prevent modification of playlist-type tags through the app

**Key Files:**
- `lib/screens/tags/tags_screen.dart`
- `lib/screens/tags/create_tag_screen.dart`
- `lib/widgets/tag_list_item.dart`
- `lib/services/tag_service.dart`

---

### Phase 3: Tagging System (Week 3)
**Goal:** Complete tagging functionality for individual and batch operations

####  3.1: Individual Song Tagging (Days 15-17)
**Deliverables:**
- [ ] Tag songs individually from song detail screen
- [ ] Remove tags from songs
- [ ] Optimistic UI updates
- [ ] Tag chips display

**Technical Tasks:**
- Create song detail screen with tag management
- Implement tag selector with autocomplete
- Add optimistic UI updates for immediate feedback
- Create tag chips UI component
- Implement tag assignment/removal with Spotify sync
- Add error handling and rollback for failed operations
- Create tag search and filtering in selector

**Key Files:**
- `lib/screens/songs/song_detail_screen.dart`
- `lib/widgets/tag_selector.dart`
- `lib/widgets/tag_chip.dart`
- `lib/services/song_tagging_service.dart`

####  3.2: Batch Tagging (Days 18-21)
**Deliverables:**
- [ ] Select multiple songs for batch operations
- [ ] Apply tags to multiple songs simultaneously
- [ ] Remove tags from multiple songs
- [ ] Efficient batch API calls

**Technical Tasks:**
- Implement multi-select UI for songs list
- Create batch tagging interface
- Optimize API calls for batch operations
- Add progress indicators for batch operations
- Implement batch tag removal
- Add confirmation dialogs for destructive operations
- Create batch operation success/failure feedback

**Key Files:**
- `lib/widgets/batch_selection_widget.dart`
- `lib/screens/batch/batch_tagging_screen.dart`
- `lib/services/batch_tagging_service.dart`

---

### Phase 4: Query Builder & Results (Week 4)
**Goal:** Implement the core query functionality and results display

####  4.1: Query Builder UI (Days 22-24)
**Deliverables:**
- [ ] Query builder interface with AND/OR/NOT sections
- [ ] Tag selection with autocomplete
- [ ] Real-time query results count
- [ ] Query validation

**Technical Tasks:**
- Design and implement query builder UI
- Create tag selection components for each section (with type filtering)
- Implement query state management
- Add query validation logic
- Create responsive layout for different screen sizes
- Implement query history (save/load recent queries)
- Add query examples and help text
- Distinguish between tags (modifiable) and playlists (read-only) in query interface

**Key Files:**
- `lib/screens/query/query_builder_screen.dart`
- `lib/widgets/query_section.dart`
- `lib/widgets/tag_selector_widget.dart`
- `lib/models/query.dart`

####  4.2: Query Execution Engine (Days 25-28)
**Deliverables:**
- [ ] Fast query execution against SQLite
- [ ] Results display with pagination
- [ ] Performance optimization for large libraries
- [ ] Query result management

**Technical Tasks:**
- Implement query execution algorithm using set operations
- Handle both tag and playlist types in query execution
- Optimize SQLite queries with proper indexes
- Create results display with virtual scrolling
- Implement pagination for large result sets
- Add query performance monitoring
- Create empty state handling and suggestions
- Implement result sorting and filtering options
- Ensure query results can include songs from both tag and playlist types

**Key Files:**
- `lib/services/query_service.dart`
- `lib/widgets/query_results_list.dart`
- `lib/utils/query_optimizer.dart`

---

### Phase 5: Export & Playback Integration (Week 5)
**Goal:** Complete the user workflow with export options and Spotify integration

####  5.1: Export to Queue (Days 29-31)
**Deliverables:**
- [ ] Add query results to Spotify queue
- [ ] Progress tracking for queue operations
- [ ] Deep linking to Spotify app
- [ ] Error handling for playback operations

**Technical Tasks:**
- Implement Spotify queue API integration
- Create queue export UI with progress tracking
- Add deep linking to Spotify app
- Implement batch queue operations with rate limiting
- Add queue export confirmation and feedback
- Handle Spotify app not installed scenarios
- Create fallback options for queue export failures

**Key Files:**
- `lib/services/queue_service.dart`
- `lib/widgets/export_options.dart`
- `lib/utils/deep_link_helper.dart`

#### 5.2: Export as Playlist/Tag (Days 32-35)
**Deliverables:**
- [ ] Save query results as new tag
- [ ] Save query results as regular playlist
- [ ] Export progress tracking
- [ ] Export confirmation and feedback

**Technical Tasks:**
- Implement playlist creation in Spotify
- Create export options UI with naming prompts
- Add export progress tracking and error handling
- Implement tag creation from query results
- Add export history and management
- Create export success/failure notifications
- Implement playlist organization (Tagify Tags folder)

**Key Files:**
- `lib/services/export_service.dart`
- `lib/screens/export/export_options_screen.dart`
- `lib/widgets/export_progress_widget.dart`

---

### Phase 6: Polish & Testing (Week 6)
**Goal:** Polish the app, fix bugs, and prepare for release

#### 6.1: Sync & Error Handling (Days 36-38)
**Deliverables:**
- [ ] Robust sync system between local and Spotify
- [ ] Comprehensive error handling
- [ ] Offline state management
- [ ] Sync status indicators

**Technical Tasks:**
- Implement bidirectional sync with conflict resolution
- Add comprehensive error handling throughout the app
- Create sync status indicators and manual sync option
- Implement offline state detection and handling
- Add retry logic for failed operations
- Create sync conflict resolution UI
- Implement background sync when app is active

**Key Files:**
- `lib/services/sync_service.dart`
- `lib/widgets/sync_status_widget.dart`
- `lib/utils/error_handler.dart`

#### 6.2: UI Polish & Performance (Days 39-42)
**Deliverables:**
- [ ] Polished UI with consistent design
- [ ] Performance optimization
- [ ] Loading states and animations
- [ ] Accessibility improvements

**Technical Tasks:**
- Polish UI components and ensure design consistency
- Optimize app performance and memory usage
- Add loading states and smooth animations
- Implement accessibility features (screen readers, etc.)
- Add haptic feedback for key interactions
- Create onboarding flow for new users
- Implement dark mode support

**Key Files:**
- `lib/theme/app_theme.dart`
- `lib/widgets/loading_states.dart`
- `lib/screens/onboarding/onboarding_screen.dart`

---

## Technical Architecture

### Core Dependencies
```yaml
dependencies:
  flutter: sdk
  http: ^1.1.0              # Spotify API calls
  sqflite: ^2.3.0           # Local SQLite database
  flutter_secure_storage: ^9.0.0  # Secure token storage
  provider: ^6.1.1          # State management
  url_launcher: ^6.2.1      # Deep linking to Spotify
  shared_preferences: ^2.2.2 # App preferences
  connectivity_plus: ^5.0.2  # Network connectivity
  flutter_dotenv: ^5.1.0    # Environment variables
```

### Project Structure
```
lib/
├── main.dart
├── app.dart
├── models/
│   ├── song.dart
│   ├── tag.dart
│   ├── query.dart
│   └── user.dart
├── services/
│   ├── spotify_service.dart
│   ├── auth_service.dart
│   ├── database_service.dart
│   ├── sync_service.dart
│   └── import_service.dart
├── screens/
│   ├── auth/
│   ├── library/
│   ├── query/
│   ├── tags/
│   └── settings/
├── widgets/
│   ├── common/
│   ├── tag_chip.dart
│   └── query_builder.dart
└── utils/
    ├── constants.dart
    └── helpers.dart
```

### Database Schema
```sql
-- Songs table
CREATE TABLE songs (
  id INTEGER PRIMARY KEY,
  spotify_id TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  album TEXT NOT NULL,
  duration_ms INTEGER,
  uri TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tags table
CREATE TABLE tags (
  id INTEGER PRIMARY KEY,
  spotify_id TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL CHECK (type IN ('tag', 'playlist')),
  is_public BOOLEAN DEFAULT FALSE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Song-Tag junction table
CREATE TABLE song_tags (
  song_id INTEGER,
  tag_id INTEGER,
  PRIMARY KEY (song_id, tag_id),
  FOREIGN KEY (song_id) REFERENCES songs (id),
  FOREIGN KEY (tag_id) REFERENCES tags (id)
);

-- Indexes for performance
CREATE INDEX idx_songs_spotify_id ON songs(spotify_id);
CREATE INDEX idx_tags_type ON tags(type);
CREATE INDEX idx_tags_spotify_id ON tags(spotify_id);
CREATE INDEX idx_song_tags_song_id ON song_tags(song_id);
CREATE INDEX idx_song_tags_tag_id ON song_tags(tag_id);
```

---

## Risk Mitigation

### Technical Risks

**Risk: Spotify API Rate Limits**
- **Mitigation:** Implement request queuing and batching
- **Monitoring:** Track API usage and implement exponential backoff
- **Fallback:** Queue operations for later when limits hit

**Risk: Sync Conflicts**
- **Mitigation:** Spotify as source of truth, clear conflict resolution
- **Monitoring:** Log sync conflicts and user notifications
- **Fallback:** Manual sync option with conflict resolution UI

**Risk: Performance with Large Libraries**
- **Mitigation:** Optimize SQLite queries, use indexes, implement pagination
- **Monitoring:** Performance testing with 10k+ songs
- **Fallback:** Progressive loading and result limiting

**Risk: Network Connectivity Issues**
- **Mitigation:** Offline state detection, queue operations for later
- **Monitoring:** Connectivity status indicators
- **Fallback:** Local-only mode with sync when connected

### Product Risks

**Risk: Spotify API Changes**
- **Mitigation:** Stay updated with Spotify developer community
- **Monitoring:** Automated API health checks
- **Fallback:** Export functionality to preserve user data

**Risk: User Adoption**
- **Mitigation:** Start with personal use, validate concept
- **Monitoring:** User feedback and usage analytics
- **Fallback:** Iterate based on real usage patterns

---

## Success Metrics

### Technical Metrics
- [ ] App launches successfully on iOS and Android
- [ ] Spotify authentication works reliably
- [ ] Library import completes for 5k+ songs
- [ ] Query execution < 500ms for 10k songs
- [ ] Sync operations complete without data loss
- [ ] App handles offline scenarios gracefully

### User Experience Metrics
- [ ] User can complete core workflow (auth → import → tag → query → export)
- [ ] Tagging songs feels responsive (< 200ms UI feedback)
- [ ] Query results display instantly
- [ ] Export operations complete successfully
- [ ] Error messages are clear and actionable

### MVP Validation Criteria
- [ ] Solves the core problem: multi-dimensional music organization
- [ ] Integrates seamlessly with Spotify workflow
- [ ] Performs well with realistic library sizes
- [ ] Provides clear value over existing playlist system
- [ ] Ready for personal use and friend testing

---

## Post-MVP Roadmap

### Phase 7: Advanced Features (Weeks 7-10)
- [ ] Spotify metadata integration (BPM, energy, genre)
- [ ] Smart playlists with auto-updating rules
- [ ] Advanced query syntax (parentheses, nested logic)
- [ ] Tag analytics and insights
- [ ] Custom attribute tags (ratings, notes)

### Phase 8: Platform Expansion (Weeks 11-14)
- [ ] Desktop app (Flutter desktop)
- [ ] Web version
- [ ] Cross-platform library sync
- [ ] Advanced export options

### Phase 9: Social Features (Weeks 15-18)
- [ ] Share tag systems
- [ ] Community tag exploration
- [ ] Collaborative tagging
- [ ] Tag recommendations

---

## Development Resources

### Learning Resources
- [Flutter Documentation](https://docs.flutter.dev/)
- [Spotify Web API Guide](https://developer.spotify.com/documentation/web-api/)
- [SQLite with Flutter](https://pub.dev/packages/sqflite)
- [Flutter State Management Guide](https://docs.flutter.dev/development/data-and-backend/state-mgmt)

### Key Spotify API Endpoints
- `GET /me/tracks` - User's liked songs
- `GET /me/playlists` - User's playlists
- `POST /users/{id}/playlists` - Create playlist
- `POST /playlists/{id}/tracks` - Add songs to playlist
- `POST /me/player/queue` - Add to playback queue

### Testing Strategy
- Unit tests for core business logic
- Integration tests for Spotify API calls
- Widget tests for UI components
- Performance tests with large datasets
- Manual testing on real devices

---

*This roadmap is a living document that will be updated as development progresses and requirements evolve.*
