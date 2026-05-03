import 'package:jogopalavras/src/game/game_level.dart';
import 'package:jogopalavras/src/game/campaign_stage_rules.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WordProgressStore {
  const WordProgressStore._();

  static const WordProgressStore instance = WordProgressStore._();
  static const String _keyPrefix = 'word_progress_used_v1';
  static const String _completedStagesKeyPrefix =
      'campaign_completed_stages_v2';
  static const String _stageRepairKey = 'campaign_stage_repair_v2_20260502';

  Future<Set<String>> loadUsedWords(GameLevel level) async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_keyFor(level)) ?? <String>[]).toSet();
  }

  Future<Set<String>> markWordsUsed(
    GameLevel level,
    Iterable<String> words,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final usedWords = await loadUsedWords(level);
    usedWords.addAll(words.map((word) => word.toUpperCase()));

    await preferences.setStringList(_keyFor(level), usedWords.toList()..sort());
    return usedWords;
  }

  Future<int> loadCompletedStageCount(GameLevel level) async {
    if (level.mixesAllLevels) {
      return 0;
    }

    final preferences = await SharedPreferences.getInstance();
    final stageCount = campaignStageCountForLevel(level);
    final completedStages =
        preferences.getInt(_completedStagesKeyFor(level)) ?? 0;
    return completedStages.clamp(0, stageCount).toInt();
  }

  Future<int> markStageCompleted(GameLevel level, int stageNumber) async {
    if (level.mixesAllLevels || stageNumber <= 0) {
      return 0;
    }

    final preferences = await SharedPreferences.getInstance();
    final stageCount = campaignStageCountForLevel(level);
    final current = await loadCompletedStageCount(level);
    final next = stageNumber.clamp(current, stageCount).toInt();
    await preferences.setInt(_completedStagesKeyFor(level), next);
    return next;
  }

  Future<void> repairStageProgressCacheOnce() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_stageRepairKey) == true) {
      return;
    }

    for (final level in const [
      GameLevel.easy,
      GameLevel.medium,
      GameLevel.hard,
    ]) {
      final usedWords = await loadUsedWords(level);
      final completedByWords = usedWords.length ~/ level.targetWordCount;
      final stageCount = campaignStageCountForLevel(level);
      final repairedStageCount = completedByWords.clamp(0, stageCount).toInt();
      final currentStageCount = await loadCompletedStageCount(level);
      if (repairedStageCount > currentStageCount) {
        await preferences.setInt(
          _completedStagesKeyFor(level),
          repairedStageCount,
        );
      }
    }

    await preferences.setBool(_stageRepairKey, true);
  }

  Future<void> resetLevel(GameLevel level) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_keyFor(level));
    await preferences.remove(_completedStagesKeyFor(level));
  }

  String _keyFor(GameLevel level) => '$_keyPrefix:${level.name}';

  String _completedStagesKeyFor(GameLevel level) =>
      '$_completedStagesKeyPrefix:${level.name}';
}
