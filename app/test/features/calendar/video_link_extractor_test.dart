import 'package:flutter_test/flutter_test.dart';
import 'package:happening/features/calendar/video_link_extractor.dart';

void main() {
  group('VideoLinkExtractor', () {
    // ── Priority 1: hangoutLink ───────────────────────────────────────────
    test('returns hangoutLink when present', () {
      expect(
        VideoLinkExtractor.extract(
          hangoutLink: 'https://meet.google.com/abc-defg-hij',
          conferenceEntryPoints: null,
          location: null,
          description: null,
        ),
        equals('https://meet.google.com/abc-defg-hij'),
      );
    });

    test('hangoutLink takes priority over conferenceData', () {
      expect(
        VideoLinkExtractor.extract(
          hangoutLink: 'https://meet.google.com/abc-defg-hij',
          conferenceEntryPoints: ['https://zoom.us/j/999'],
          location: null,
          description: null,
        ),
        equals('https://meet.google.com/abc-defg-hij'),
      );
    });

    // ── Priority 2: conferenceEntryPoints ─────────────────────────────────
    test('returns first conference entry point when no hangoutLink', () {
      expect(
        VideoLinkExtractor.extract(
          hangoutLink: null,
          conferenceEntryPoints: ['https://zoom.us/j/123456789'],
          location: null,
          description: null,
        ),
        equals('https://zoom.us/j/123456789'),
      );
    });

    test('returns null for empty conferenceEntryPoints list', () {
      expect(
        VideoLinkExtractor.extract(
          hangoutLink: null,
          conferenceEntryPoints: [],
          location: null,
          description: null,
        ),
        isNull,
      );
    });

    // ── Priority 3: location field regex ─────────────────────────────────
    test('extracts Zoom URL from location', () {
      expect(
        VideoLinkExtractor.extract(
          hangoutLink: null,
          conferenceEntryPoints: null,
          location: 'Zoom: https://zoom.us/j/987654321',
          description: null,
        ),
        equals('https://zoom.us/j/987654321'),
      );
    });

    test('extracts Teams URL from location', () {
      expect(
        VideoLinkExtractor.extract(
          hangoutLink: null,
          conferenceEntryPoints: null,
          location:
              'https://teams.microsoft.com/l/meetup-join/19%3Aabc/context',
          description: null,
        ),
        equals('https://teams.microsoft.com/l/meetup-join/19%3Aabc/context'),
      );
    });

    // ── Priority 4: description field regex ───────────────────────────────
    test('extracts Zoom URL from description', () {
      expect(
        VideoLinkExtractor.extract(
          hangoutLink: null,
          conferenceEntryPoints: null,
          location: 'Conference Room A',
          description:
              'Join us on Zoom:\nhttps://zoom.us/j/112233445\nPasscode: 1234',
        ),
        equals('https://zoom.us/j/112233445'),
      );
    });

    test('extracts Meet URL from description when no hangoutLink', () {
      expect(
        VideoLinkExtractor.extract(
          hangoutLink: null,
          conferenceEntryPoints: null,
          location: null,
          description: 'Video call: https://meet.google.com/xyz-uvwx-pqr',
        ),
        equals('https://meet.google.com/xyz-uvwx-pqr'),
      );
    });

    test('extracts Webex URL from description', () {
      expect(
        VideoLinkExtractor.extract(
          hangoutLink: null,
          conferenceEntryPoints: null,
          location: null,
          description: 'Meeting at https://company.webex.com/meet/user123',
        ),
        equals('https://company.webex.com/meet/user123'),
      );
    });

    // ── No match ─────────────────────────────────────────────────────────
    test('returns null when no video URL found anywhere', () {
      expect(
        VideoLinkExtractor.extract(
          hangoutLink: null,
          conferenceEntryPoints: null,
          location: 'Room 101, Building B',
          description: 'Bring your laptop and coffee.',
        ),
        isNull,
      );
    });

    test('returns null when all inputs are null', () {
      expect(
        VideoLinkExtractor.extract(
          hangoutLink: null,
          conferenceEntryPoints: null,
          location: null,
          description: null,
        ),
        isNull,
      );
    });
  });
}
