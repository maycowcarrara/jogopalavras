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
      RankingStore.scoreForPerformance(
        level: GameLevel.easy,
        words: 10,
        elapsedSeconds: 71,
      ),
      greaterThan(
        RankingStore.scoreForPerformance(
          level: GameLevel.easy,
          words: 14,
          elapsedSeconds: 176,
        ),
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
      RankingStore.scoreForPerformance(
        level: GameLevel.easy,
        words: 14,
        elapsedSeconds: 176,
      ),
    );
  });

  test('usa pontuacao inicial por nivel', () {
    expect(
      RankingStore.startingScoreForLevel(GameLevel.easy),
      RankingStore.easyStartingScore,
    );
    expect(
      RankingStore.startingScoreForLevel(GameLevel.medium),
      RankingStore.mediumStartingScore,
    );
    expect(
      RankingStore.startingScoreForLevel(GameLevel.hard),
      RankingStore.hardStartingScore,
    );
    expect(
      RankingStore.startingScoreForLevel(GameLevel.pautaLivre),
      RankingStore.pautaLivreStartingScore,
    );

    expect(
      RankingStore.scoreForPerformance(
        level: GameLevel.hard,
        words: 0,
        elapsedSeconds: 0,
      ),
      RankingStore.hardStartingScore,
    );
  });

  test('recalcula pontuacao com penalidade de pulos', () {
    final scoreWithoutHint = RankingStore.scoreForPerformance(
      level: GameLevel.easy,
      words: 10,
      elapsedSeconds: 60,
    );
    final scoreWithHint = RankingStore.scoreForPerformance(
      level: GameLevel.easy,
      words: 10,
      elapsedSeconds: 60,
      hintsUsed: 1,
    );

    expect(scoreWithHint, scoreWithoutHint);

    final scoreWithSkip = RankingStore.scoreForPerformance(
      level: GameLevel.easy,
      words: 10,
      elapsedSeconds: 60,
      hintsUsed: 1,
      skipsUsed: 1,
    );

    expect(scoreWithSkip, scoreWithoutHint - RankingStore.pointsPerSkip);

    final entry = RankingEntry.fromJson(<String, Object?>{
      'initials': 'MRC',
      'level': 'easy',
      'score': 1000,
      'words': 10,
      'elapsedSeconds': 60,
      'hintsUsed': 1,
      'skipsUsed': 1,
      'completedAt': DateTime(2026, 4, 28).toIso8601String(),
    });

    expect(entry.skipsUsed, 1);
    expect(entry.score, scoreWithSkip);
  });

  test('lembra as ultimas iniciais usadas no ranking', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await RankingStore.instance.saveLastInitials('abcde');

    expect(await RankingStore.instance.loadLastInitials(), 'ABCDE');
  });

  test('permite numeros na assinatura do ranking', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final result = await RankingStore.instance.updatePlayerInitials(
      'a1b2c3',
      now: DateTime(2026, 4, 1),
    );

    expect(result.saved, isTrue);
    expect(result.initials, 'A1B2C3');
    expect(await RankingStore.instance.loadLastInitials(), 'A1B2C3');
  });

  test('salvar entrada atualiza iniciais lembradas', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await RankingStore.instance.saveEntry(
      RankingEntry(
        initials: 'MAYCO',
        level: GameLevel.easy,
        score: 150,
        words: 15,
        elapsedSeconds: 90,
        completedAt: DateTime(2026, 4, 28),
      ),
    );

    expect(await RankingStore.instance.loadLastInitials(), 'MAYCO');
  });

  test('ignora salvamento local repetido da mesma rodada', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final originalEntry = RankingEntry(
      initials: 'MAYCO',
      level: GameLevel.easy,
      score: 150,
      words: 10,
      elapsedSeconds: 90,
      completedAt: DateTime(2026, 4, 28, 12, 30),
    );
    final repeatedEntry = RankingEntry(
      initials: originalEntry.initials,
      level: originalEntry.level,
      score: originalEntry.score,
      words: originalEntry.words,
      elapsedSeconds: originalEntry.elapsedSeconds,
      completedAt: originalEntry.completedAt.add(const Duration(seconds: 5)),
    );

    await RankingStore.instance.saveEntry(originalEntry);
    await RankingStore.instance.saveEntry(repeatedEntry);

    final entries = await RankingStore.instance.loadEntries(
      level: GameLevel.easy,
    );

    expect(entries, hasLength(1));
    expect(entries.single.initials, 'MAYCO');
    expect(entries.single.completedAt, originalEntry.completedAt);
  });

  test('mantem rankings locais separados por fase', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final now = DateTime(2026, 4, 28);

    await RankingStore.instance.saveEntry(
      RankingEntry(
        initials: 'AAA',
        level: GameLevel.easy,
        stageNumber: 1,
        score: 150,
        words: 10,
        elapsedSeconds: 90,
        completedAt: now,
      ),
    );
    await RankingStore.instance.saveEntry(
      RankingEntry(
        initials: 'BBB',
        level: GameLevel.easy,
        stageNumber: 2,
        score: 150,
        words: 10,
        elapsedSeconds: 80,
        completedAt: now,
      ),
    );

    final firstStage = await RankingStore.instance.loadEntries(
      level: GameLevel.easy,
      stageNumber: 1,
    );
    final secondStage = await RankingStore.instance.loadEntries(
      level: GameLevel.easy,
      stageNumber: 2,
    );

    expect(firstStage.map((entry) => entry.initials), orderedEquals(['AAA']));
    expect(secondStage.map((entry) => entry.initials), orderedEquals(['BBB']));
  });

  test('mantem entradas locais mesmo fora do antigo top 10', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final now = DateTime(2026, 4, 28);

    for (var index = 0; index < 11; index++) {
      await RankingStore.instance.saveEntry(
        RankingEntry(
          initials: 'AA${String.fromCharCode(65 + index)}',
          level: GameLevel.easy,
          stageNumber: 1,
          score: 150,
          words: 10,
          elapsedSeconds: 80 + index,
          completedAt: now.add(Duration(seconds: index)),
        ),
      );
    }

    final entries = await RankingStore.instance.loadEntries(
      level: GameLevel.easy,
      stageNumber: 1,
    );

    expect(entries, hasLength(11));
    expect(entries.last.initials, 'AAK');
  });

  test('bloqueia troca de assinatura por trinta dias', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final first = await RankingStore.instance.updatePlayerInitials(
      'abc',
      now: DateTime(2026, 4, 1),
    );
    final second = await RankingStore.instance.updatePlayerInitials(
      'def',
      now: DateTime(2026, 4, 2),
    );

    expect(first.saved, isTrue);
    expect(second.status, InitialsUpdateStatus.cooldown);
    expect(await RankingStore.instance.loadLastInitials(), 'ABC');
  });

  test('bloqueia assinatura local ja usada no ranking', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await RankingStore.instance.saveEntry(
      RankingEntry(
        initials: 'JORN',
        level: GameLevel.easy,
        score: 150,
        words: 10,
        elapsedSeconds: 90,
        completedAt: DateTime(2026, 4, 28),
      ),
    );
    await RankingStore.instance.saveLastInitials('EDIT');

    final result = await RankingStore.instance.updatePlayerInitials(
      'jorn',
      now: DateTime(2026, 5, 30),
    );

    expect(result.status, InitialsUpdateStatus.unavailable);
    expect(await RankingStore.instance.loadLastInitials(), 'EDIT');
  });
}
