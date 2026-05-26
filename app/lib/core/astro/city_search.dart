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

/// Returns the best matching city for [query], or null if none found.
///
/// Searches the bundled GeoNames dataset (cities15000) case-insensitively.
/// Prefers prefix matches over substring matches.
Future<({double lat, double lng, String label})?> searchCity(
    String query) async {
  final q = query.toLowerCase().trim();
  if (q.isEmpty) return null;

  _cachedLines ??= (await rootBundle.loadString('assets/data/cities.csv'))
      .split('\n')
      .where((l) => l.isNotEmpty)
      .toList();

  String? best;
  for (final line in _cachedLines!) {
    final name = line.split('|')[0].toLowerCase();
    if (name.startsWith(q)) {
      best = line;
      break;
    }
    if (best == null && name.contains(q)) {
      best = line;
    }
  }

  if (best == null) return null;
  final parts = best.split('|');
  if (parts.length < 4) return null;
  final lat = double.tryParse(parts[2]);
  final lng = double.tryParse(parts[3]);
  if (lat == null || lng == null) return null;
  return (lat: lat, lng: lng, label: '${parts[0]}, ${parts[1]}');
}
