// Local city name → (lat, lng) search backed by bundled GeoNames data.
//
// TLDR:
// Overview: Provides off-line city coordinate lookup using a bundled GeoNames dataset.
// Problem:  Need zero-dependency, off-line city-to-coordinate geocoding for location configuration.
// Solution: Searches a local CSV of 33,742 cities (cities.csv), preferring prefix matches, and parses lat/lng.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'package:flutter/services.dart';

List<String>? _cachedLines;

typedef CityMatch = ({double lat, double lng, String label});

/// Returns the best matching city for [query], or null if none found.
///
/// Searches the bundled GeoNames dataset (cities15000) case-insensitively.
/// Prefers prefix matches over substring matches.
Future<CityMatch?> searchCity(String query) async {
  final matches = await searchCities(query);
  return matches.isEmpty ? null : matches.first;
}

/// Returns up to [limit] cities matching [query], best match first.
///
/// Searches the bundled GeoNames dataset case-insensitively. Prefix matches
/// are ranked ahead of substring matches so the user can disambiguate between
/// same-named cities (e.g. Los Angeles, CA vs Los Angeles, CL).
Future<List<CityMatch>> searchCities(String query, {int limit = 25}) async {
  final q = query.toLowerCase().trim();
  if (q.isEmpty) return const [];

  _cachedLines ??= (await rootBundle.loadString('assets/data/cities.csv'))
      .split('\n')
      .where((l) => l.isNotEmpty)
      .toList();

  final prefixMatches = <CityMatch>[];
  final substringMatches = <CityMatch>[];
  for (final line in _cachedLines!) {
    final parts = line.split('|');
    if (parts.length < 4) continue;
    final name = parts[0].toLowerCase();
    final isPrefix = name.startsWith(q);
    if (!isPrefix && !name.contains(q)) continue;

    final lat = double.tryParse(parts[2]);
    final lng = double.tryParse(parts[3]);
    if (lat == null || lng == null) continue;

    final match = (lat: lat, lng: lng, label: '${parts[0]}, ${parts[1]}');
    (isPrefix ? prefixMatches : substringMatches).add(match);
    if (prefixMatches.length >= limit) break;
  }

  return [...prefixMatches, ...substringMatches].take(limit).toList();
}
