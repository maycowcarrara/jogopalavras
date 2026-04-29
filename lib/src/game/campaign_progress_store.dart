import 'package:jogopalavras/src/game/game_level.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CampaignProgress {
  const CampaignProgress(this.completedLevels);

  final Set<GameLevel> completedLevels;

  bool isCompleted(GameLevel level) => completedLevels.contains(level);

  bool isUnlocked(GameLevel level) {
    return switch (level) {
      GameLevel.easy => true,
      GameLevel.medium => completedLevels.contains(GameLevel.easy),
      GameLevel.hard => completedLevels.contains(GameLevel.medium),
      GameLevel.pautaLivre => true,
    };
  }

  GameLevel? nextLevelAfter(GameLevel level) {
    return switch (level) {
      GameLevel.easy when isUnlocked(GameLevel.medium) => GameLevel.medium,
      GameLevel.medium when isUnlocked(GameLevel.hard) => GameLevel.hard,
      GameLevel.hard => null,
      GameLevel.pautaLivre => GameLevel.pautaLivre,
      _ => level,
    };
  }
}

class CampaignProgressStore {
  const CampaignProgressStore._();

  static const CampaignProgressStore instance = CampaignProgressStore._();
  static const String _completedLevelsKey = 'campaign_completed_levels_v1';

  Future<CampaignProgress> loadProgress() async {
    final preferences = await SharedPreferences.getInstance();
    final levelNames =
        preferences.getStringList(_completedLevelsKey) ?? <String>[];

    return CampaignProgress({
      for (final name in levelNames)
        for (final level in GameLevel.values)
          if (level.name == name) level,
    });
  }

  Future<CampaignProgress> completeLevel(GameLevel level) async {
    if (level == GameLevel.pautaLivre) {
      return loadProgress();
    }

    final preferences = await SharedPreferences.getInstance();
    final progress = await loadProgress();
    final completedLevels = {...progress.completedLevels, level};

    await preferences.setStringList(
      _completedLevelsKey,
      completedLevels.map((level) => level.name).toList()..sort(),
    );

    return CampaignProgress(completedLevels);
  }
}
