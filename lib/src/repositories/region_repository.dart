import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:injectable/injectable.dart';

import '../models/map_region.dart';

/// Repository for loading and managing map regions from JSON.
///
/// Provides methods to load hierarchical region data from the
/// bundled `assets/data/regions.json` file and query regions
/// by type, parent, or ID.
@lazySingleton
class RegionRepository {
  static const String _jsonPath = 'assets/data/regions.json';

  List<MapRegion>? _cachedRegions;

  /// Loads all regions from the JSON asset file.
  ///
  /// Caches the result to avoid repeated parsing on subsequent calls.
  Future<List<MapRegion>> loadAllRegions() async {
    if (_cachedRegions != null) {
      return _cachedRegions!;
    }

    final jsonString = await rootBundle.loadString(_jsonPath);
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

    _cachedRegions = jsonList
        .map((json) => MapRegion.fromJson(json as Map<String, dynamic>))
        .toList();

    return _cachedRegions!;
  }

  /// Gets all island groups (parent regions).
  ///
  /// Returns regions where [RegionType] is [RegionType.islandGroup],
  /// sorted by priority (lower = first).
  Future<List<MapRegion>> getIslandGroups() async {
    final regions = await loadAllRegions();
    return regions
        .where((r) => r.type == RegionType.islandGroup)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// Gets all islands (child regions) for a given parent ID.
  ///
  /// Returns regions where [parentId] matches the given ID,
  /// sorted by priority (lower = first).
  Future<List<MapRegion>> getIslandsForGroup(String parentId) async {
    final regions = await loadAllRegions();
    return regions.where((r) => r.parentId == parentId).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// Gets a region by ID.
  ///
  /// Returns `null` if no region with the given ID is found.
  Future<MapRegion?> getRegionById(String id) async {
    final regions = await loadAllRegions();
    try {
      return regions.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Gets all child regions for a parent, recursively if needed.
  ///
  /// Currently returns the same as [getIslandsForGroup] since
  /// we only have a two-level hierarchy. Can be extended for
  /// deeper nesting in the future.
  Future<List<MapRegion>> getAllChildRegions(String parentId) async {
    return getIslandsForGroup(parentId);
  }

  /// Gets all downloadable regions (islands only, not groups).
  ///
  /// Island groups are containers and not directly downloadable.
  /// Use this method to get all actual downloadable regions.
  Future<List<MapRegion>> getDownloadableRegions() async {
    final regions = await loadAllRegions();
    return regions.where((r) => r.type == RegionType.island).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// Calculates the total estimated size for an island group.
  ///
  /// Sums up the [estimatedSizeMB] of all child islands.
  Future<int> getTotalSizeForGroup(String groupId) async {
    final children = await getIslandsForGroup(groupId);
    return children.fold<int>(0, (sum, r) => sum + r.estimatedSizeMB);
  }

  /// Calculates the total estimated tile count for an island group.
  ///
  /// Sums up the [estimatedTileCount] of all child islands.
  Future<int> getTotalTileCountForGroup(String groupId) async {
    final children = await getIslandsForGroup(groupId);
    return children.fold<int>(0, (sum, r) => sum + r.estimatedTileCount);
  }

  /// Clears the cache (useful for testing or hot reload).
  void clearCache() {
    _cachedRegions = null;
  }
}