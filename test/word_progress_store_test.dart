import 'package:flutter_test/flutter_test.dart';
import 'package:jogopalavras/src/game/game_level.dart';
import 'package:jogopalavras/src/game/word_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('salva palavras usadas por nivel', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    var usedWords = await WordProgressStore.instance.loadUsedWords(
      GameLevel.easy,
    );
    expect(usedWords, isEmpty);

    usedWords = await WordProgressStore.instance.markWordsUsed(GameLevel.easy, [
      'CASA',
      'bolo',
    ]);

    expect(usedWords, containsAll(<String>['CASA', 'BOLO']));
    expect(
      await WordProgressStore.instance.loadUsedWords(GameLevel.medium),
      isEmpty,
    );

    await WordProgressStore.instance.resetLevel(GameLevel.easy);
    expect(
      await WordProgressStore.instance.loadUsedWords(GameLevel.easy),
      isEmpty,
    );
    expect(
      await WordProgressStore.instance.loadCompletedStageCount(GameLevel.easy),
      0,
    );
  });

  test('salva fase concluida separada da contagem de palavras', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    expect(
      await WordProgressStore.instance.markStageCompleted(GameLevel.easy, 10),
      10,
    );
    expect(
      await WordProgressStore.instance.markStageCompleted(GameLevel.easy, 8),
      10,
    );
    expect(
      await WordProgressStore.instance.loadCompletedStageCount(GameLevel.easy),
      10,
    );
  });

  test('repara cache antigo de etapas uma unica vez', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'word_progress_used_v1:easy': List<String>.generate(
        100,
        (index) => 'PALAVRA_$index',
      ),
    });

    await WordProgressStore.instance.repairStageProgressCacheOnce();
    expect(
      await WordProgressStore.instance.loadCompletedStageCount(GameLevel.easy),
      10,
    );
  });
}
