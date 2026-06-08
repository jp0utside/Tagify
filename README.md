# Tagify

**A powerful tagging system for Spotify that enables multi-dimensional music organization and complex queries.**

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-Personal-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Phase%202%20Complete-brightgreen.svg)](docs/Tagify_Development_Roadmap.md)

## 🎵 What is Tagify?

Tagify solves the fundamental limitation of Spotify's playlist system by adding a flexible tagging layer that enables multi-dimensional music organization. Instead of being forced into rigid playlist categories, you can tag songs with multiple labels and query across them using boolean logic.

### The Problem
- **Spotify's playlist system is rigid**: You can't easily find songs that are both "chill" AND "instrumental" but NOT "classical"
- **Hyper-specific playlists**: You end up with dozens of playlists for every possible combination
- **No multi-dimensional organization**: Can't organize by mood, genre, era, and activity simultaneously

### The Solution
- **Flexible tagging**: Add multiple tags to any song (workout, high-energy, 90s, grunge, etc.)
- **Smart queries**: Use AND, OR, NOT logic to find exactly what you want
- **Instant results**: Query against local database for sub-second response times
- **Spotify integration**: Export results to queue or save as playlists

## 🚀 Current Status

### ✅ Phase 1 Complete: Foundation & Authentication
- **Flutter project setup** with complete structure and dependencies
- **Spotify OAuth authentication** with PKCE security (SHA256)
- **SQLite database** with optimized schema for fast queries
- **Core services** for API integration and local data management
- **UI foundation** with Material 3 theming and navigation

### ✅ Phase 2 Complete: Library Import & Tag Management
- **Library import** with paginated Spotify API fetch, progress tracking, and cancellation
- **Tag management** — create, rename, delete tags (synced to Spotify playlists)
- **Library screen** with album art, search filtering, pull-to-refresh
- **Tags screen** with Tags/Playlists tabs, overflow menu for rename/delete
- **Web deployment** via GitHub Actions → GitHub Pages
- **Unit tests** for ImportService and TagService

### 🚧 Next: Phase 3 - Tagging System
- Individual song tagging from song detail screen
- Batch tagging operations
- Tag chips display in library list

## 📱 Key Features

### Core Functionality
- **🔐 Spotify Authentication**: Secure OAuth 2.0 flow with PKCE
- **📚 Library Import**: Import liked songs and existing playlists
- **🏷️ Tag Management**: Create, rename, and delete tags (stored as Spotify playlists)
- **🎵 Song Tagging**: Add/remove multiple tags from individual songs
- **🔍 Query Builder**: Complex queries using AND, OR, NOT logic
- **📤 Export Options**: Add to Spotify queue or save as playlists
- **🔄 Sync**: Bi-directional sync between local database and Spotify

### Technical Highlights
- **⚡ Fast Queries**: Local SQLite database for instant results
- **🔒 Secure**: PKCE authentication and secure token storage
- **📱 Mobile-First**: Native iOS and Android app built with Flutter
- **🎨 Modern UI**: Material 3 design with Spotify-inspired theming
- **🏗️ Clean Architecture**: Service layer pattern with proper separation of concerns

## 🏗️ Project Structure

```
Tagify/
├── docs/                           # Documentation
│   ├── Tagify_PRD.md              # Product Requirements Document
│   └── Tagify_Development_Roadmap.md # Development roadmap
├── src/                           # Flutter application
│   ├── lib/
│   │   ├── main.dart              # App entry point
│   │   ├── app.dart               # Main app widget
│   │   ├── models/                # Data models
│   │   │   ├── song.dart          # Song model
│   │   │   ├── tag.dart           # Tag model
│   │   │   ├── song_tag.dart      # Junction table
│   │   │   └── user.dart          # User profile
│   │   ├── services/              # Business logic
│   │   │   ├── auth_service.dart  # Spotify OAuth PKCE
│   │   │   ├── spotify_service.dart # Spotify Web API
│   │   │   ├── database_service.dart # SQLite / web delegate
│   │   │   ├── import_service.dart # Library import
│   │   │   └── tag_service.dart   # Tag CRUD
│   │   ├── screens/               # UI screens
│   │   │   ├── auth/              # Login screen
│   │   │   ├── main/              # Bottom nav shell
│   │   │   ├── library/           # Song list + search
│   │   │   ├── import/            # Import progress
│   │   │   ├── query/             # Query builder (Phase 4)
│   │   │   ├── tags/              # Tag management
│   │   │   └── settings/          # App settings
│   │   ├── theme/                 # App theming
│   │   └── utils/                 # Utilities
│   ├── pubspec.yaml               # Dependencies
│   └── README.md                  # Flutter app documentation
└── README.md                      # This file
```

## 🛠️ Getting Started

### Prerequisites
- **Flutter SDK 3.16+** - [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Xcode 15+** (for iOS development)
- **Android Studio** (for Android development)
- **Spotify Developer Account** - [Create App](https://developer.spotify.com/dashboard)

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Tagify
   ```

2. **Navigate to Flutter app**
   ```bash
   cd src
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Configure Spotify API**
   - Create a Spotify app in the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
   - Add redirect URI: `tagify://auth`
   - Create `.env` file in `src/` directory:
     ```env
     SPOTIFY_CLIENT_ID=your_spotify_client_id_here
     SPOTIFY_REDIRECT_URI=tagify://auth
     SPOTIFY_SCOPE=user-library-read playlist-read-private playlist-modify-private user-modify-playback-state
     ```

5. **Run the app**
   ```bash
   flutter run
   ```

### Testing the App

#### Web (GitHub Pages)
The app is deployed at `https://jp0utside.github.io/Tagify/`. Web uses in-memory storage (data resets on page refresh).

#### What Works Now
- ✅ Spotify OAuth authentication (PKCE with SHA256)
- ✅ Secure token storage and refresh
- ✅ Import liked songs and playlists from Spotify
- ✅ Library screen with album art, search, pull-to-refresh
- ✅ Create, rename, and delete tags (synced to Spotify)
- ✅ Tags/Playlists tabs with song counts
- ✅ Bottom tab navigation
- ✅ User profile display in settings

#### What's Coming Next
- 🚧 Individual song tagging (Phase 3)
- 🚧 Batch tagging operations (Phase 3)
- 🚧 Query builder with AND/OR/NOT logic (Phase 4)

## 🎯 Use Cases

### Example 1: Multi-Dimensional Discovery
**Current Problem**: Find songs that are both "chill" AND "instrumental" but NOT "classical"

**With Tagify**:
- Tag songs: `chill`, `instrumental`, `not classical`
- Query: `chill AND instrumental NOT classical`
- Result: 23 songs instantly
- Export to Spotify queue or save as playlist

### Example 2: Leverage Existing Playlists
**Current Problem**: Want to shuffle multiple playlists together

**With Tagify**:
- Import existing playlists as read-only entities
- Query: `90s AND 00s AND Grunge` (across multiple playlists)
- Play freely without repeats or manual playlist switching

### Example 3: Gradual Organization
**Current Problem**: Organizing music feels like an all-or-nothing project

**With Tagify**:
- Tag songs opportunistically while listening
- Each tag adds immediate value
- System gets more powerful as you tag more songs
- No pressure to tag everything at once

## 🔧 Technical Architecture

### Core Components
- **Flutter App**: Cross-platform mobile application
- **SQLite Database**: Local storage for fast queries
- **Spotify Web API**: Authentication and data sync
- **Provider State Management**: Reactive UI updates

### Data Flow
1. **Authentication**: User connects with Spotify OAuth
2. **Import**: Library and playlists imported from Spotify
3. **Local Storage**: Data cached in SQLite for fast access
4. **Tagging**: Tags stored as Spotify playlists in "Tagify Tags" folder
5. **Querying**: Complex queries executed against local database
6. **Export**: Results added to Spotify queue or saved as playlists

### Database Schema
```sql
-- Songs table
CREATE TABLE songs (
  id INTEGER PRIMARY KEY,
  spotify_id TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  album TEXT NOT NULL,
  album_art_url TEXT,
  duration_ms INTEGER,
  uri TEXT
);

-- Tags table (supports both tags and playlists)
CREATE TABLE tags (
  id INTEGER PRIMARY KEY,
  spotify_id TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('tag', 'playlist')),
  is_public BOOLEAN DEFAULT FALSE
);

-- Many-to-many relationship
CREATE TABLE song_tags (
  song_id INTEGER,
  tag_id INTEGER,
  PRIMARY KEY (song_id, tag_id)
);
```

## 📋 Development Roadmap

### Phase 1 ✅ Complete
- [x] Flutter project setup
- [x] Spotify OAuth authentication (PKCE with SHA256)
- [x] SQLite database schema
- [x] Core services and models
- [x] Basic UI navigation

### Phase 2 ✅ Complete
- [x] Library import from Spotify (paginated, with progress/cancel)
- [x] Tag management (create/rename/delete with Spotify sync)
- [x] Album art in library, search filtering
- [x] Web deployment (GitHub Actions → GitHub Pages)
- [x] Unit tests for ImportService and TagService

### Phase 3 🚧 Next (Week 3)
- [ ] Individual song tagging from detail screen
- [ ] Batch tagging operations
- [ ] Tag chips and UI components

### Phase 4 📅 Planned (Week 4)
- [ ] Query builder interface
- [ ] Query execution engine
- [ ] Results display

### Phase 5 📅 Planned (Week 5)
- [ ] Export to Spotify queue
- [ ] Save as playlist/tag
- [ ] Deep linking integration

### Phase 6 📅 Planned (Week 6)
- [ ] Sync and error handling
- [ ] UI polish and performance
- [ ] Testing and refinement

## 🤝 Contributing

This is currently a personal project for validating the concept. The codebase is well-structured and documented for future collaboration.

### Code Quality
- Clean architecture with service layer pattern
- Comprehensive error handling
- Performance-optimized database queries
- Modern Flutter best practices
- Material 3 design system

## 📄 License

This project is for personal use and development. See the [Product Requirements Document](docs/Tagify_PRD.md) for detailed specifications.

## 📚 Documentation

- [Product Requirements Document](docs/Tagify_PRD.md) - Complete product specifications
- [Development Roadmap](docs/Tagify_Development_Roadmap.md) - Detailed development plan
- [Flutter App README](src/README.md) - Technical implementation details

---

**Tagify** - Organize your music, discover new possibilities. 🎵
