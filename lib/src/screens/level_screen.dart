import 'dart:math' as math;

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
  final ScrollController _scrollController = ScrollController();
  final Map<GameLevel, GlobalKey> _chapterKeys = {
    GameLevel.easy: GlobalKey(),
    GameLevel.medium: GlobalKey(),
    GameLevel.hard: GlobalKey(),
  };
  String? _lastAutoScrollTarget;

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleAutoScroll(_CampaignSnapshot campaign) {
    final targetLevel = campaign.currentLevel;
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

      final context = _chapterKeys[targetLevel]?.currentContext;
      if (context == null) {
        return;
      }

      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        alignment: 0.16,
      );
    });
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
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                children: [
                  const _MapHeader(),
                  const SizedBox(height: 12),
                  _NextObjectiveBanner(campaign: campaign),
                  const SizedBox(height: 16),
                  _CampaignPath(
                    campaign: campaign,
                    chapterKeys: _chapterKeys,
                    onProgressChanged: _refreshProgress,
                  ),
                ],
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
      padding: const EdgeInsets.only(right: 94),
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

class _NextObjectiveBanner extends StatelessWidget {
  const _NextObjectiveBanner({required this.campaign});

  final _CampaignSnapshot campaign;

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

    return Material(
      color: AppTheme.midnight,
      borderRadius: BorderRadius.circular(8),
      elevation: 7,
      shadowColor: AppTheme.midnight.withValues(alpha: 0.18),
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
                  Text(
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
            const SizedBox(width: 8),
            _ProgressBadge(label: '${campaign.totalPercent}%', color: accent),
          ],
        ),
      ),
    );
  }
}

class _CampaignPath extends StatelessWidget {
  const _CampaignPath({
    required this.campaign,
    required this.chapterKeys,
    required this.onProgressChanged,
  });

  final _CampaignSnapshot campaign;
  final Map<GameLevel, GlobalKey> chapterKeys;
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
        const SizedBox(height: 14),
        RevealOnMount(
          delay: const Duration(milliseconds: 400),
          child: _FreePlayDock(onProgressChanged: onProgressChanged),
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
    required this.onProgressChanged,
  });

  final GameLevel level;
  final _CampaignSnapshot campaign;
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
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
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
                    label: completed ? '100%' : unlocked ? '$percent%' : 'LOCK',
                    color: accent,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SubStageTrail(
                stageCount: stageCount,
                completedStages: completedStages,
                currentStage: currentStage,
                unlocked: unlocked,
                completed: completed,
                accent: accent,
                itemLabel: _subStageLabel(level),
                onStart: () => _startLevel(context),
              ),
              if (completed) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: _PublishedStamp(label: 'PUBLICADO', color: accent),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: ValueKey<String>('stage_${level.name}'),
                  onPressed: unlocked ? () => _startLevel(context) : null,
                  icon: Icon(
                    completed
                        ? Icons.replay_rounded
                        : Icons.play_arrow_rounded,
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

  Future<void> _startLevel(BuildContext context) async {
    await Navigator.of(context).push(
      appPageRoute<void>(
        settings: RouteSettings(name: '/game/${level.name}'),
        builder: (_) => GameScreen(level: level),
      ),
    );
    onProgressChanged();
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
    required this.onStart,
  });

  final int stageCount;
  final int completedStages;
  final int currentStage;
  final bool unlocked;
  final bool completed;
  final Color accent;
  final String itemLabel;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = math.max(5, math.min(9, (width / 40).floor())).toInt();
        final rows = (stageCount / columns).ceil();
        final height = math.max(42.0, ((rows - 1) * 45) + 42).toDouble();
        final centers = _trailCenters(
          width: width,
          stageCount: stageCount,
          columns: columns,
        );

        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _SubStagePathPainter(
                    centers: centers,
                    completedStages: completed ? stageCount : completedStages,
                    color: accent,
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
  }

  Widget _positionedSubStageDot(int number, Offset center) {
    final isCurrent = unlocked && !completed && number == currentStage;
    final size = isCurrent ? 38.0 : 32.0;

    return Positioned(
      left: center.dx - (size / 2),
      top: center.dy - (size / 2),
      width: size,
      height: size,
      child: _SubStageDot(
        number: number,
        itemLabel: itemLabel,
        completed: completed || number <= completedStages,
        current: isCurrent,
        locked: !unlocked || (!completed && number > currentStage),
        color: accent,
        onTap: unlocked && (completed || number <= currentStage)
            ? onStart
            : null,
      ),
    );
  }
}

List<Offset> _trailCenters({
  required double width,
  required int stageCount,
  required int columns,
}) {
  const top = 21.0;
  const rowHeight = 45.0;
  final left = 18.0;
  final right = math.max(left, width - 18);
  final step = columns <= 1 ? 0.0 : (right - left) / (columns - 1);

  return [
    for (var index = 0; index < stageCount; index++)
      () {
        final row = index ~/ columns;
        final column = index % columns;
        final reverse = row.isOdd;
        final visualColumn = reverse ? columns - 1 - column : column;
        return Offset(left + (visualColumn * step), top + (row * rowHeight));
      }(),
  ];
}

class _SubStagePathPainter extends CustomPainter {
  const _SubStagePathPainter({
    required this.centers,
    required this.completedStages,
    required this.color,
  });

  final List<Offset> centers;
  final int completedStages;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) {
      return;
    }

    final basePaint = Paint()
      ..color = AppTheme.rule.withValues(alpha: 0.72)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final activePaint = Paint()
      ..color = color.withValues(alpha: 0.88)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var index = 1; index < centers.length; index++) {
      final paint = index <= completedStages ? activePaint : basePaint;
      final previous = centers[index - 1];
      final current = centers[index];
      final path = Path()..moveTo(previous.dx, previous.dy);
      final controlX = (previous.dx + current.dx) / 2;
      path.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SubStagePathPainter oldDelegate) {
    return oldDelegate.centers != centers ||
        oldDelegate.completedStages != completedStages ||
        oldDelegate.color != color;
  }
}

class _SubStageDot extends StatelessWidget {
  const _SubStageDot({
    required this.number,
    required this.itemLabel,
    required this.completed,
    required this.current,
    required this.locked,
    required this.color,
    required this.onTap,
  });

  final int number;
  final String itemLabel;
  final bool completed;
  final bool current;
  final bool locked;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final background = completed
        ? color
        : current
        ? AppTheme.card
        : AppTheme.midnight.withValues(alpha: 0.08);
    final foreground = completed
        ? Colors.white
        : locked
        ? AppTheme.ink.withValues(alpha: 0.32)
        : color;

    return Tooltip(
      message: '$itemLabel $number',
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: current ? 38 : 32,
            height: current ? 38 : 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: current ? color : AppTheme.rule.withValues(alpha: 0.55),
                width: current ? 3 : 1,
              ),
            ),
            child: completed
                ? Transform.rotate(
                    angle: -0.16,
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
                  )
                : Text(
                    '$number',
                    maxLines: 1,
                    style: TextStyle(
                      color: foreground,
                      fontSize: number >= 100 ? 9 : 10.5,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ChapterConnector extends StatelessWidget {
  const _ChapterConnector({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Center(
        child: Container(
          width: 7,
          height: 34,
          decoration: BoxDecoration(
            color: completed
                ? AppTheme.pressGreen
                : AppTheme.rule.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
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
  const _FreePlayDock({required this.onProgressChanged});

  final VoidCallback onProgressChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.midnight,
      borderRadius: BorderRadius.circular(8),
      elevation: 8,
      shadowColor: AppTheme.midnight.withValues(alpha: 0.24),
      child: InkWell(
        key: const ValueKey<String>('stage_pautaLivre'),
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          await Navigator.of(context).push(
            appPageRoute<void>(
              settings: const RouteSettings(name: '/game/pautaLivre'),
              builder: (_) => const GameScreen(level: GameLevel.pautaLivre),
            ),
          );
          onProgressChanged();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
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
                      'Plantão: Pauta Livre',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Rodada solta com todos os cadernos',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 22,
              ),
            ],
          ),
        ),
      ),
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
  });

  factory _CampaignSnapshot.empty() {
    return const _CampaignSnapshot(
      progress: CampaignProgress(<GameLevel>{}),
      usedWordCounts: <GameLevel, int>{},
    );
  }

  final CampaignProgress progress;
  final Map<GameLevel, int> usedWordCounts;

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
