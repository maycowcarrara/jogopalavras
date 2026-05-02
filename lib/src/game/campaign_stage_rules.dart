import 'dart:math' as math;

import 'package:jogopalavras/src/game/game_level.dart';
import 'package:jogopalavras/src/game/word_bank.dart';

const Map<GameLevel, List<String>> _productionStepLabels = {
  GameLevel.easy: ['Pauta', 'Apuração'],
  GameLevel.medium: ['Redação', 'Edição', 'Revisão'],
  GameLevel.hard: ['Correção', 'Diagramação', 'Fechamento', 'Publicação'],
};

class CampaignProductionStep {
  const CampaignProductionStep({
    required this.label,
    required this.firstStage,
    required this.lastStage,
  });

  final String label;
  final int firstStage;
  final int lastStage;

  int get stageCount => lastStage - firstStage + 1;
}

int campaignStageCountForLevel(GameLevel level) {
  if (level.mixesAllLevels) {
    return 0;
  }

  final totalWords = wordBank[level]?.length ?? 0;
  if (totalWords == 0) {
    return 0;
  }

  if (totalWords <= level.targetWordCount) {
    return 1;
  }

  return math.max(1, (totalWords ~/ level.targetWordCount) - 1);
}

int campaignRequiredWordCountForLevel(GameLevel level) {
  final stageCount = campaignStageCountForLevel(level);
  if (stageCount == 0) {
    return 0;
  }

  final totalWords = wordBank[level]?.length ?? 0;
  return math.min(totalWords, stageCount * level.targetWordCount);
}

int campaignStageNumberForUsedWords({
  required GameLevel level,
  required int usedWords,
}) {
  final stageCount = campaignStageCountForLevel(level);
  if (stageCount == 0) {
    return 0;
  }

  final requiredWords = campaignRequiredWordCountForLevel(level);
  final clampedUsedWords = usedWords.clamp(0, requiredWords).toInt();
  if (clampedUsedWords >= requiredWords) {
    return stageCount;
  }

  final nextStage = (clampedUsedWords / level.targetWordCount).floor() + 1;
  return nextStage.clamp(1, stageCount).toInt();
}

int campaignTargetWordCountForStage({
  required GameLevel level,
  required int stageNumber,
}) {
  if (stageNumber <= 0 || level.mixesAllLevels) {
    return level.targetWordCount;
  }

  final requiredWords = campaignRequiredWordCountForLevel(level);
  if (requiredWords == 0) {
    return level.targetWordCount;
  }

  final wordsBeforeStage = (stageNumber - 1) * level.targetWordCount;
  final remainingWords = math.max(1, requiredWords - wordsBeforeStage);
  return math.min(level.targetWordCount, remainingWords);
}

List<WordEntry> campaignWordEntriesForStage({
  required GameLevel level,
  required int stageNumber,
}) {
  final entries = wordBank[level] ?? const <WordEntry>[];
  if (stageNumber <= 0 || level.mixesAllLevels || entries.isEmpty) {
    return entries;
  }

  final requiredWords = campaignRequiredWordCountForLevel(level);
  final start = (stageNumber - 1) * level.targetWordCount;
  if (start < 0 || start >= requiredWords) {
    return entries;
  }

  final end = math.min(start + level.targetWordCount, requiredWords);
  return entries.sublist(start, end);
}

List<WordEntry> campaignReserveWordEntriesForLevel(GameLevel level) {
  final entries = wordBank[level] ?? const <WordEntry>[];
  if (level.mixesAllLevels || entries.isEmpty) {
    return const <WordEntry>[];
  }

  final requiredWords = campaignRequiredWordCountForLevel(level);
  if (requiredWords < 0 || requiredWords >= entries.length) {
    return const <WordEntry>[];
  }

  return entries.sublist(requiredWords);
}

String campaignStageLabelForLevel(GameLevel level, int stageNumber) {
  if (level.mixesAllLevels || stageNumber <= 0) {
    return 'Rodada';
  }

  final labels = _productionStepLabels[level];
  if (labels == null || labels.isEmpty) {
    return 'Fase';
  }

  final stageCount = campaignStageCountForLevel(level);
  if (stageCount == 0) {
    return labels.first;
  }

  final stepSize = (stageCount / labels.length).ceil();
  final index = ((stageNumber - 1) ~/ stepSize)
      .clamp(0, labels.length - 1)
      .toInt();
  return labels[index];
}

List<CampaignProductionStep> campaignProductionStepsForLevel(GameLevel level) {
  if (level.mixesAllLevels) {
    return const <CampaignProductionStep>[];
  }

  final labels = _productionStepLabels[level];
  final stageCount = campaignStageCountForLevel(level);
  if (labels == null || labels.isEmpty || stageCount == 0) {
    return const <CampaignProductionStep>[];
  }

  final stepSize = (stageCount / labels.length).ceil();
  return [
    for (var index = 0; index < labels.length; index++)
      if ((index * stepSize) + 1 <= stageCount)
        CampaignProductionStep(
          label: labels[index],
          firstStage: (index * stepSize) + 1,
          lastStage: math.min((index + 1) * stepSize, stageCount),
        ),
  ];
}
