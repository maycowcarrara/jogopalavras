import 'package:flutter_test/flutter_test.dart';
import 'package:jogopalavras/src/game/game_level.dart';
import 'package:jogopalavras/src/game/ranking_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ordena ranking por eficiencia de palavras e tempo', () {
    final now = DateTime(2026, 4, 28);
    final entries = <RankingEntry>[
      RankingEntry(
        initials: 'AAA',
        level: GameLevel.easy,
        score: 164,
        words: 14,
        elapsedSeconds: 176,
        completedAt: now,
      ),
      RankingEntry(
        initials: 'BBB',
        level: GameLevel.easy,
        score: 162,
        words: 10,
        elapsedSeconds: 71,
        completedAt: now,
      ),
      RankingEntry(
        initials: 'CCC',
        level: GameLevel.easy,
        score: 160,
        words: 10,
        elapsedSeconds: 68,
        completedAt: now,
      ),
      RankingEntry(
        initials: 'DDD',
        level: GameLevel.easy,
        score: 170,
        words: 11,
        elapsedSeconds: 45,
        completedAt: now,
      ),
    ];

    final ranking = RankingStore.bestEntries(entries);

    expect(
      ranking.map((entry) => entry.initials),
      orderedEquals(<String>['CCC', 'BBB', 'DDD', 'AAA']),
    );

    expect(
      RankingStore.scoreForPerformance(words: 10, elapsedSeconds: 71),
      greaterThan(
        RankingStore.scoreForPerformance(words: 14, elapsedSeconds: 176),
      ),
    );
  });

  test('recalcula pontuacao salva a partir da eficiencia', () {
    final entry = RankingEntry.fromJson(<String, Object?>{
      'initials': 'MRC',
      'level': 'easy',
      'score': 164,
      'words': 14,
      'elapsedSeconds': 176,
      'completedAt': DateTime(2026, 4, 28).toIso8601String(),
    });

    expect(
      entry.score,
      RankingStore.scoreForPerformance(words: 14, elapsedSeconds: 176),
    );
  });

  test('lembra as ultimas iniciais usadas no ranking', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await RankingStore.instance.saveLastInitials('abc');

    expect(await RankingStore.instance.loadLastInitials(), 'ABC');
  });

  test('salvar entrada atualiza iniciais lembradas', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await RankingStore.instance.saveEntry(
      RankingEntry(
        initials: 'XYZ',
        level: GameLevel.easy,
        score: 150,
        words: 15,
        elapsedSeconds: 90,
        completedAt: DateTime(2026, 4, 28),
      ),
    );

    expect(await RankingStore.instance.loadLastInitials(), 'XYZ');
  });
}
