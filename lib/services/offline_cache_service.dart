import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zim_tracker/models/grid_zone.dart';

/// Caches the last successfully-fetched national grid so the app can show
/// *something* useful with no signal -- which is exactly the moment a
/// load-shedding app matters most. This is a simple last-known-good cache,
/// not a full offline-first sync layer.
class OfflineCacheService {
  static const _zonesKey = 'cached_zones_v1';
  static const _cachedAtKey = 'cached_zones_at_v1';

  Future<void> cacheZones(List<GridZone> zones) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(zones.map((z) => {
          'id': z.id,
          ...z.toMap(),
          // toMap() stores DateTime objects directly, which jsonEncode
          // can't serialize -- convert to ISO strings for the cache.
          'lastUpdated': z.lastUpdated.toIso8601String(),
          'estimatedRestoration': z.estimatedRestoration?.toIso8601String(),
        }).toList());
    await prefs.setString(_zonesKey, encoded);
    await prefs.setString(_cachedAtKey, DateTime.now().toIso8601String());
  }

  /// Returns the last cached zone list, or an empty list if nothing has
  /// ever been cached (e.g. very first launch with no connectivity at all).
  Future<List<GridZone>> getCachedZones() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_zonesKey);
    if (raw == null) return [];

    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((data) {
        final map = Map<String, dynamic>.from(data);
        return GridZone(
          id: map['id'],
          name: map['name'] ?? '',
          region: map['region'] ?? '',
          status: map['status'] == 'ON' || map['status'] == 'on' ? PowerStatus.on : PowerStatus.off,
          estimatedRestoration: map['estimatedRestoration'] != null ? DateTime.parse(map['estimatedRestoration']) : null,
          lastUpdated: map['lastUpdated'] != null ? DateTime.parse(map['lastUpdated']) : DateTime.now(),
          latitude: (map['latitude'] ?? -17.8216).toDouble(),
          longitude: (map['longitude'] ?? 31.0492).toDouble(),
          suburbCode: map['suburbCode'] ?? '',
          accurateVotes: (map['accurateVotes'] ?? 0) as int,
          inaccurateVotes: (map['inaccurateVotes'] ?? 0) as int,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<DateTime?> getCachedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedAtKey);
    return raw != null ? DateTime.parse(raw) : null;
  }
}
