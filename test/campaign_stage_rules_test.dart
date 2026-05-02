import 'package:flutter_test/flutter_test.dart';
import 'package:jogopalavras/src/game/campaign_stage_rules.dart';
import 'package:jogopalavras/src/game/game_level.dart';
import 'package:jogopalavras/src/game/word_bank.dart';

void main() {
  test('campanha mantém palavras de reserva para pulos', () {
    for (final level in const [
      GameLevel.easy,
      GameLevel.medium,
      GameLevel.hard,
    ]) {
      final totalWords = wordBank[level]!.length;
      final requiredWords = campaignRequiredWordCountForLevel(level);

      expect(requiredWords % level.targetWordCount, 0);
      expect(
        totalWords - requiredWords,
        greaterThanOrEqualTo(level.targetWordCount),
      );
      expect(
        campaignStageCountForLevel(level),
        requiredWords ~/ level.targetWordCount,
      );
    }
  });

  test('campanha usa quase todo o banco mantendo reserva', () {
    expect(campaignStageCountForLevel(GameLevel.easy), 19);
    expect(campaignStageCountForLevel(GameLevel.medium), 31);
    expect(campaignStageCountForLevel(GameLevel.hard), 44);
  });

  test('etapas grandes são quebradas em blocos de produção jornalística', () {
    expect(campaignStageLabelForLevel(GameLevel.easy, 10), 'Pauta');
    expect(campaignStageLabelForLevel(GameLevel.easy, 11), 'Apuração');
    expect(campaignStageLabelForLevel(GameLevel.medium, 1), 'Redação');
    expect(campaignStageLabelForLevel(GameLevel.medium, 12), 'Edição');
    expect(campaignStageLabelForLevel(GameLevel.medium, 23), 'Revisão');
    expect(campaignStageLabelForLevel(GameLevel.hard, 1), 'Correção');
    expect(campaignStageLabelForLevel(GameLevel.hard, 12), 'Diagramação');
    expect(campaignStageLabelForLevel(GameLevel.hard, 34), 'Publicação');
  });

  test('palavras consumidas só avançam fase ao completar o alvo', () {
    expect(
      campaignStageNumberForUsedWords(level: GameLevel.easy, usedWords: 0),
      1,
    );
    expect(
      campaignStageNumberForUsedWords(level: GameLevel.easy, usedWords: 1),
      1,
    );
    expect(
      campaignStageNumberForUsedWords(
        level: GameLevel.easy,
        usedWords: GameLevel.easy.targetWordCount,
      ),
      2,
    );
  });

  test('última fase usa alvo cheio e deixa o restante como reserva', () {
    final lastStage = campaignStageCountForLevel(GameLevel.easy);

    expect(
      campaignTargetWordCountForStage(
        level: GameLevel.easy,
        stageNumber: lastStage,
      ),
      GameLevel.easy.targetWordCount,
    );
    expect(
      campaignWordEntriesForStage(
        level: GameLevel.easy,
        stageNumber: lastStage,
      ),
      hasLength(GameLevel.easy.targetWordCount),
    );
  });

  test('palavras reserva ficam fora das fases regulares', () {
    for (final level in const [
      GameLevel.easy,
      GameLevel.medium,
      GameLevel.hard,
    ]) {
      final stageWords = {
        for (var stage = 1; stage <= campaignStageCountForLevel(level); stage++)
          ...campaignWordEntriesForStage(
            level: level,
            stageNumber: stage,
          ).map((entry) => entry.text),
      };
      final reserveWords = campaignReserveWordEntriesForLevel(
        level,
      ).map((entry) => entry.text).toSet();

      expect(stageWords.intersection(reserveWords), isEmpty);
      expect(reserveWords.length, greaterThanOrEqualTo(level.targetWordCount));
    }
  });
}
