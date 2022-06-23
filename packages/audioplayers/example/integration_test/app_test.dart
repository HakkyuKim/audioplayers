import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_example/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const String assetAudio = 'nasa_on_a_mission.mp3';
const Duration _kPlayDuration = Duration(seconds: 1);

/// Returns a future that completes when seek completes.
Future<void> seekSync(AudioPlayer player, Duration seekToPosition) async {
  final seek = Completer<void>();
  final subscription = player.onSeekComplete.listen((event) => seek.complete());

  await player.seek(seekToPosition);
  await seek.future;
  subscription.cancel();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('verify app is launched', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      expect(
        find.text('Remote URL WAV 1 - coins.wav'),
        findsOneWidget,
      );
    });
  });

  testWidgets('sends complete events in loop mode.',
      (WidgetTester tester) async {
    final player = AudioPlayer();
    final initialized = Completer<void>();
    player.onDurationChanged.listen((duration) {
      if (!initialized.isCompleted) {
        initialized.complete();
      }
    });

    await player.setSourceAsset(assetAudio);
    await initialized.future;
    final duration = await player.getDuration();
    expect(duration, isNotNull);
    await seekSync(player, duration! - const Duration(milliseconds: 500));

    await player.setReleaseMode(ReleaseMode.loop);
    var isComplete = false;
    player.onPlayerComplete.listen((event) {
      isComplete = true;
    });
    await player.resume();
    await Future<void>.delayed(_kPlayDuration);
    expect(isComplete, true);

    await player.dispose();
  });
}
