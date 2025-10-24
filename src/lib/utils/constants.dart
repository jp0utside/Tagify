class AppConstants {
  // Spotify API
  static const String spotifyBaseUrl = 'https://api.spotify.com/v1';
  static const String spotifyAuthUrl = 'https://accounts.spotify.com';
  
  // App Configuration
  static const String appName = 'Tagify';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String databaseName = 'tagify.db';
  static const int databaseVersion = 1;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Tagify Tags
  static const String tagifyTagPrefix = '#tag:';
  static const String tagifyFolderName = 'Tagify Tags';
  
  // Rate Limits
  static const int spotifyRateLimit = 180; // requests per minute
  static const Duration rateLimitDelay = Duration(milliseconds: 100);
  
  // Batch Sizes
  static const int defaultBatchSize = 50;
  static const int maxBatchSize = 100;
}
