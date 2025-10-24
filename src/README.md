# Tagify

A mobile app that adds a powerful tagging system to Spotify, enabling multi-dimensional organization and complex queries across your music library.

## Features

- **Spotify Integration**: Connect with your Spotify account and import your library
- **Tagging System**: Add multiple tags to songs for flexible organization
- **Smart Queries**: Use AND, OR, NOT logic to find exactly the music you want
- **Export Options**: Add results to Spotify queue or save as playlists
- **Local Database**: Fast queries using SQLite for instant results

## Development Status

This is Phase 1 of development, which includes:

### ✅ Completed
- Flutter project setup with proper structure
- Core dependencies installed and configured
- Database schema implemented (SQLite)
- Authentication service with Spotify OAuth
- Basic app navigation structure
- Data models for songs, tags, and relationships
- Service layer for Spotify API integration

### 🚧 In Progress
- Spotify authentication flow
- Database service implementation
- Basic UI screens

### 📋 Next Steps
- Complete authentication flow
- Implement library import
- Add tag management functionality
- Build query system
- Add export capabilities

## Getting Started

### Prerequisites
- Flutter SDK 3.16+
- Xcode 15+ (for iOS development)
- Android Studio (for Android development)
- Spotify Developer Account

### Setup
1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Configure Spotify API credentials in `.env` file
4. Run the app: `flutter run`

### Environment Variables
Create a `.env` file in the root directory with:
```
SPOTIFY_CLIENT_ID=your_spotify_client_id_here
SPOTIFY_REDIRECT_URI=tagify://auth
SPOTIFY_SCOPE=user-library-read playlist-read-private playlist-modify-private user-modify-playback-state
```

## Architecture

### Core Components
- **Models**: Song, Tag, SongTag, User
- **Services**: AuthService, DatabaseService, SpotifyService
- **Screens**: Library, Query, Tags, Settings
- **Database**: SQLite with optimized schema for fast queries

### Data Flow
1. User authenticates with Spotify
2. Library and playlists are imported from Spotify
3. Data is stored locally in SQLite for fast access
4. Tags are created as Spotify playlists in "Tagify Tags" folder
5. Queries are executed against local database
6. Results can be exported to Spotify queue or saved as playlists

## License

This project is for personal use and development.
