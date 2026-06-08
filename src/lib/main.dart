import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/spotify_service.dart';
import 'services/import_service.dart';
import 'services/tag_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final databaseService = DatabaseService();
  await databaseService.init();

  final authService = AuthService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authService),
        Provider<DatabaseService>(create: (_) => databaseService),
        ProxyProvider<AuthService, SpotifyService>(
          update: (_, auth, __) => SpotifyService(auth),
        ),
        ChangeNotifierProxyProvider2<SpotifyService, DatabaseService,
            ImportService>(
          create: (context) => ImportService(
            spotifyService: SpotifyService(authService),
            databaseService: databaseService,
          ),
          update: (_, spotify, db, previous) =>
              previous ??
              ImportService(spotifyService: spotify, databaseService: db),
        ),
        ChangeNotifierProxyProvider2<SpotifyService, DatabaseService,
            TagService>(
          create: (context) => TagService(
            spotifyService: SpotifyService(authService),
            databaseService: databaseService,
          ),
          update: (_, spotify, db, previous) =>
              previous ??
              TagService(spotifyService: spotify, databaseService: db),
        ),
      ],
      child: const TagifyApp(),
    ),
  );
}
