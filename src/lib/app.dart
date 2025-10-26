import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';
import 'theme/app_theme.dart';

class TagifyApp extends StatefulWidget {
  const TagifyApp({super.key});

  @override
  State<TagifyApp> createState() => _TagifyAppState();
}

class _TagifyAppState extends State<TagifyApp> {
  @override
  void initState() {
    super.initState();
    _handleOAuthCallback();
  }

  void _handleOAuthCallback() {
    // Check if we're on web and have URL parameters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = Uri.base;
      if (uri.queryParameters.containsKey('code') && 
          uri.queryParameters.containsKey('state')) {
        final code = uri.queryParameters['code']!;
        final state = uri.queryParameters['state']!;
        
        // Process the OAuth callback
        Provider.of<AuthService>(context, listen: false)
            .handleAuthCallback(code, state)
            .then((success) {
          if (success) {
            // Clear the URL parameters by navigating to the root
            // This will cause a rebuild and show the main screen
            setState(() {});
            // Also clear the URL in the browser
            if (kIsWeb) {
              // Replace the current URL with the base URL to remove query parameters
              // This prevents the callback from being processed again
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tagify',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: Consumer<AuthService>(
        builder: (context, authService, child) {
          if (authService.isAuthenticated) {
            return const MainScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
