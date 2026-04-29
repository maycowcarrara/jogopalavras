import 'package:flutter_test/flutter_test.dart';
import 'package:jogopalavras/src/game/campaign_progress_store.dart';
import 'package:jogopalavras/src/game/game_level.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('desbloqueia a campanha em ordem editorial', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    var progress = await CampaignProgressStore.instance.loadProgress();

    expect(progress.isUnlocked(GameLevel.easy), isTrue);
    expect(progress.isUnlocked(GameLevel.medium), isFalse);
    expect(progress.isUnlocked(GameLevel.hard), isFalse);
    expect(progress.isUnlocked(GameLevel.pautaLivre), isTrue);

    progress = await CampaignProgressStore.instance.completeLevel(
      GameLevel.easy,
    );

    expect(progress.isCompleted(GameLevel.easy), isTrue);
    expect(progress.isUnlocked(GameLevel.medium), isTrue);
    expect(progress.nextLevelAfter(GameLevel.easy), GameLevel.medium);

    progress = await CampaignProgressStore.instance.completeLevel(
      GameLevel.medium,
    );

    expect(progress.isCompleted(GameLevel.medium), isTrue);
    expect(progress.isUnlocked(GameLevel.hard), isTrue);
    expect(progress.nextLevelAfter(GameLevel.medium), GameLevel.hard);
  });
}
