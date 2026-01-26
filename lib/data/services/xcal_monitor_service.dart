import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for monitoring xCal URL for changes using hash comparison
class XCalMonitorService {
  final Dio dio;
  final SharedPreferences prefs;

  XCalMonitorService({
    required this.dio,
    required this.prefs,
  });

  static const String _hashKeyPrefix = 'xcal_hash_';
  static const String _lastCheckKeyPrefix = 'xcal_last_check_';

  /// Get a normalized key for storing hash based on URL
  String _getHashKey(String url) {
    final urlHash = sha256.convert(utf8.encode(url)).toString();
    return '$_hashKeyPrefix$urlHash';
  }

  /// Get a normalized key for storing last check time based on URL
  String _getLastCheckKey(String url) {
    final urlHash = sha256.convert(utf8.encode(url)).toString();
    return '$_lastCheckKeyPrefix$urlHash';
  }

  /// Get the stored hash for a URL
  Future<String?> getLastCheckedHash(String url) async {
    final key = _getHashKey(url);
    return prefs.getString(key);
  }

  /// Get the last check time for a URL
  DateTime? getLastCheckTime(String url) {
    final key = _getLastCheckKey(url);
    final timestamp = prefs.getInt(key);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Update the stored hash after a successful check
  Future<void> updateLastCheckedHash(String url, String hash) async {
    final hashKey = _getHashKey(url);
    final checkKey = _getLastCheckKey(url);
    await prefs.setString(hashKey, hash);
    await prefs.setInt(checkKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Calculate SHA-256 hash of content
  String _calculateHash(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if content at URL has changed
  /// Returns true if content has changed or if no previous hash exists
  /// Returns false if content is the same
  /// Throws exception on network or other errors
  Future<bool> checkForChanges(String url) async {
    try {
      print('🔍 Checking for changes in xCal URL: $url');
      
      // Fetch content from URL
      final response = await dio.get(url);
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch xCal: HTTP ${response.statusCode}');
      }

      final content = response.data.toString();
      final currentHash = _calculateHash(content);
      
      // Get stored hash
      final storedHash = await getLastCheckedHash(url);
      
      if (storedHash == null) {
        print('📝 No previous hash found - treating as new content');
        // Store hash for future comparison
        await updateLastCheckedHash(url, currentHash);
        return true; // New content, treat as changed
      }
      
      if (currentHash == storedHash) {
        print('✅ Content unchanged (hash matches)');
        // Update last check time even if no change
        await updateLastCheckedHash(url, currentHash);
        return false; // No change
      } else {
        print('🔄 Content changed (hash differs)');
        // Update hash after detecting change
        await updateLastCheckedHash(url, currentHash);
        return true; // Content has changed
      }
    } catch (e) {
      print('❌ Error checking for changes: $e');
      rethrow;
    }
  }

  /// Get the content hash without storing it
  /// Useful for one-time checks
  Future<String> getContentHash(String url) async {
    final response = await dio.get(url);
    
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch xCal: HTTP ${response.statusCode}');
    }

    final content = response.data.toString();
    return _calculateHash(content);
  }
}
