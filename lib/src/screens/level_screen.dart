import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:jogopalavras/src/game/campaign_progress_store.dart';
import 'package:jogopalavras/src/game/game_level.dart';
import 'package:jogopalavras/src/game/word_bank.dart';
import 'package:jogopalavras/src/game/word_progress_store.dart';
import 'package:jogopalavras/src/navigation/app_page_route.dart';
import 'package:jogopalavras/src/screens/game_screen.dart';
import 'package:jogopalavras/src/screens/ranking_screen.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';
import 'package:jogopalavras/src/widgets/ad_banner_slot.dart';
import 'package:jogopalavras/src/widgets/app_backdrop.dart';
import 'package:jogopalavras/src/widgets/reveal_on_mount.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  late Future<_CampaignSnapshot> _progressFuture = _loadCampaignSnapshot();

  void _refreshProgress() {
    setState(() {
      _progressFuture = _loadCampaignSnapshot();
    });
  }

  Future<_CampaignSnapshot> _loadCampaignSnapshot() async {
    final progress = await CampaignProgressStore.instance.loadProgress();
    final usedWordCounts = <GameLevel, int>{};
    for (final level in const [
      GameLevel.easy,
      GameLevel.medium,
      GameLevel.hard,
    ]) {
      usedWordCounts[level] = (await WordProgressStore.instance.loadUsedWords(
        level,
      )).length;
    }

    return _CampaignSnapshot(
      progress: progress,
      usedWordCounts: usedWordCounts,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CampaignSnapshot>(
      future: _progressFuture,
      builder: (context, snapshot) {
        final campaign = snapshot.data ?? _CampaignSnapshot.empty();

        return Scaffold(
          bottomNavigationBar: const AdBannerSlot(
            adSize: AdSize.largeBanner,
            safeAreaMinimum: EdgeInsets.fromLTRB(18, 0, 18, 10),
          ),
          body: AppBackdrop(
            primary: AppTheme.pressBlue,
            secondary: AppTheme.pressRed,
            topRightActions: const [_RankingActionButton()],
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const padding = EdgeInsets.fromLTRB(18, 4, 18, 18);
                  final shouldScroll = constraints.maxHeight < 720;

                  if (shouldScroll) {
                    return ListView(
                      padding: padding,
                      children: [
                        const _LevelHero(),
                        const SizedBox(height: 14),
                        _LevelList(
                          expanded: false,
                          campaign: campaign,
                          onProgressChanged: _refreshProgress,
                        ),
                      ],
                    );
                  }

                  return Padding(
                    padding: padding,
                    child: Column(
                      children: [
                        const _LevelHero(),
                        const SizedBox(height: 14),
                        Expanded(
                          child: _LevelList(
                            expanded: true,
                            campaign: campaign,
                            onProgressChanged: _refreshProgress,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LevelHero extends StatelessWidget {
  const _LevelHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RevealOnMount(
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        decoration: BoxDecoration(
          color: AppTheme.midnight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.midnight),
          boxShadow: [
            BoxShadow(
              color: AppTheme.midnight.withValues(alpha: 0.16),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha a editoria',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Avance pela edição: pauta, redação, fechamento e entrega.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.86),
                height: 1.18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            const _HeroSummary(
              icon: Icons.newspaper_rounded,
              label: 'Campanha editorial com Pauta Livre sempre disponível',
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingActionButton extends StatelessWidget {
  const _RankingActionButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ver ranking',
      child: Tooltip(
        message: 'Ranking',
        child: Material(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(8),
          elevation: 10,
          shadowColor: AppTheme.midnight.withValues(alpha: 0.28),
          child: InkWell(
            key: const ValueKey<String>('level_ranking_button'),
            onTap: () {
              Navigator.of(context).push(
                appPageRoute<void>(
                  settings: const RouteSettings(name: '/ranking'),
                  builder: (_) => const RankingScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: const SizedBox.square(
              dimension: 42,
              child: Icon(
                Icons.leaderboard_rounded,
                color: AppTheme.pressBlue,
                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelList extends StatelessWidget {
  const _LevelList({
    required this.expanded,
    required this.campaign,
    required this.onProgressChanged,
  });

  final bool expanded;
  final _CampaignSnapshot campaign;
  final VoidCallback onProgressChanged;

  @override
  Widget build(BuildContext context) {
    const campaignLevels = [GameLevel.easy, GameLevel.medium, GameLevel.hard];
    final campaignCards = [
      for (var index = 0; index < campaignLevels.length; index++)
        RevealOnMount(
          delay: Duration(milliseconds: 100 + (index * 70)),
          child: _LevelCard(
            level: campaignLevels[index],
            stageNumber: index + 1,
            prominent: expanded,
            unlocked: campaign.progress.isUnlocked(campaignLevels[index]),
            completed: campaign.progress.isCompleted(campaignLevels[index]),
            progressPercent: campaign.percentFor(campaignLevels[index]),
            onProgressChanged: onProgressChanged,
          ),
        ),
    ];
    final freeCard = RevealOnMount(
      delay: const Duration(milliseconds: 330),
      child: _LevelCard(
        level: GameLevel.pautaLivre,
        prominent: expanded,
        unlocked: true,
        completed: false,
        progressPercent: null,
        onProgressChanged: onProgressChanged,
      ),
    );

    if (!expanded) {
      return Column(
        children: [
          for (final card in campaignCards) ...[
            card,
            const SizedBox(height: 10),
          ],
          freeCard,
        ],
      );
    }

    return Column(
      children: [
        for (final card in campaignCards) ...[
          Expanded(child: card),
          const SizedBox(height: 10),
        ],
        Expanded(child: freeCard),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.unlocked,
    required this.completed,
    required this.progressPercent,
    required this.onProgressChanged,
    this.stageNumber,
    this.prominent = false,
  });

  final GameLevel level;
  final int? stageNumber;
  final bool unlocked;
  final bool completed;
  final int? progressPercent;
  final VoidCallback onProgressChanged;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = prominent ? 48.0 : 42.0;
    final accent = unlocked
        ? level.accent
        : AppTheme.ink.withValues(alpha: 0.32);

    return Material(
      color: AppTheme.card.withValues(alpha: unlocked ? 0.96 : 0.72),
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: completed
                ? level.accent.withValues(alpha: 0.72)
                : AppTheme.rule.withValues(alpha: 0.9),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.midnight.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: unlocked
              ? () async {
                  await Navigator.of(context).push(
                    appPageRoute<void>(
                      settings: RouteSettings(name: '/game/${level.name}'),
                      builder: (_) => GameScreen(level: level),
                    ),
                  );
                  onProgressChanged();
                }
              : null,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: prominent ? 16 : 14,
              vertical: prominent ? 16 : 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    completed
                        ? Icons.done_rounded
                        : unlocked
                        ? level.icon
                        : Icons.lock_rounded,
                    color: Colors.white,
                    size: prominent ? 24 : 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _stageTitle(level, stageNumber),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: unlocked
                                    ? AppTheme.ink
                                    : AppTheme.ink.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            completed
                                ? 'Concluído'
                                : unlocked
                                ? progressPercent == null
                                      ? level.wordSizeShortLabel
                                      : '$progressPercent%'
                                : 'Bloqueado',
                            style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _stageSubtitle(level, unlocked),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.ink.withValues(
                            alpha: unlocked ? 0.78 : 0.52,
                          ),
                          fontSize: 13,
                          height: 1.1,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 0,
                        runSpacing: 2,
                        children: [
                          Text(
                            _goalLabel(level),
                            style: TextStyle(
                              color: AppTheme.ink.withValues(alpha: 0.72),
                              fontSize: 12,
                              height: 1.12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: AppTheme.ink.withValues(alpha: 0.52),
                              fontSize: 12,
                              height: 1.12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _ctaLabel(level, unlocked, completed),
                            style: TextStyle(
                              color: AppTheme.ink.withValues(
                                alpha: unlocked ? 0.9 : 0.52,
                              ),
                              fontSize: 12,
                              height: 1.12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  unlocked ? Icons.arrow_forward_rounded : Icons.lock_rounded,
                  color: AppTheme.midnight.withValues(
                    alpha: unlocked ? 0.72 : 0.32,
                  ),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _stageTitle(GameLevel level, int? stageNumber) {
  final prefix = stageNumber == null ? 'Plantão' : 'Fase $stageNumber';
  final title = switch (level) {
    GameLevel.easy => 'Pauta',
    GameLevel.medium => 'Redação',
    GameLevel.hard => 'Fechamento',
    GameLevel.pautaLivre => 'Pauta Livre',
  };

  return '$prefix: $title';
}

String _stageSubtitle(GameLevel level, bool unlocked) {
  if (!unlocked) {
    return 'Conclua a etapa anterior para abrir este caderno.';
  }

  return switch (level) {
    GameLevel.easy => 'Comece por notas curtas e chamadas rápidas.',
    GameLevel.medium => 'Transforme a apuração em matéria principal.',
    GameLevel.hard => 'Feche a edição com palavras mais longas.',
    GameLevel.pautaLivre => 'Misture todas as editorias em uma rodada solta.',
  };
}

String _ctaLabel(GameLevel level, bool unlocked, bool completed) {
  if (!unlocked) {
    return 'Aguardando liberação';
  }

  if (completed && level != GameLevel.pautaLivre) {
    return 'Revisitar fase';
  }

  return switch (level) {
    GameLevel.easy => 'Começar no fácil',
    GameLevel.medium => 'Encara o médio',
    GameLevel.hard => 'Partir para o difícil',
    GameLevel.pautaLivre => 'Abrir pauta livre',
  };
}

String _goalLabel(GameLevel level) => switch (level) {
  GameLevel.easy => 'Ritmo de pauta',
  GameLevel.medium => 'Texto em produção',
  GameLevel.hard => 'Edição final',
  GameLevel.pautaLivre => 'Todos os níveis',
};

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignSnapshot {
  const _CampaignSnapshot({
    required this.progress,
    required this.usedWordCounts,
  });

  factory _CampaignSnapshot.empty() {
    return const _CampaignSnapshot(
      progress: CampaignProgress(<GameLevel>{}),
      usedWordCounts: <GameLevel, int>{},
    );
  }

  final CampaignProgress progress;
  final Map<GameLevel, int> usedWordCounts;

  int? percentFor(GameLevel level) {
    if (level == GameLevel.pautaLivre) {
      return null;
    }

    final totalWords = wordBank[level]?.length ?? 0;
    if (totalWords == 0) {
      return 0;
    }

    final usedWords = (usedWordCounts[level] ?? 0).clamp(0, totalWords);
    return ((usedWords / totalWords) * 100).floor();
  }
}
