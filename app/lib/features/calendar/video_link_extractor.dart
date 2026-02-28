// Video call URL extraction service.
//
// TLDR:
// Overview: Finds Meet, Zoom, and Teams links in calendar event fields.
// Problem: Meeting links are often hidden in different parts of the event metadata.
// Solution: Implements a priority chain (hangoutLink → conferenceData → regex) for extraction.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

/// Extracts a video call URL from Google Calendar event fields.
///
/// Priority chain (first match wins):
///   1. hangoutLink         — explicit Google Meet API field
///   2. conferenceEntryPoints — structured conference data (Meet/Zoom/Teams via API)
///   3. location            — regex scan for known video URL patterns
///   4. description         — regex scan for known video URL patterns
abstract final class VideoLinkExtractor {
  static final _videoUrlPattern = RegExp(
    r'https?://(meet\.google\.com|zoom\.us/j|teams\.microsoft\.com/l/meetup-join|[\w.-]+\.webex\.com)[^\s]*',
    caseSensitive: false,
  );

  static String? extract({
    required String? hangoutLink,
    required List<String>? conferenceEntryPoints,
    required String? location,
    required String? description,
  }) {
    if (hangoutLink != null && hangoutLink.isNotEmpty) return hangoutLink;

    if (conferenceEntryPoints != null && conferenceEntryPoints.isNotEmpty) {
      return conferenceEntryPoints.first;
    }

    final fromLocation = _scanForUrl(location);
    if (fromLocation != null) return fromLocation;

    return _scanForUrl(description);
  }

  static String? _scanForUrl(String? text) {
    if (text == null || text.isEmpty) return null;
    return _videoUrlPattern.firstMatch(text)?.group(0);
  }
}
