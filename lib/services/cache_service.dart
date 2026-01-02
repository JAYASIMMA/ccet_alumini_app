import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const Duration _defaultTv = Duration(hours: 24); // Default Time-to-Live

  // Singleton instance
  static final CacheService _instance = CacheService._internal();

  factory CacheService() {
    return _instance;
  }

  CacheService._internal();

  /// Save data to cache with an optional expiration time.
  /// [key] - Unique key for the data.
  /// [data] - The data to save (must be json encodable).
  /// [expiration] - Optional duration after which the data expires.
  Future<void> save(String key, dynamic data, {Duration? expiration}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'expiry': (expiration ?? _defaultTv).inMilliseconds,
        'data': data,
      };
      await prefs.setString(key, jsonEncode(cacheEntry));
    } catch (e) {
      print('CacheService: Error saving key $key: $e');
    }
  }

  /// Get data from cache. Returns null if not found or expired.
  Future<dynamic> get(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(key);

      if (jsonString == null) return null;

      final Map<String, dynamic> cacheEntry = jsonDecode(jsonString);
      final DateTime timestamp = DateTime.parse(cacheEntry['timestamp']);
      final int expiryMs = cacheEntry['expiry'];
      final dynamic data = cacheEntry['data'];

      final DateTime now = DateTime.now();
      if (now.difference(timestamp).inMilliseconds > expiryMs) {
        // Cache expired
        await remove(key);
        return null;
      }

      return data;
    } catch (e) {
      print('CacheService: Error retrieving key $key: $e');
      return null;
    }
  }

  /// Remove a specific key from cache.
  Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      print('CacheService: Error removing key $key: $e');
    }
  }

  /// Clear all cache.
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('CacheService: Error clearing cache: $e');
    }
  }
}
