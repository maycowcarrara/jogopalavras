import 'package:flutter_test/flutter_test.dart';
import 'package:jogopalavras/src/game/game_level.dart';
import 'package:jogopalavras/src/game/ranking_store.dart';

void main() {
  test('ordena ranking por pontos, palavras e tempo', () {
    final now = DateTime(2026, 4, 28);
    final entries = <RankingEntry>[
      RankingEntry(
        initials: 'AAA',
        level: GameLevel.easy,
        score: 100,
        words: 8,
        elapsedSeconds: 80,
        completedAt: now,
      ),
      RankingEntry(
        initials: 'BBB',
        level: GameLevel.easy,
        score: 120,
        words: 8,
        elapsedSeconds: 100,
        completedAt: now,
      ),
      RankingEntry(
        initials: 'CCC',
        level: GameLevel.easy,
        score: 120,
        words: 7,
        elapsedSeconds: 100,
        completedAt: now,
      ),
      RankingEntry(
        initials: 'DDD',
        level: GameLevel.easy,
        score: 120,
        words: 7,
        elapsedSeconds: 70,
        completedAt: now,
      ),
    ];

    final ranking = RankingStore.bestEntries(entries);

    expect(
      ranking.map((entry) => entry.initials),
      orderedEquals(<String>['DDD', 'CCC', 'BBB', 'AAA']),
    );
  });
}
