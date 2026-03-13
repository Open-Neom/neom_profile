import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/utils/constants/app_hive_constants.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';

/// Offline cache controller for visited profiles.
/// Caches recently visited profiles for offline access.
class ProfileCacheController {
  static final ProfileCacheController _instance = ProfileCacheController._internal();
  factory ProfileCacheController() => _instance;
  ProfileCacheController._internal();

  Box? _box;

  static const int _maxCachedProfiles = 50;
  static const int _cacheExpirationDays = 7;

  Future<Box> _getBox() async {
    _box ??= await Hive.openBox(AppHiveBox.visitedProfiles.name);
    return _box!;
  }

  // ============ VISITED PROFILES CACHE ============

  /// Cache a visited profile for offline access.
  Future<void> cacheProfile(AppProfile profile) async {
    try {
      final box = await _getBox();
      final key = '${AppHiveConstants.visitedProfilePrefix}${profile.id}';

      // Store profile with timestamp
      final cacheData = {
        'profile': profile.toJSON(),
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      };

      await box.put(key, jsonEncode(cacheData));

      // Update visited IDs list (for ordering by recency)
      await _updateVisitedIds(profile.id);

      // Cleanup old profiles if exceeding limit
      await _cleanupOldProfiles();

      AppConfig.logger.d('Cached profile: ${profile.id}');
    } catch (e) {
      AppConfig.logger.e('Error caching profile: $e');
    }
  }

  /// Get a cached profile by ID.
  Future<AppProfile?> getCachedProfile(String profileId) async {
    AppConfig.logger.d('Getting cached profile: $profileId');
    
    try {
      final box = await _getBox();
      final key = '${AppHiveConstants.visitedProfilePrefix}$profileId';
      final json = box.get(key) as String?;

      if (json != null) {
        final cacheData = jsonDecode(json) as Map<String, dynamic>;
        final cachedAt = cacheData['cachedAt'] as int;

        // Check if cache is still valid
        const expirationMs = _cacheExpirationDays * 24 * 60 * 60 * 1000;
        if (DateTime.now().millisecondsSinceEpoch - cachedAt > expirationMs) {
          // Cache expired, remove it
          await removeCachedProfile(profileId);
          return null;
        }

        final profileData = cacheData['profile'] as Map<String, dynamic>;
        return AppProfile.fromJSON(profileData);
      }
    } catch (e) {
      AppConfig.logger.e('Error getting cached profile: $e');
    }
    return null;
  }

  /// Get all cached profiles (sorted by most recent).
  Future<List<AppProfile>> getAllCachedProfiles() async {
    final profiles = <AppProfile>[];
    try {
      await _getBox();
      final visitedIds = await _getVisitedIds();

      for (final id in visitedIds) {
        final profile = await getCachedProfile(id);
        if (profile != null) {
          profiles.add(profile);
        }
      }
    } catch (e) {
      AppConfig.logger.e('Error getting all cached profiles: $e');
    }
    return profiles;
  }

  /// Get recently visited profile IDs (most recent first).
  Future<List<String>> getRecentlyVisitedIds({int limit = 10}) async {
    try {
      final ids = await _getVisitedIds();
      return ids.take(limit).toList();
    } catch (e) {
      AppConfig.logger.e('Error getting recently visited IDs: $e');
    }
    return [];
  }

  /// Remove a cached profile.
  Future<void> removeCachedProfile(String profileId) async {
    try {
      final box = await _getBox();
      await box.delete('${AppHiveConstants.visitedProfilePrefix}$profileId');

      // Remove from visited IDs list
      final ids = await _getVisitedIds();
      ids.remove(profileId);
      await _saveVisitedIds(ids);

      AppConfig.logger.d('Removed cached profile: $profileId');
    } catch (e) {
      AppConfig.logger.e('Error removing cached profile: $e');
    }
  }

  /// Check if a profile is cached.
  Future<bool> isProfileCached(String profileId) async {
    try {
      final box = await _getBox();
      return box.containsKey('${AppHiveConstants.visitedProfilePrefix}$profileId');
    } catch (e) {
      return false;
    }
  }

  /// Get count of cached profiles.
  Future<int> getCachedProfileCount() async {
    try {
      final ids = await _getVisitedIds();
      return ids.length;
    } catch (e) {
      return 0;
    }
  }

  // ============ PRIVATE HELPERS ============

  Future<List<String>> _getVisitedIds() async {
    try {
      final box = await _getBox();
      final idsJson = box.get(AppHiveConstants.visitedProfileIds) as String?;
      if (idsJson != null) {
        final ids = jsonDecode(idsJson) as List<dynamic>;
        return ids.cast<String>();
      }
    } catch (e) {
      AppConfig.logger.e('Error getting visited IDs: $e');
    }
    return [];
  }

  Future<void> _saveVisitedIds(List<String> ids) async {
    try {
      final box = await _getBox();
      await box.put(AppHiveConstants.visitedProfileIds, jsonEncode(ids));
    } catch (e) {
      AppConfig.logger.e('Error saving visited IDs: $e');
    }
  }

  Future<void> _updateVisitedIds(String profileId) async {
    final ids = await _getVisitedIds();

    // Remove if already exists (to move to front)
    ids.remove(profileId);

    // Add to front (most recent)
    ids.insert(0, profileId);

    await _saveVisitedIds(ids);
  }

  Future<void> _cleanupOldProfiles() async {
    try {
      final ids = await _getVisitedIds();

      if (ids.length > _maxCachedProfiles) {
        // Remove oldest profiles
        final toRemove = ids.sublist(_maxCachedProfiles);
        for (final id in toRemove) {
          await removeCachedProfile(id);
        }
      }
    } catch (e) {
      AppConfig.logger.e('Error cleaning up old profiles: $e');
    }
  }

  // ============ CACHE MANAGEMENT ============

  /// Clear all cached profiles.
  Future<void> clearAll() async {
    try {
      final box = await _getBox();
      await box.clear();
      AppConfig.logger.d('Cleared all cached profiles');
    } catch (e) {
      AppConfig.logger.e('Error clearing profile cache: $e');
    }
  }

  /// Get cache statistics.
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final box = await _getBox();
      final ids = await _getVisitedIds();
      final lastUpdate = box.get(AppHiveConstants.profileCacheLastUpdate) as int?;

      return {
        'cachedCount': ids.length,
        'maxCache': _maxCachedProfiles,
        'lastUpdate': lastUpdate != null
            ? DateTime.fromMillisecondsSinceEpoch(lastUpdate).toIso8601String()
            : null,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
