import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const String _accessTokenKey = 'spotify_access_token';
  static const String _refreshTokenKey = 'spotify_refresh_token';
  static const String _userKey = 'spotify_user';

  String? _accessToken;
  String? _refreshToken;
  User? _user;
  bool _isLoading = false;

  String? get accessToken => _accessToken;
  User? get user => _user;
  bool get isAuthenticated => _accessToken != null;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadStoredTokens();
  }

  Future<void> _loadStoredTokens() async {
    try {
      _accessToken = await _storage.read(key: _accessTokenKey);
      _refreshToken = await _storage.read(key: _refreshTokenKey);
      final userJson = await _storage.read(key: _userKey);
      
      if (userJson != null) {
        _user = User.fromJson(jsonDecode(userJson));
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading stored tokens: $e');
    }
  }

  Future<bool> login() async {
    _isLoading = true;
    notifyListeners();

    try {
      final clientId = dotenv.env['SPOTIFY_CLIENT_ID'];
      final redirectUri = dotenv.env['SPOTIFY_REDIRECT_URI'];
      final scope = dotenv.env['SPOTIFY_SCOPE'];

      if (clientId == null || redirectUri == null || scope == null) {
        throw Exception('Missing Spotify configuration');
      }

      // Generate PKCE parameters
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);
      final state = _generateRandomString(16);

      // Store code verifier and state for later verification
      await _storage.write(key: 'code_verifier', value: codeVerifier);
      await _storage.write(key: 'auth_state', value: state);

      // Build authorization URL
      final authUrl = Uri.https('accounts.spotify.com', '/authorize', {
        'response_type': 'code',
        'client_id': clientId,
        'scope': scope,
        'redirect_uri': redirectUri,
        'code_challenge_method': 'S256',
        'code_challenge': codeChallenge,
        'state': state,
      });

      // Launch browser for authentication
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
        return true;
      } else {
        throw Exception('Could not launch authentication URL');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> handleAuthCallback(String code, String state) async {
    try {
      // Verify state parameter
      final storedState = await _storage.read(key: 'auth_state');
      if (state != storedState) {
        throw Exception('Invalid state parameter');
      }

      final codeVerifier = await _storage.read(key: 'code_verifier');
      if (codeVerifier == null) {
        throw Exception('Code verifier not found');
      }

      // Exchange code for tokens
      final success = await _exchangeCodeForTokens(code, codeVerifier);
      
      if (success) {
        // Fetch user profile
        await _fetchUserProfile();
        
        // Clean up temporary storage
        await _storage.delete(key: 'code_verifier');
        await _storage.delete(key: 'auth_state');
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('Auth callback error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _exchangeCodeForTokens(String code, String codeVerifier) async {
    try {
      final clientId = dotenv.env['SPOTIFY_CLIENT_ID'];
      final redirectUri = dotenv.env['SPOTIFY_REDIRECT_URI'];

      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri!,
          'client_id': clientId!,
          'code_verifier': codeVerifier,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        
        // Store tokens securely
        await _storage.write(key: _accessTokenKey, value: _accessToken);
        await _storage.write(key: _refreshTokenKey, value: _refreshToken);
        
        return true;
      } else {
        debugPrint('Token exchange failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Token exchange error: $e');
      return false;
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/me'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _user = User.fromJson(userData);
        
        // Store user data
        await _storage.write(
          key: _userKey, 
          value: jsonEncode(_user!.toJson()),
        );
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<void> refreshAccessToken() async {
    if (_refreshToken == null) {
      await logout();
      return;
    }

    try {
      final clientId = dotenv.env['SPOTIFY_CLIENT_ID'];

      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken!,
          'client_id': clientId!,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        
        // Update stored token
        await _storage.write(key: _accessTokenKey, value: _accessToken);
        
        // Update refresh token if provided
        if (data['refresh_token'] != null) {
          _refreshToken = data['refresh_token'];
          await _storage.write(key: _refreshTokenKey, value: _refreshToken);
        }
      } else {
        await logout();
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
      await logout();
    }
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    
    // Clear stored data
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
    
    notifyListeners();
  }

  String _generateCodeVerifier() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(128, (i) => chars[random.nextInt(chars.length)]).join();
  }

  String _generateCodeChallenge(String codeVerifier) {
    // In a real implementation, you'd use SHA256 and base64url encoding
    // For now, we'll use a simplified approach
    return codeVerifier;
  }

  String _generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(length, (i) => chars[random.nextInt(chars.length)]).join();
  }
}
