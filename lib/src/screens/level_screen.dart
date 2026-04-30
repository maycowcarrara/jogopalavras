import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:jogopalavras/src/game/campaign_progress_store.dart';
import 'package:jogopalavras/src/game/game_level.dart';
import 'package:jogopalavras/src/game/ranking_store.dart';
import 'package:jogopalavras/src/game/word_bank.dart';
import 'package:jogopalavras/src/game/word_progress_store.dart';
import 'package:jogopalavras/src/navigation/app_page_route.dart';
import 'package:jogopalavras/src/navigation/app_route_observer.dart';
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

class _LevelScreenState extends State<LevelScreen> with RouteAware {
  static const _autoScrollAlignment = 0.08;
  static const _autoScrollStageAlignment = 0.42;
  static const _exitConfirmationWindow = Duration(seconds: 5);

  late Future<_CampaignSnapshot> _progressFuture = _loadCampaignSnapshot();
  final ScrollController _scrollController = ScrollController();
  final Map<GameLevel, GlobalKey> _chapterKeys = {
    GameLevel.easy: GlobalKey(),
    GameLevel.medium: GlobalKey(),
    GameLevel.hard: GlobalKey(),
  };
  final Map<String, GlobalKey> _subStageKeys = {};
  String? _lastAutoScrollTarget;
  bool _waitingForExitConfirmation = false;
  Timer? _exitConfirmationTimer;
  PageRoute<dynamic>? _route;

  void _refreshProgress() {
    if (!mounted) {
      return;
    }

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

    final rankingPositions = await _loadRankingPositions(
      progress: progress,
      usedWordCounts: usedWordCounts,
    );

    return _CampaignSnapshot(
      progress: progress,
      usedWordCounts: usedWordCounts,
      rankingPositions: rankingPositions,
    );
  }

  Future<Map<String, int>> _loadRankingPositions({
    required CampaignProgress progress,
    required Map<GameLevel, int> usedWordCounts,
  }) async {
    final cachedPositions = await RankingStore.instance
        .syncCachedStagePositions();
    if (cachedPositions.isEmpty) {
      return const <String, int>{};
    }
    final positions = <String, int>{};
    final snapshot = _CampaignSnapshot(
      progress: progress,
      usedWordCounts: usedWordCounts,
    );
    final freePlayPosition =
        cachedPositions[_subStageKey(GameLevel.pautaLivre, 0)];
    if (freePlayPosition != null) {
      positions[_subStageKey(GameLevel.pautaLivre, 0)] = freePlayPosition;
    }

    for (final level in const [
      GameLevel.easy,
      GameLevel.medium,
      GameLevel.hard,
    ]) {
      final completedStages = snapshot.completedSubStagesFor(level);
      if (completedStages == 0) {
        continue;
      }

      for (var stageNumber = 1; stageNumber <= completedStages; stageNumber++) {
        final position = cachedPositions[_subStageKey(level, stageNumber)];
        if (position != null) {
          positions[_subStageKey(level, stageNumber)] = position;
        }
      }
    }

    return positions;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _route) {
      if (_route != null) {
        appRouteObserver.unsubscribe(this);
      }
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _refreshProgress();
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _exitConfirmationTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleAutoScroll(_CampaignSnapshot campaign) {
    final targetLevel = campaign.currentLevel;
    final targetStage = campaign.currentSubStageFor(targetLevel);
    if (targetLevel == GameLevel.easy && targetStage <= 3) {
      return;
    }

    final signature =
        '${targetLevel.name}:${campaign.completedSubStagesFor(targetLevel)}';
    if (_lastAutoScrollTarget == signature) {
      return;
    }

    _lastAutoScrollTarget = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final stageContext =
          _subStageKeys[_subStageKey(targetLevel, targetStage)]?.currentContext;
      final chapterContext = _chapterKeys[targetLevel]?.currentContext;
      final targetContext = stageContext ?? chapterContext;
      if (targetContext == null) {
        return;
      }

      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        alignment: stageContext == null
            ? _autoScrollAlignment
            : _autoScrollStageAlignment,
      );
    });
  }

  GlobalKey _subStageKeyFor(GameLevel level, int stageNumber) {
    return _subStageKeys.putIfAbsent(
      _subStageKey(level, stageNumber),
      GlobalKey.new,
    );
  }

  Future<void> _openNextObjective(_CampaignSnapshot campaign) async {
    if (campaign.completedGame) {
      return;
    }

    final level = campaign.currentLevel;
    await Navigator.of(context).push(
      appPageRoute<void>(
        settings: RouteSettings(name: '/game/${level.name}'),
        builder: (_) => GameScreen(
          level: level,
          stageNumber: campaign.currentSubStageFor(level),
        ),
      ),
    );
    _refreshProgress();
  }

  void _handleBackPressed() {
    if (_waitingForExitConfirmation) {
      SystemNavigator.pop();
      return;
    }

    _waitingForExitConfirmation = true;
    _exitConfirmationTimer?.cancel();
    _exitConfirmationTimer = Timer(_exitConfirmationWindow, () {
      _waitingForExitConfirmation = false;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Pressione voltar novamente para sair'),
          duration: _exitConfirmationWindow,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CampaignSnapshot>(
      future: _progressFuture,
      builder: (context, snapshot) {
        final campaign = snapshot.data ?? _CampaignSnapshot.empty();
        if (snapshot.hasData) {
          _scheduleAutoScroll(campaign);
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            _handleBackPressed();
          },
          child: Scaffold(
            bottomNavigationBar: const AdBannerSlot(
              adSize: AdSize.largeBanner,
              safeAreaMinimum: EdgeInsets.fromLTRB(18, 0, 18, 10),
            ),
            body: AppBackdrop(
              primary: AppTheme.pressBlue,
              secondary: AppTheme.pressRed,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                      child: Column(
                        children: [
                          const _MapHeader(),
                          const SizedBox(height: 12),
                          _NextObjectiveBanner(
                            campaign: campaign,
                            onTap: () => _openNextObjective(campaign),
                          ),
                          const SizedBox(height: 10),
                          _FreePlayDock(
                            rankingPosition: campaign.rankingPositionFor(
                              GameLevel.pautaLivre,
                              0,
                            ),
                            onProgressChanged: _refreshProgress,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        children: [
                          _CampaignPath(
                            campaign: campaign,
                            chapterKeys: _chapterKeys,
                            subStageKeyFor: _subStageKeyFor,
                            onProgressChanged: _refreshProgress,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mapa da edição',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.midnight,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              fontSize: 26,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Avance pelas partidas de cada editoria até entregar o jornal.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.ink.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
              height: 1.16,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextObjectiveBanner extends StatelessWidget {
  const _NextObjectiveBanner({required this.campaign, required this.onTap});

  final _CampaignSnapshot campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final level = campaign.currentLevel;
    final accent = _chapterAccent(level);
    final current = campaign.currentSubStageFor(level);
    final total = campaign.subStageCountFor(level);
    final remainingWords = campaign.remainingWordsFor(level);
    final title = campaign.completedGame
        ? 'Edição entregue'
        : '${_nextObjectivePrefix(level)} $current/$total';
    final subtitle = campaign.completedGame
        ? 'Você concluiu todas as fases da campanha.'
        : _nextObjectiveSubtitle(level, remainingWords);

    final enabled = !campaign.completedGame;

    return Material(
      key: const ValueKey<String>('next_objective_banner'),
      color: AppTheme.midnight,
      borderRadius: BorderRadius.circular(8),
      elevation: 7,
      shadowColor: AppTheme.midnight.withValues(alpha: 0.18),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  campaign.completedGame
                      ? Icons.local_shipping_rounded
                      : Icons.flag_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ProgressBadge(
                          label: '${campaign.totalPercent}%',
                          color: accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampaignPath extends StatelessWidget {
  const _CampaignPath({
    required this.campaign,
    required this.chapterKeys,
    required this.subStageKeyFor,
    required this.onProgressChanged,
  });

  final _CampaignSnapshot campaign;
  final Map<GameLevel, GlobalKey> chapterKeys;
  final GlobalKey Function(GameLevel level, int stageNumber) subStageKeyFor;
  final VoidCallback onProgressChanged;

  @override
  Widget build(BuildContext context) {
    const levels = [GameLevel.easy, GameLevel.medium, GameLevel.hard];

    return Column(
      children: [
        for (var index = 0; index < levels.length; index++) ...[
          _EditorialChapterMarker(
            level: levels[index],
            rangeLabel: campaign.stageRangeLabel(levels[index]),
            unlocked: campaign.progress.isUnlocked(levels[index]),
            completed: campaign.progress.isCompleted(levels[index]),
          ),
          const SizedBox(height: 8),
          RevealOnMount(
            delay: Duration(milliseconds: 90 + (index * 70)),
            child: _LevelChapter(
              key: chapterKeys[levels[index]],
              level: levels[index],
              campaign: campaign,
              subStageKeyFor: subStageKeyFor,
              onProgressChanged: onProgressChanged,
            ),
          ),
          _ChapterConnector(
            completed: campaign.progress.isCompleted(levels[index]),
          ),
        ],
        RevealOnMount(
          delay: const Duration(milliseconds: 330),
          child: _DeliveryChapter(completed: campaign.completedGame),
        ),
      ],
    );
  }
}

class _EditorialChapterMarker extends StatelessWidget {
  const _EditorialChapterMarker({
    required this.level,
    required this.rangeLabel,
    required this.unlocked,
    required this.completed,
  });

  final GameLevel level;
  final String rangeLabel;
  final bool unlocked;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final accent = unlocked ? _chapterAccent(level) : AppTheme.rule;

    return Row(
      children: [
        Expanded(
          child: Divider(
            color: accent.withValues(alpha: unlocked ? 0.62 : 0.42),
            thickness: 1,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.card.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accent.withValues(alpha: 0.38)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                completed
                    ? Icons.task_alt_rounded
                    : unlocked
                    ? Icons.newspaper_rounded
                    : Icons.lock_rounded,
                color: accent,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                '${_editionLabel(level)} • $rangeLabel',
                style: TextStyle(
                  color: AppTheme.ink.withValues(alpha: unlocked ? 0.82 : 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(
            color: accent.withValues(alpha: unlocked ? 0.62 : 0.42),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

class _LevelChapter extends StatelessWidget {
  const _LevelChapter({
    super.key,
    required this.level,
    required this.campaign,
    required this.subStageKeyFor,
    required this.onProgressChanged,
  });

  final GameLevel level;
  final _CampaignSnapshot campaign;
  final GlobalKey Function(GameLevel level, int stageNumber) subStageKeyFor;
  final VoidCallback onProgressChanged;

  @override
  Widget build(BuildContext context) {
    final stageCount = campaign.subStageCountFor(level);
    final completedStages = campaign.completedSubStagesFor(level);
    final currentStage = math.min(completedStages + 1, stageCount);
    final unlocked = campaign.progress.isUnlocked(level);
    final completed = campaign.progress.isCompleted(level);
    final percent = campaign.percentFor(level);
    final accent = unlocked ? _chapterAccent(level) : AppTheme.rule;

    if (!unlocked) {
      return _CollapsedLevelChapter(level: level, accent: accent);
    }

    return Material(
      color: AppTheme.card.withValues(alpha: unlocked ? 0.98 : 0.76),
      borderRadius: BorderRadius.circular(8),
      elevation: unlocked ? 6 : 1,
      shadowColor: AppTheme.midnight.withValues(alpha: 0.12),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: completed
                ? accent.withValues(alpha: 0.72)
                : AppTheme.rule.withValues(alpha: 0.9),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChapterSeal(
                    index: _chapterIndex(level),
                    color: accent,
                    icon: completed
                        ? Icons.done_rounded
                        : unlocked
                        ? level.icon
                        : Icons.lock_rounded,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign.stageRangeLabel(level),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.ink.withValues(alpha: 0.58),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _chapterTitle(level),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unlocked
                                ? AppTheme.ink
                                : AppTheme.ink.withValues(alpha: 0.52),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          unlocked
                              ? _chapterPreview(level, stageCount)
                              : _lockedPreview(level),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.ink.withValues(
                              alpha: unlocked ? 0.72 : 0.5,
                            ),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ProgressBadge(
                    label: completed
                        ? '100%'
                        : unlocked
                        ? '$percent%'
                        : 'LOCK',
                    color: accent,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SubStageTrail(
                stageCount: stageCount,
                completedStages: completedStages,
                currentStage: currentStage,
                unlocked: unlocked,
                completed: completed,
                accent: accent,
                itemLabel: _subStageLabel(level),
                rankingPositionForStage: (stageNumber) =>
                    campaign.rankingPositionFor(level, stageNumber),
                keyForStage: (stageNumber) =>
                    subStageKeyFor(level, stageNumber),
                onSubStageTap: (stageNumber) =>
                    _handleSubStageTap(context, stageNumber),
              ),
              if (completed) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: _PublishedStamp(label: 'PUBLICADO', color: accent),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: ValueKey<String>('stage_${level.name}'),
                  onPressed: unlocked
                      ? completed
                            ? () => _startLevel(
                                context,
                                stageNumber: 1,
                                replayStage: true,
                              )
                            : () => _startLevel(context)
                      : null,
                  icon: Icon(
                    completed ? Icons.replay_rounded : Icons.play_arrow_rounded,
                    size: 20,
                  ),
                  label: Text(
                    completed
                        ? 'Revisitar ${_chapterTitle(level)}'
                        : unlocked
                        ? 'Jogar ${_subStageLabel(level).toLowerCase()} $currentStage de $stageCount'
                        : 'Bloqueado',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubStageTap(BuildContext context, int stageNumber) async {
    final completedStages = campaign.completedSubStagesFor(level);
    final currentStage = campaign.currentSubStageFor(level);
    final played =
        campaign.progress.isCompleted(level) || stageNumber <= completedStages;

    if (!played && stageNumber == currentStage) {
      await _startLevel(context);
      return;
    }

    final action = await showModalBottomSheet<_SubStageAction>(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (_) => _SubStageActionSheet(
        level: level,
        stageNumber: stageNumber,
        itemLabel: _subStageLabel(level),
        accent: _chapterAccent(level),
      ),
    );

    if (action == null || !context.mounted) {
      return;
    }

    switch (action) {
      case _SubStageAction.play:
        await _startLevel(context, stageNumber: stageNumber, replayStage: true);
      case _SubStageAction.ranking:
        await Navigator.of(context).push(
          appPageRoute<void>(
            settings: RouteSettings(
              name: '/ranking/${level.name}/$stageNumber',
            ),
            builder: (_) => RankingScreen(
              initialLevel: level,
              initialStageNumber: stageNumber,
            ),
          ),
        );
        onProgressChanged();
    }
  }

  Future<void> _startLevel(
    BuildContext context, {
    int? stageNumber,
    bool replayStage = false,
  }) async {
    await Navigator.of(context).push(
      appPageRoute<void>(
        settings: RouteSettings(name: '/game/${level.name}'),
        builder: (_) => GameScreen(
          level: level,
          stageNumber: stageNumber,
          replayStage: replayStage,
        ),
      ),
    );
    onProgressChanged();
  }
}

class _CollapsedLevelChapter extends StatelessWidget {
  const _CollapsedLevelChapter({required this.level, required this.accent});

  final GameLevel level;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.card.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(8),
      elevation: 1,
      shadowColor: AppTheme.midnight.withValues(alpha: 0.08),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.rule.withValues(alpha: 0.82)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              _ChapterSeal(
                index: _chapterIndex(level),
                color: accent,
                icon: Icons.lock_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _chapterTitle(level),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.ink.withValues(alpha: 0.5),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _ProgressBadge(label: 'LOCK', color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SubStageAction { play, ranking }

class _SubStageActionSheet extends StatelessWidget {
  const _SubStageActionSheet({
    required this.level,
    required this.stageNumber,
    required this.itemLabel,
    required this.accent,
  });

  final GameLevel level;
  final int stageNumber;
  final String itemLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$itemLabel $stageNumber',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.midnight,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _chapterTitle(level),
                        style: TextStyle(
                          color: AppTheme.ink.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pop(_SubStageAction.play),
                icon: const Icon(Icons.replay_rounded, size: 20),
                label: const Text('Jogar de novo'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pop(_SubStageAction.ranking),
                icon: const Icon(Icons.leaderboard_rounded, size: 20),
                label: const Text('Ver ranking da fase'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubStageTrail extends StatelessWidget {
  const _SubStageTrail({
    required this.stageCount,
    required this.completedStages,
    required this.currentStage,
    required this.unlocked,
    required this.completed,
    required this.accent,
    required this.itemLabel,
    required this.rankingPositionForStage,
    required this.keyForStage,
    required this.onSubStageTap,
  });

  final int stageCount;
  final int completedStages;
  final int currentStage;
  final bool unlocked;
  final bool completed;
  final Color accent;
  final String itemLabel;
  final int? Function(int stageNumber) rankingPositionForStage;
  final GlobalKey Function(int stageNumber) keyForStage;
  final ValueChanged<int> onSubStageTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final reduceMotion =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        const rowHeight = 78.0;
        final height = math.max(72.0, ((stageCount - 1) * rowHeight) + 72);
        final centers = _trailCenters(width: width, stageCount: stageCount);

        return _OffsetPressAnimation(
          reduceMotion: reduceMotion,
          builder: (context, paperPhase) {
            return SizedBox(
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _NewspaperTrailBackgroundPainter(accent: accent),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SubStagePathPainter(
                        centers: centers,
                        completedStages: completed
                            ? stageCount
                            : completedStages,
                        color: accent,
                        paperPhase: paperPhase,
                      ),
                    ),
                  ),
                  for (var number = 1; number <= stageCount; number++)
                    _positionedSubStageDot(number, centers[number - 1]),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _positionedSubStageDot(int number, Offset center) {
    final isCurrent = unlocked && !completed && number == currentStage;
    final isCompleted = completed || number <= completedStages;
    final isLocked = !unlocked || (!completed && number > currentStage);
    final width = isCurrent ? 170.0 : 156.0;
    final height = isCurrent ? 58.0 : 52.0;
    final labelSide = number.isOdd
        ? _SubStageLabelSide.left
        : _SubStageLabelSide.right;

    return Positioned(
      left: center.dx - (width / 2),
      top: center.dy - (height / 2),
      width: width,
      height: height,
      child: _SubStageDot(
        key: keyForStage(number),
        number: number,
        itemLabel: itemLabel,
        completed: isCompleted,
        current: isCurrent,
        locked: isLocked,
        hasRanking: isCompleted,
        rankingPosition: isCompleted ? rankingPositionForStage(number) : null,
        color: accent,
        labelSide: labelSide,
        onTap: !isLocked ? () => onSubStageTap(number) : null,
      ),
    );
  }
}

List<Offset> _trailCenters({required double width, required int stageCount}) {
  const top = 36.0;
  const rowHeight = 78.0;
  final left = math.min(math.max(88.0, width * 0.3), width / 2);
  final right = math.max(left, width - left);

  return [
    for (var index = 0; index < stageCount; index++)
      Offset(index.isEven ? left : right, top + (index * rowHeight)),
  ];
}

class _OffsetPressAnimation extends StatefulWidget {
  const _OffsetPressAnimation({
    required this.reduceMotion,
    required this.builder,
  });

  final bool reduceMotion;
  final Widget Function(BuildContext context, double paperPhase) builder;

  @override
  State<_OffsetPressAnimation> createState() => _OffsetPressAnimationState();
}

class _OffsetPressAnimationState extends State<_OffsetPressAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _OffsetPressAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reduceMotion != widget.reduceMotion) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.reduceMotion) {
      _controller
        ..stop()
        ..value = 0;
      return;
    }

    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion) {
      return widget.builder(context, 0);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => widget.builder(context, _controller.value),
    );
  }
}

class _SubStagePathPainter extends CustomPainter {
  const _SubStagePathPainter({
    required this.centers,
    required this.completedStages,
    required this.color,
    required this.paperPhase,
  });

  final List<Offset> centers;
  final int completedStages;
  final Color color;
  final double paperPhase;

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) {
      return;
    }

    for (var index = 1; index < centers.length; index++) {
      final previous = centers[index - 1];
      final current = centers[index];
      final path = _segmentPath(previous, current);
      final active = index <= completedStages;
      _drawPaperPath(canvas, path, active: active);
    }
  }

  Path _segmentPath(Offset previous, Offset current) {
    return Path()
      ..moveTo(previous.dx, previous.dy)
      ..lineTo(current.dx, current.dy);
  }

  void _drawPaperPath(Canvas canvas, Path path, {required bool active}) {
    final paperColor = AppTheme.card.withValues(alpha: active ? 0.9 : 0.6);
    final edgeColor = active
        ? color.withValues(alpha: 0.2)
        : AppTheme.rule.withValues(alpha: 0.2);

    final shadowPaint = Paint()
      ..color = AppTheme.midnight.withValues(alpha: active ? 0.06 : 0.03)
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;
    final edgePaint = Paint()
      ..color = edgeColor
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;
    final paperPaint = Paint()
      ..color = paperColor
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;
    final centerFoldPaint = Paint()
      ..color = Colors.white.withValues(alpha: active ? 0.42 : 0.2)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;

    canvas
      ..drawPath(path, shadowPaint)
      ..drawPath(path, edgePaint)
      ..drawPath(path, paperPaint)
      ..drawPath(path, centerFoldPaint);

    _drawPrintedWeb(canvas, path, active: active);
  }

  void _drawPrintedWeb(Canvas canvas, Path path, {required bool active}) {
    const spacing = 34.0;
    const blockLength = 28.0;

    for (final metric in path.computeMetrics()) {
      final clipPath = _paperBandClip(metric, halfWidth: 7.4);
      canvas
        ..save()
        ..clipPath(clipPath);

      final start = (paperPhase * spacing).remainder(spacing) - spacing;
      for (
        var distance = start;
        distance < metric.length;
        distance += spacing
      ) {
        final blockStart = distance;
        final blockEnd = distance + blockLength;
        if (blockEnd <= 5 || blockStart >= metric.length - 5) {
          continue;
        }

        final tangent = metric.getTangentForOffset(
          (blockStart + (blockLength / 2)).clamp(0, metric.length),
        );
        if (tangent == null) {
          continue;
        }

        final center = tangent.position;
        _drawMiniNewspaperBlock(
          canvas,
          center: center,
          active: active,
          variant: (distance / spacing).floor(),
        );
      }

      canvas.restore();
    }
  }

  Path _paperBandClip(PathMetric metric, {required double halfWidth}) {
    final startTangent = metric.getTangentForOffset(0);
    final endTangent = metric.getTangentForOffset(metric.length);
    if (startTangent == null || endTangent == null) {
      return Path();
    }

    final normal = Offset(-startTangent.vector.dy, startTangent.vector.dx);
    return Path()
      ..moveTo(
        startTangent.position.dx + (normal.dx * halfWidth),
        startTangent.position.dy + (normal.dy * halfWidth),
      )
      ..lineTo(
        endTangent.position.dx + (normal.dx * halfWidth),
        endTangent.position.dy + (normal.dy * halfWidth),
      )
      ..lineTo(
        endTangent.position.dx - (normal.dx * halfWidth),
        endTangent.position.dy - (normal.dy * halfWidth),
      )
      ..lineTo(
        startTangent.position.dx - (normal.dx * halfWidth),
        startTangent.position.dy - (normal.dy * halfWidth),
      )
      ..close();
  }

  void _drawMiniNewspaperBlock(
    Canvas canvas, {
    required Offset center,
    required bool active,
    required int variant,
  }) {
    final inkAlpha = active ? 0.36 : 0.14;
    final sectionPaint = Paint()
      ..color = Colors.white.withValues(alpha: active ? 0.1 : 0.04)
      ..style = PaintingStyle.fill;
    final rulePaint = Paint()
      ..color = AppTheme.ink.withValues(alpha: inkAlpha)
      ..strokeWidth = active ? 1.05 : 0.75
      ..strokeCap = StrokeCap.round;
    final headlinePaint = Paint()
      ..color = AppTheme.ink.withValues(alpha: active ? 0.42 : 0.18)
      ..strokeWidth = active ? 1.8 : 1.1
      ..strokeCap = StrokeCap.round;

    canvas
      ..save()
      ..translate(center.dx, center.dy);

    final sectionPath = Path()
      ..moveTo(-22, -7.5)
      ..lineTo(20, -6.2)
      ..lineTo(22, 7.5)
      ..lineTo(-20, 6.2)
      ..close();
    canvas.drawPath(sectionPath, sectionPaint);

    final linePlan = variant.isEven
        ? const <(double, double, double, bool)>[
            (-18.0, 17.5, -6.0, true),
            (-16.5, 9.0, -3.8, false),
            (-18.0, 15.5, -1.7, false),
            (-12.5, 18.0, 0.4, false),
            (-18.0, 11.0, 2.6, false),
            (-15.0, 17.0, 4.7, false),
            (-18.0, 6.5, 6.8, false),
          ]
        : const <(double, double, double, bool)>[
            (-16.0, 18.0, -6.2, true),
            (-18.0, 12.5, -4.0, false),
            (-14.0, 18.0, -1.8, false),
            (-18.0, 16.0, 0.3, false),
            (-10.5, 18.0, 2.5, false),
            (-18.0, 8.0, 4.8, false),
            (-13.0, 15.5, 6.9, false),
          ];

    for (final (startX, endX, y, headline) in linePlan) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(endX, y),
        headline ? headlinePaint : rulePaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SubStagePathPainter oldDelegate) {
    return oldDelegate.centers != centers ||
        oldDelegate.completedStages != completedStages ||
        oldDelegate.color != color ||
        oldDelegate.paperPhase != paperPhase;
  }
}

class _NewspaperTrailBackgroundPainter extends CustomPainter {
  const _NewspaperTrailBackgroundPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rulePaint = Paint()
      ..color = AppTheme.midnight.withValues(alpha: 0.026)
      ..strokeWidth = 1;
    final accentPaint = Paint()
      ..color = accent.withValues(alpha: 0.06)
      ..strokeWidth = 1.4;

    for (var y = 22.0; y < size.height; y += 39) {
      canvas.drawLine(Offset(4, y), Offset(size.width - 4, y), rulePaint);
    }

    for (var y = 58.0; y < size.height; y += 156) {
      canvas.drawLine(Offset(18, y), Offset(size.width * 0.32, y), accentPaint);
      canvas.drawLine(
        Offset(size.width * 0.68, y + 78),
        Offset(size.width - 18, y + 78),
        accentPaint,
      );
    }

    final guidePaint = Paint()
      ..color = AppTheme.rule.withValues(alpha: 0.18)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var y = 72.0; y < size.height; y += 78) {
      canvas.drawLine(
        Offset(size.width * 0.28, y),
        Offset(size.width * 0.72, y),
        guidePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NewspaperTrailBackgroundPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

enum _SubStageLabelSide { left, right }

class _SubStageDot extends StatelessWidget {
  const _SubStageDot({
    super.key,
    required this.number,
    required this.itemLabel,
    required this.completed,
    required this.current,
    required this.locked,
    required this.hasRanking,
    required this.rankingPosition,
    required this.color,
    required this.labelSide,
    required this.onTap,
  });

  final int number;
  final String itemLabel;
  final bool completed;
  final bool current;
  final bool locked;
  final bool hasRanking;
  final int? rankingPosition;
  final Color color;
  final _SubStageLabelSide labelSide;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final background = completed
        ? color.withValues(alpha: 0.96)
        : current
        ? AppTheme.card
        : AppTheme.card.withValues(alpha: locked ? 0.72 : 0.94);
    final foreground = completed
        ? Colors.white
        : locked
        ? AppTheme.ink.withValues(alpha: 0.34)
        : color;
    final secondaryForeground = completed
        ? Colors.white.withValues(alpha: 0.82)
        : AppTheme.ink.withValues(alpha: locked ? 0.42 : 0.64);
    final borderColor = current
        ? color
        : completed
        ? color.withValues(alpha: 0.9)
        : AppTheme.rule.withValues(alpha: 0.72);

    return Tooltip(
      message: '$itemLabel $number',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(9),
        elevation: current
            ? 6
            : completed
            ? 3
            : 1,
        shadowColor: AppTheme.midnight.withValues(alpha: 0.16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: current ? 10 : 9,
              vertical: current ? 8 : 7,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: borderColor,
                width: current ? 2.4 : 1.4,
              ),
            ),
            child: Row(
              children: [
                _StagePageNumber(
                  number: number,
                  color: completed || current ? color : AppTheme.rule,
                  foreground: foreground,
                  completed: completed,
                  current: current,
                  locked: locked,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryForeground,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        completed
                            ? 'Publicada'
                            : current
                            ? 'Agora'
                            : locked
                            ? 'Bloqueada'
                            : 'Aberta',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: completed ? Colors.white : foreground,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (completed)
                  rankingPosition == null
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : _StageRankingBadge(position: rankingPosition!),
                if (hasRanking && !completed)
                  Icon(Icons.leaderboard_rounded, color: foreground, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StageRankingBadge extends StatelessWidget {
  const _StageRankingBadge({required this.position});

  final int position;

  @override
  Widget build(BuildContext context) {
    final label = position > 99 ? '99+' : '$position';

    return Tooltip(
      message: 'Sua última posição conhecida: #$position',
      child: SizedBox(
        width: 30,
        height: 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              color: AppTheme.pressGold,
              size: 28,
              shadows: [
                Shadow(
                  color: AppTheme.midnight.withValues(alpha: 0.18),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: position <= 3 ? Colors.white : AppTheme.midnight,
                  fontSize: position > 99 ? 7.2 : 8.4,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StagePageNumber extends StatelessWidget {
  const _StagePageNumber({
    required this.number,
    required this.color,
    required this.foreground,
    required this.completed,
    required this.current,
    required this.locked,
  });

  final int number;
  final Color color;
  final Color foreground;
  final bool completed;
  final bool current;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final width = current ? 36.0 : 32.0;
    final height = current ? 40.0 : 36.0;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(width, height),
            painter: _StagePagePainter(
              color: color,
              completed: completed,
              current: current,
              locked: locked,
            ),
          ),
          Text(
            '$number',
            maxLines: 1,
            style: TextStyle(
              color: foreground,
              fontSize: number >= 100
                  ? 10
                  : current
                  ? 15
                  : 13,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _StagePagePainter extends CustomPainter {
  const _StagePagePainter({
    required this.color,
    required this.completed,
    required this.current,
    required this.locked,
  });

  final Color color;
  final bool completed;
  final bool current;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    final active = completed || current;
    final pageRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      const Radius.circular(5),
    );
    final foldPath = Path()
      ..moveTo(size.width - 11, 2)
      ..lineTo(size.width - 2, 11)
      ..lineTo(size.width - 11, 11)
      ..close();

    final shadowPaint = Paint()
      ..color = AppTheme.midnight.withValues(alpha: current ? 0.16 : 0.09)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4);
    final pagePaint = Paint()
      ..color = completed
          ? Colors.white.withValues(alpha: 0.16)
          : AppTheme.card.withValues(alpha: locked ? 0.72 : 0.98);
    final rimPaint = Paint()
      ..color = completed
          ? Colors.white.withValues(alpha: 0.42)
          : color.withValues(alpha: locked ? 0.26 : 0.66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = current ? 1.6 : 1.2;
    final foldPaint = Paint()
      ..color = color.withValues(alpha: active ? 0.24 : 0.12)
      ..style = PaintingStyle.fill;
    final rulePaint = Paint()
      ..color = completed
          ? Colors.white.withValues(alpha: 0.28)
          : AppTheme.ink.withValues(alpha: locked ? 0.12 : 0.2)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;

    canvas
      ..drawRRect(pageRect.shift(const Offset(0, 2)), shadowPaint)
      ..drawRRect(pageRect, pagePaint)
      ..drawPath(foldPath, foldPaint)
      ..drawRRect(pageRect, rimPaint);

    final left = size.width * 0.22;
    final right = size.width * 0.78;
    for (final y in <double>[
      size.height * 0.26,
      size.height * 0.72,
      size.height * 0.82,
    ]) {
      canvas.drawLine(Offset(left, y), Offset(right, y), rulePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StagePagePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.completed != completed ||
        oldDelegate.current != current ||
        oldDelegate.locked != locked;
  }
}

class _ChapterConnector extends StatelessWidget {
  const _ChapterConnector({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return _OffsetPressAnimation(
      reduceMotion: reduceMotion,
      builder: (context, paperPhase) {
        return SizedBox(
          height: 50,
          child: Center(
            child: CustomPaint(
              size: const Size(90, 50),
              painter: _ChapterConnectorPainter(
                completed: completed,
                paperPhase: paperPhase,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChapterConnectorPainter extends CustomPainter {
  const _ChapterConnectorPainter({
    required this.completed,
    required this.paperPhase,
  });

  final bool completed;
  final double paperPhase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final color = completed ? AppTheme.pressGreen : AppTheme.rule;
    final pulse = math.sin(paperPhase * math.pi * 2) * 1.3;
    _drawPageBundle(canvas, center + Offset(0, -4 + pulse), color);
    _drawTransferArrow(canvas, center + const Offset(0, 19), color);
  }

  void _drawPageBundle(Canvas canvas, Offset center, Color color) {
    final pagePaint = Paint()
      ..color = completed
          ? AppTheme.card.withValues(alpha: 0.92)
          : AppTheme.newsprint.withValues(alpha: 0.68)
      ..style = PaintingStyle.fill;
    final edgePaint = Paint()
      ..color = color.withValues(alpha: completed ? 0.36 : 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final rulePaint = Paint()
      ..color = AppTheme.ink.withValues(alpha: completed ? 0.18 : 0.08)
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = AppTheme.midnight.withValues(alpha: completed ? 0.1 : 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    for (var index = 0; index < 3; index++) {
      final offset = Offset(index * 2.5 - 2.5, index * -2.0);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center + offset, width: 40, height: 19),
        const Radius.circular(3),
      );
      if (index == 0) {
        canvas.drawRRect(rect.shift(const Offset(0, 2)), shadowPaint);
      }
      canvas
        ..drawRRect(rect, pagePaint)
        ..drawRRect(rect, edgePaint);
    }

    canvas
      ..drawLine(
        center + const Offset(-9, -4),
        center + const Offset(8, -4),
        rulePaint,
      )
      ..drawLine(
        center + const Offset(-8, 0),
        center + const Offset(10, 0),
        rulePaint,
      );
  }

  void _drawTransferArrow(Canvas canvas, Offset tip, Color color) {
    final arrowPaint = Paint()
      ..color = color.withValues(alpha: completed ? 0.58 : 0.28)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(tip.dx, tip.dy - 10)
      ..lineTo(tip.dx, tip.dy - 1)
      ..moveTo(tip.dx - 4, tip.dy - 5)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + 4, tip.dy - 5);
    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _ChapterConnectorPainter oldDelegate) {
    return oldDelegate.completed != completed ||
        oldDelegate.paperPhase != paperPhase;
  }
}

class _DeliveryChapter extends StatelessWidget {
  const _DeliveryChapter({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = completed ? AppTheme.pressGold : AppTheme.rule;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: completed ? 0.96 : 1, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.midnight.withValues(alpha: completed ? 1 : 0.72),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.7)),
          boxShadow: completed
              ? [
                  BoxShadow(
                    color: AppTheme.pressGold.withValues(alpha: 0.22),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            _ChapterSeal(
              index: 4,
              color: color,
              icon: completed
                  ? Icons.local_shipping_rounded
                  : Icons.lock_rounded,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    completed ? 'Final concluído' : 'Destino final',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Entrega',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    completed
                        ? 'Edição entregue. Campanha fechada.'
                        : 'Complete o Fechamento para entregar o jornal.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.74),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            if (completed) ...[
              const SizedBox(width: 10),
              _PublishedStamp(
                label: 'ENTREGUE',
                color: AppTheme.pressGold,
                dark: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PublishedStamp extends StatelessWidget {
  const _PublishedStamp({
    required this.label,
    required this.color,
    this.dark = false,
  });

  final String label;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.08,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.7), width: 1.4),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: dark ? Colors.white : color,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _FreePlayDock extends StatelessWidget {
  const _FreePlayDock({
    required this.rankingPosition,
    required this.onProgressChanged,
  });

  final int? rankingPosition;
  final VoidCallback onProgressChanged;

  Future<void> _openFreePlay(BuildContext context) async {
    await Navigator.of(context).push(
      appPageRoute<void>(
        settings: const RouteSettings(name: '/game/pautaLivre'),
        builder: (_) => const GameScreen(level: GameLevel.pautaLivre),
      ),
    );
    onProgressChanged();
  }

  Future<void> _openFreePlayRanking(BuildContext context) async {
    await Navigator.of(context).push(
      appPageRoute<void>(
        settings: const RouteSettings(name: '/ranking/pautaLivre'),
        builder: (_) => const RankingScreen(initialLevel: GameLevel.pautaLivre),
      ),
    );
    onProgressChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.card.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(8),
      elevation: 6,
      shadowColor: AppTheme.midnight.withValues(alpha: 0.24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 360;

          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: stacked
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPlayTarget(context),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildActions(context),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _buildPlayTarget(context)),
                      const SizedBox(width: 8),
                      _buildActions(context),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildPlayTarget(BuildContext context) {
    return InkWell(
      key: const ValueKey<String>('stage_pautaLivre'),
      borderRadius: BorderRadius.circular(8),
      onTap: () => _openFreePlay(context),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.pressGold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.dynamic_feed_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pauta Livre',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.midnight,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    height: 1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Plantão sempre aberto com todos os cadernos',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.08,
                  ),
                ),
              ],
            ),
          ),
          if (rankingPosition != null) ...[
            const SizedBox(width: 8),
            _StageRankingBadge(position: rankingPosition!),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Ranking do Plantão',
          child: Material(
            color: AppTheme.pressGold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              key: const ValueKey<String>('ranking_pautaLivre'),
              borderRadius: BorderRadius.circular(999),
              onTap: () => _openFreePlayRanking(context),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppTheme.pressGold.withValues(alpha: 0.34),
                  ),
                ),
                child: const Icon(
                  Icons.leaderboard_rounded,
                  color: AppTheme.pressGold,
                  size: 19,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: AppTheme.pressGold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => _openFreePlay(context),
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.pressGold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppTheme.pressGold.withValues(alpha: 0.34),
                ),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppTheme.pressGold,
                size: 19,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChapterSeal extends StatelessWidget {
  const _ChapterSeal({
    required this.index,
    required this.color,
    required this.icon,
  });

  final int index;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 4,
            right: 7,
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          Icon(icon, color: Colors.white, size: 22),
        ],
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _CampaignSnapshot {
  const _CampaignSnapshot({
    required this.progress,
    required this.usedWordCounts,
    this.rankingPositions = const <String, int>{},
  });

  factory _CampaignSnapshot.empty() {
    return const _CampaignSnapshot(
      progress: CampaignProgress(<GameLevel>{}),
      usedWordCounts: <GameLevel, int>{},
      rankingPositions: <String, int>{},
    );
  }

  final CampaignProgress progress;
  final Map<GameLevel, int> usedWordCounts;
  final Map<String, int> rankingPositions;

  bool get completedGame => progress.isCompleted(GameLevel.hard);

  GameLevel get currentLevel {
    if (!progress.isCompleted(GameLevel.easy)) {
      return GameLevel.easy;
    }
    if (!progress.isCompleted(GameLevel.medium)) {
      return GameLevel.medium;
    }
    return GameLevel.hard;
  }

  int get totalStageCount =>
      subStageCountFor(GameLevel.easy) +
      subStageCountFor(GameLevel.medium) +
      subStageCountFor(GameLevel.hard);

  int get completedStageCount =>
      completedSubStagesFor(GameLevel.easy) +
      completedSubStagesFor(GameLevel.medium) +
      completedSubStagesFor(GameLevel.hard);

  int get totalPercent {
    final total = totalStageCount;
    if (total == 0) {
      return 0;
    }

    return ((completedStageCount / total) * 100).floor();
  }

  int totalWordsFor(GameLevel level) => wordBank[level]?.length ?? 0;

  int subStageCountFor(GameLevel level) {
    final totalWords = totalWordsFor(level);
    if (totalWords == 0) {
      return 0;
    }

    return (totalWords / level.targetWordCount).ceil();
  }

  int completedSubStagesFor(GameLevel level) {
    final totalWords = totalWordsFor(level);
    final stageCount = subStageCountFor(level);
    if (totalWords == 0 || stageCount == 0) {
      return 0;
    }

    final usedWords = (usedWordCounts[level] ?? 0).clamp(0, totalWords).toInt();
    if (usedWords == 0) {
      return 0;
    }

    return math.min(stageCount, (usedWords / level.targetWordCount).ceil());
  }

  int currentSubStageFor(GameLevel level) {
    final total = subStageCountFor(level);
    if (total == 0) {
      return 0;
    }

    return math.min(completedSubStagesFor(level) + 1, total);
  }

  int? rankingPositionFor(GameLevel level, int stageNumber) {
    return rankingPositions[_subStageKey(level, stageNumber)];
  }

  int remainingWordsFor(GameLevel level) {
    final totalWords = totalWordsFor(level);
    final usedWords = (usedWordCounts[level] ?? 0).clamp(0, totalWords).toInt();
    return math.max(0, totalWords - usedWords);
  }

  String stageRangeLabel(GameLevel level) {
    final start = switch (level) {
      GameLevel.easy => 1,
      GameLevel.medium => subStageCountFor(GameLevel.easy) + 1,
      GameLevel.hard =>
        subStageCountFor(GameLevel.easy) +
            subStageCountFor(GameLevel.medium) +
            1,
      GameLevel.pautaLivre => 0,
    };
    if (level == GameLevel.pautaLivre) {
      return 'Plantão';
    }

    final end = start + subStageCountFor(level) - 1;
    return 'Fases $start-$end';
  }

  int percentFor(GameLevel level) {
    final totalWords = totalWordsFor(level);
    if (totalWords == 0) {
      return 0;
    }

    final usedWords = (usedWordCounts[level] ?? 0).clamp(0, totalWords).toInt();
    return ((usedWords / totalWords) * 100).floor();
  }
}

String _subStageKey(GameLevel level, int stageNumber) {
  return '${level.name}:$stageNumber';
}

String _chapterTitle(GameLevel level) => switch (level) {
  GameLevel.easy => 'Pauta',
  GameLevel.medium => 'Redação',
  GameLevel.hard => 'Fechamento',
  GameLevel.pautaLivre => 'Pauta Livre',
};

String _chapterPreview(GameLevel level, int stageCount) => switch (level) {
  GameLevel.easy => '$stageCount pautas curtas antes da Redação.',
  GameLevel.medium => '$stageCount matérias para chegar ao Fechamento.',
  GameLevel.hard => '$stageCount páginas finais antes da Entrega.',
  GameLevel.pautaLivre => 'Rodada solta com todos os cadernos.',
};

String _nextObjectivePrefix(GameLevel level) => switch (level) {
  GameLevel.easy => 'Próxima pauta',
  GameLevel.medium => 'Próxima matéria',
  GameLevel.hard => 'Próxima página',
  GameLevel.pautaLivre => 'Próxima rodada',
};

String _nextObjectiveSubtitle(GameLevel level, int remainingWords) {
  final target = switch (level) {
    GameLevel.easy => 'abrir Redação',
    GameLevel.medium => 'abrir Fechamento',
    GameLevel.hard => 'entregar a edição',
    GameLevel.pautaLivre => 'fechar o plantão',
  };

  return 'Faltam $remainingWords palavras para $target.';
}

String _editionLabel(GameLevel level) => switch (level) {
  GameLevel.easy => 'Edição 01 • Caderno de pauta',
  GameLevel.medium => 'Edição 02 • Mesa de redação',
  GameLevel.hard => 'Edição 03 • Fechamento',
  GameLevel.pautaLivre => 'Plantão',
};

String _subStageLabel(GameLevel level) => switch (level) {
  GameLevel.easy => 'Página',
  GameLevel.medium => 'Matéria',
  GameLevel.hard => 'Prova',
  GameLevel.pautaLivre => 'Rodada',
};

String _lockedPreview(GameLevel level) => switch (level) {
  GameLevel.easy => 'Primeira etapa da redação.',
  GameLevel.medium => 'Conclua todas as pautas para liberar.',
  GameLevel.hard => 'Conclua a Redação para liberar.',
  GameLevel.pautaLivre => 'Sempre disponível.',
};

int _chapterIndex(GameLevel level) => switch (level) {
  GameLevel.easy => 1,
  GameLevel.medium => 2,
  GameLevel.hard => 3,
  GameLevel.pautaLivre => 0,
};

Color _chapterAccent(GameLevel level) => switch (level) {
  GameLevel.easy => AppTheme.pressGreen,
  GameLevel.medium => AppTheme.pressBlue,
  GameLevel.hard => AppTheme.pressRed,
  GameLevel.pautaLivre => AppTheme.pressGold,
};
