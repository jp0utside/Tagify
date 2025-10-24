# Tagify

**A powerful tagging system for Spotify that enables multi-dimensional music organization and complex queries.**

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-Personal-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Phase%201%20Complete-brightgreen.svg)](docs/Tagify_Development_Roadmap.md)

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
- **Spotify OAuth authentication** with PKCE security
- **SQLite database** with optimized schema for fast queries
- **Core services** for API integration and local data management
- **UI foundation** with Material 3 theming and navigation

### 🚧 Next: Phase 2 - Library Import & Data Management
- Import user's Spotify library and playlists
- Tag management functionality
- Data sync between local and Spotify

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
│   │   │   ├── auth_service.dart  # Authentication
│   │   │   ├── database_service.dart # Local database
│   │   │   └── spotify_service.dart # Spotify API
│   │   ├── screens/               # UI screens
│   │   │   ├── auth/              # Authentication screens
│   │   │   ├── main/              # Main navigation
│   │   │   ├── library/           # Song library
│   │   │   ├── query/             # Query builder
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

#### Current Phase 1 Features
- **Authentication**: Tap "Connect with Spotify" to test OAuth flow
- **Navigation**: Use bottom navigation to explore different screens
- **Settings**: View user profile and app information
- **Database**: Check that local database is initialized

#### What Works Now
- ✅ Spotify OAuth authentication
- ✅ Secure token storage and refresh
- ✅ Local SQLite database setup
- ✅ Basic UI navigation
- ✅ User profile display

#### What's Coming in Phase 2
- 🚧 Library import from Spotify
- 🚧 Tag creation and management
- 🚧 Song tagging functionality
- 🚧 Query builder interface

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
- [x] Spotify OAuth authentication
- [x] SQLite database schema
- [x] Core services and models
- [x] Basic UI navigation

### Phase 2 🚧 Next (Week 2)
- [ ] Library import from Spotify
- [ ] Tag management functionality
- [ ] Data sync implementation

### Phase 3 📅 Planned (Week 3)
- [ ] Individual song tagging
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
