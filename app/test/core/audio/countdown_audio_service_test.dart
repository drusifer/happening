import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/audio/countdown_audio_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([MockSpec<AudioPlayer>()])
import 'countdown_audio_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CountdownAudioMath', () {
    test('calculateIntervalSeconds starts at 1.5s at 60s remaining', () {
      final interval = CountdownAudioMath.calculateIntervalSeconds(60.0);
      expect(interval, closeTo(1.5, 0.001));
    });

    test('calculateIntervalSeconds accelerates to 0.12s at 0s remaining', () {
      final interval = CountdownAudioMath.calculateIntervalSeconds(0.0);
      expect(interval, closeTo(0.12, 0.001));
    });

    test('calculateIntervalSeconds is monotonic decreasing as T decreases', () {
      final t60 = CountdownAudioMath.calculateIntervalSeconds(60.0);
      final t30 = CountdownAudioMath.calculateIntervalSeconds(30.0);
      final t10 = CountdownAudioMath.calculateIntervalSeconds(10.0);
      final t0 = CountdownAudioMath.calculateIntervalSeconds(0.0);

      expect(t60 > t30, isTrue);
      expect(t30 > t10, isTrue);
      expect(t10 > t0, isTrue);
    });

    test('calculateVolume starts soft at 0.15 at 60s remaining', () {
      final vol = CountdownAudioMath.calculateVolume(60.0);
      expect(vol, closeTo(0.15, 0.001));
    });

    test('calculateVolume reaches 1.0 at 0s remaining', () {
      final vol = CountdownAudioMath.calculateVolume(0.0);
      expect(vol, closeTo(1.0, 0.001));
    });
  });

  group('CountdownAudioService', () {
    late MockAudioPlayer mockPlayer;
    late CountdownAudioService service;

    setUp(() {
      mockPlayer = MockAudioPlayer();
      when(mockPlayer.setVolume(any)).thenAnswer((_) async {});
      when(mockPlayer.play(any)).thenAnswer((_) async {});
      when(mockPlayer.stop()).thenAnswer((_) async {});
      when(mockPlayer.dispose()).thenAnswer((_) async {});

      service = CountdownAudioService(player: mockPlayer);
    });

    tearDown(() {
      service.dispose();
    });

    test('does not start audio if remaining seconds > 60', () {
      service.updateRemainingSeconds(65, enabled: true);
      expect(service.isPlaying, isFalse);
      verifyNever(mockPlayer.play(any));
    });

    test('does not start audio if disabled', () {
      service.updateRemainingSeconds(30, enabled: false);
      expect(service.isPlaying, isFalse);
      verifyNever(mockPlayer.play(any));
    });

    test('starts audio and alternates beats when remaining seconds <= 60', () async {
      service.updateRemainingSeconds(30, enabled: true);
      expect(service.isPlaying, isTrue);

      await Future<void>.value();

      verify(mockPlayer.setVolume(argThat(greaterThan(0.15)))).called(1);
      verify(mockPlayer.play(argThat(isA<AssetSource>()))).called(1);
    });

    test('stop() cancels audio playback', () {
      service.updateRemainingSeconds(30, enabled: true);
      expect(service.isPlaying, isTrue);

      service.stop();
      expect(service.isPlaying, isFalse);
    });

    test('playStartupSound plays fire.wav when enabled', () async {
      await service.playStartupSound(enabled: true);
      expect(service.hasPlayedStartup, isTrue);
      verify(mockPlayer.play(argThat(predicate<AssetSource>((s) => s.path == 'audio/fire.wav')))).called(1);
    });

    test('does not play bang sound at launch when not playing countdown', () async {
      service.updateRemainingSeconds(0, enabled: true);

      await Future<void>.value();

      expect(service.hasPlayedBang, isFalse);
      verifyNever(mockPlayer.play(argThat(predicate<AssetSource>((s) => s.path == 'audio/bangLarge.wav'))));
    });

    test('plays bangLarge sound when countdown reaches 0 seconds after playing', () async {
      service.updateRemainingSeconds(30, enabled: true);
      service.updateRemainingSeconds(0, enabled: true);

      await Future<void>.value();

      expect(service.hasPlayedBang, isTrue);
      expect(service.isPlaying, isFalse);
      verify(mockPlayer.play(argThat(predicate<AssetSource>((s) => s.path == 'audio/bangLarge.wav')))).called(1);
    });
  });
}
