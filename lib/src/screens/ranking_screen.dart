import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:jogopalavras/src/game/campaign_stage_rules.dart';
import 'package:jogopalavras/src/game/game_level.dart';
import 'package:jogopalavras/src/game/ranking_store.dart';
import 'package:jogopalavras/src/navigation/app_page_route.dart';
import 'package:jogopalavras/src/screens/game_screen.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';
import 'package:jogopalavras/src/widgets/ad_banner_slot.dart';
import 'package:jogopalavras/src/widgets/app_backdrop.dart';
import 'package:jogopalavras/src/widgets/reveal_on_mount.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({
    super.key,
    this.initialLevel,
    this.initialStageNumber,
    this.highlightEntry,
    this.initialEntries,
    this.initialResult,
    this.continueLevel,
    this.continueStageNumber,
    this.completedLevel,
    this.completedGame = false,
  });

  final GameLevel? initialLevel;
  final int? initialStageNumber;
  final RankingEntry? highlightEntry;
  final List<RankingEntry>? initialEntries;
  final RankingEntriesResult? initialResult;
  final GameLevel? continueLevel;
  final int? continueStageNumber;
  final GameLevel? completedLevel;
  final bool completedGame;

  @override
  Widget build(BuildContext context) {
    final initialIndex = initialLevel == null
        ? 0
        : GameLevel.values.indexOf(initialLevel!);
    final singleLevel =
        initialStageNumber != null || initialLevel == GameLevel.pautaLivre;
    final selectedLevel = initialLevel ?? GameLevel.easy;
    final showStageCelebration = _shouldShowStageCelebration(highlightEntry);
    final celebrationAccent =
        highlightEntry?.level.accent ?? selectedLevel.accent;

    if (singleLevel) {
      return _StageCelebrationShell(
        show: showStageCelebration,
        accent: celebrationAccent,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Ranking',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: const [_RankingOptionsAction()],
          ),
          bottomNavigationBar: const AdBannerSlot(
            adSize: AdSize.largeBanner,
            safeAreaMinimum: EdgeInsets.fromLTRB(18, 0, 18, 12),
          ),
          body: AppBackdrop(
            primary: AppTheme.pressBlue,
            secondary: AppTheme.pressRed,
            showOptionsControl: false,
            child: SafeArea(
              top: false,
              child: _RankingLevelView(
                level: selectedLevel,
                stageNumber: highlightEntry?.stageNumber ?? initialStageNumber,
                highlightEntry: highlightEntry,
                initialEntries: initialEntries,
                initialResult: initialResult,
                continueLevel: continueLevel,
                continueStageNumber: continueStageNumber,
                completedLevel: completedLevel,
                completedGame: completedGame,
              ),
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: GameLevel.values.length,
      initialIndex: initialIndex,
      child: _StageCelebrationShell(
        show: showStageCelebration,
        accent: celebrationAccent,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Ranking',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: const [_RankingOptionsAction()],
            bottom: TabBar(
              labelColor: AppTheme.midnight,
              indicatorColor: AppTheme.pressRed,
              tabs: [
                for (final level in GameLevel.values) Tab(text: level.title),
              ],
            ),
          ),
          bottomNavigationBar: const AdBannerSlot(
            adSize: AdSize.largeBanner,
            safeAreaMinimum: EdgeInsets.fromLTRB(18, 0, 18, 12),
          ),
          body: AppBackdrop(
            primary: AppTheme.pressBlue,
            secondary: AppTheme.pressRed,
            showOptionsControl: false,
            child: SafeArea(
              top: false,
              child: TabBarView(
                children: [
                  for (final level in GameLevel.values)
                    _RankingLevelView(
                      level: level,
                      stageNumber: highlightEntry?.level == level
                          ? highlightEntry!.stageNumber
                          : initialStageNumber,
                      highlightEntry: highlightEntry?.level == level
                          ? highlightEntry
                          : null,
                      initialEntries: highlightEntry?.level == level
                          ? initialEntries
                          : null,
                      initialResult: highlightEntry?.level == level
                          ? initialResult
                          : null,
                      continueLevel: highlightEntry?.level == level
                          ? continueLevel
                          : null,
                      continueStageNumber: highlightEntry?.level == level
                          ? continueStageNumber
                          : null,
                      completedLevel: highlightEntry?.level == level
                          ? completedLevel
                          : null,
                      completedGame:
                          highlightEntry?.level == level && completedGame,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool _shouldShowStageCelebration(RankingEntry? entry) {
  if (entry == null || entry.level.mixesAllLevels || entry.stageNumber <= 0) {
    return false;
  }

  return campaignProductionStepsForLevel(
    entry.level,
  ).any((step) => step.lastStage == entry.stageNumber);
}

class _StageCelebrationShell extends StatelessWidget {
  const _StageCelebrationShell({
    required this.show,
    required this.accent,
    required this.child,
  });

  final bool show;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!show) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned.fill(child: _StageCompletionConfetti(accent: accent)),
        Positioned.fill(child: _StageCompletionApplause(accent: accent)),
      ],
    );
  }
}

class _RankingOptionsAction extends StatelessWidget {
  const _RankingOptionsAction();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 12),
      child: Center(child: AppOptionsControl()),
    );
  }
}

class _RankingLevelView extends StatefulWidget {
  const _RankingLevelView({
    required this.level,
    this.stageNumber,
    this.highlightEntry,
    this.initialEntries,
    this.initialResult,
    this.continueLevel,
    this.continueStageNumber,
    this.completedLevel,
    this.completedGame = false,
  });

  final GameLevel level;
  final int? stageNumber;
  final RankingEntry? highlightEntry;
  final List<RankingEntry>? initialEntries;
  final RankingEntriesResult? initialResult;
  final GameLevel? continueLevel;
  final int? continueStageNumber;
  final GameLevel? completedLevel;
  final bool completedGame;

  @override
  State<_RankingLevelView> createState() => _RankingLevelViewState();
}

class _RankingLevelViewState extends State<_RankingLevelView> {
  static const _manualTopLimit = 50;

  late Future<RankingEntriesResult> _entriesFuture;

  int? get _effectiveStageNumber {
    if (widget.level == GameLevel.pautaLivre) {
      return widget.stageNumber;
    }
    return widget.highlightEntry?.stageNumber ?? widget.stageNumber ?? 1;
  }

  @override
  void initState() {
    super.initState();
    final initialResult = widget.initialResult;
    if (initialResult != null) {
      _entriesFuture = Future<RankingEntriesResult>.value(initialResult);
      return;
    }

    final initialEntries = widget.initialEntries;
    _entriesFuture = initialEntries == null
        ? _loadEntries()
        : Future<RankingEntriesResult>.value(
            RankingEntriesResult.fromFullEntries(
              initialEntries,
              highlightedEntry: widget.highlightEntry,
              limit: widget.highlightEntry == null ? _manualTopLimit : null,
            ),
          );
  }

  Future<RankingEntriesResult> _loadEntries({bool forceRefresh = false}) async {
    final result = await RankingStore.instance.loadEntriesResult(
      level: widget.level,
      stageNumber: _effectiveStageNumber,
      limit: widget.highlightEntry == null ? _manualTopLimit : 11,
      aroundEntry: widget.highlightEntry,
      forceRefresh: forceRefresh,
    );
    await RankingStore.instance.cacheCurrentStagePosition(
      level: widget.level,
      stageNumber: _effectiveStageNumber,
      entries: result.entries,
    );
    return result;
  }

  Future<void> _refreshEntries() async {
    final nextEntries = _loadEntries(forceRefresh: true);
    setState(() {
      _entriesFuture = nextEntries;
    });
    await nextEntries;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RankingEntriesResult>(
      future: _entriesFuture,
      builder: (context, snapshot) {
        final result =
            snapshot.data ??
            const RankingEntriesResult(
              entries: <RankingEntry>[],
              startPosition: 0,
              totalEntries: 0,
            );
        final entries = result.entries;
        final isLoading = snapshot.connectionState != ConnectionState.done;
        final highlightIndex = widget.highlightEntry == null || isLoading
            ? -1
            : entries.indexWhere(
                (entry) => _sameRankingEntry(entry, widget.highlightEntry!),
              );
        final highlightPosition = widget.highlightEntry == null || isLoading
            ? 0
            : result.highlightedPosition ??
                  (highlightIndex < 0
                      ? 0
                      : result.startPosition + highlightIndex);
        final window = _RankingWindow.fromResult(
          result,
          highlightPosition: highlightPosition,
        );
        final highlightedEntry = widget.highlightEntry;
        final contextEntries = [
          for (var index = 0; index < window.entries.length; index++)
            if (highlightedEntry == null ||
                !_sameRankingEntry(window.entries[index], highlightedEntry))
              _PositionedRankingEntry(
                position: window.startPosition + index,
                entry: window.entries[index],
              ),
        ];

        return RefreshIndicator(
          onRefresh: _refreshEntries,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              RevealOnMount(
                child: _RankingHeader(
                  level: widget.level,
                  stageNumber: _effectiveStageNumber,
                  highlightEntry: widget.highlightEntry,
                  highlightPosition: highlightPosition,
                  continueLevel: widget.continueLevel,
                  continueStageNumber: widget.continueStageNumber,
                  completedLevel: widget.completedLevel,
                  completedGame: widget.completedGame,
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(height: 18),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (entries.isEmpty)
                const _EmptyRanking()
              else ...[
                if (widget.highlightEntry != null && highlightPosition > 0) ...[
                  _HighlightedRankingResult(
                    position: highlightPosition,
                    entry: widget.highlightEntry!,
                    accent: widget.level.accent,
                  ),
                  if (contextEntries.isNotEmpty) const SizedBox(height: 18),
                ],
                if (contextEntries.isNotEmpty && window.isTrimmed) ...[
                  _RankingWindowLabel(window: window),
                  const SizedBox(height: 9),
                ],
                for (var index = 0; index < contextEntries.length; index++) ...[
                  RevealOnMount(
                    delay: Duration(milliseconds: 70 + (index * 35)),
                    child: _RankingCard(
                      position: contextEntries[index].position,
                      entry: contextEntries[index].entry,
                      accent: widget.level.accent,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PositionedRankingEntry {
  const _PositionedRankingEntry({required this.position, required this.entry});

  final int position;
  final RankingEntry entry;
}

class _RankingWindow {
  const _RankingWindow({
    required this.entries,
    required this.startPosition,
    required this.totalEntries,
  });

  static const _neighbors = 5;

  final List<RankingEntry> entries;
  final int startPosition;
  final int totalEntries;

  bool get isTrimmed => entries.length < totalEntries;
  int get endPosition => startPosition + entries.length - 1;

  factory _RankingWindow.fromEntries(
    List<RankingEntry> entries, {
    required int highlightPosition,
  }) {
    if (highlightPosition <= 0) {
      return _RankingWindow(
        entries: entries,
        startPosition: entries.isEmpty ? 0 : 1,
        totalEntries: entries.length,
      );
    }

    final highlightIndex = highlightPosition - 1;
    final start = (highlightIndex - _neighbors).clamp(0, entries.length);
    final end = (highlightIndex + _neighbors + 1).clamp(0, entries.length);

    return _RankingWindow(
      entries: entries.sublist(start, end),
      startPosition: start + 1,
      totalEntries: entries.length,
    );
  }

  factory _RankingWindow.fromResult(
    RankingEntriesResult result, {
    required int highlightPosition,
  }) {
    if (result.isPartial) {
      return _RankingWindow(
        entries: result.entries,
        startPosition: result.startPosition,
        totalEntries: result.totalEntries,
      );
    }

    return _RankingWindow.fromEntries(
      result.entries,
      highlightPosition: highlightPosition,
    );
  }
}

class _RankingWindowLabel extends StatelessWidget {
  const _RankingWindowLabel({required this.window});

  final _RankingWindow window;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Mostrando #${window.startPosition} a #${window.endPosition} de ${window.totalEntries}',
      style: TextStyle(
        color: AppTheme.ink.withValues(alpha: 0.66),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        height: 1,
        letterSpacing: 0,
      ),
    );
  }
}

class _RankingHeader extends StatelessWidget {
  const _RankingHeader({
    required this.level,
    this.stageNumber,
    this.highlightEntry,
    this.highlightPosition = 0,
    this.continueLevel,
    this.continueStageNumber,
    this.completedLevel,
    this.completedGame = false,
    this.isLoading = false,
  });

  final GameLevel level;
  final int? stageNumber;
  final RankingEntry? highlightEntry;
  final int highlightPosition;
  final GameLevel? continueLevel;
  final int? continueStageNumber;
  final GameLevel? completedLevel;
  final bool completedGame;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final stageLabel =
        stageNumber != null && stageNumber! > 0 && level != GameLevel.pautaLivre
        ? campaignStageLabelForLevel(level, stageNumber!)
        : null;
    final resultText = highlightEntry == null
        ? level == GameLevel.pautaLivre && stageNumber == null
              ? 'Ranking geral do plantão: menos palavras e menor tempo.'
              : 'Pontuação por eficiência: menos palavras e menor tempo.'
        : isLoading
        ? 'Calculando sua posição nesta fase...'
        : highlightPosition > 0
        ? 'Sua rodada ficou em #$highlightPosition com ${highlightEntry!.score} pontos.'
        : 'Sua rodada foi salva com ${highlightEntry!.score} pontos.';
    final actionLabel = _rankingPrimaryActionLabel(
      level: level,
      stageNumber: stageNumber,
      highlightEntry: highlightEntry,
      continueLevel: continueLevel,
      continueStageNumber: continueStageNumber,
      completedGame: completedGame,
    );
    final actionIcon = highlightEntry == null
        ? Icons.play_arrow_rounded
        : Icons.arrow_forward_rounded;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.midnight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.midnight),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (completedLevel != null) ...[
            _CompletionBanner(
              level: completedLevel!,
              completedGame: completedGame,
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: level.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stageLabel != null
                          ? 'Melhores: $stageLabel $stageNumber'
                          : level == GameLevel.pautaLivre
                          ? 'Melhores do Plantão'
                          : 'Melhores em ${level.title.toLowerCase()}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resultText,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.card,
                          foregroundColor: AppTheme.midnight,
                          elevation: 0,
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                        ),
                        onPressed: () {
                          final nextLevel = continueLevel ?? level;
                          final replaySelectedStage =
                              highlightEntry == null &&
                              stageNumber != null &&
                              stageNumber! > 0;
                          final campaignContinueStage =
                              highlightEntry != null &&
                                  continueLevel != null &&
                                  continueLevel == level
                              ? continueStageNumber
                              : null;
                          Navigator.of(context).pushReplacement(
                            appPageRoute<void>(
                              settings: RouteSettings(
                                name: '/game/${nextLevel.name}',
                              ),
                              builder: (_) => GameScreen(
                                level: nextLevel,
                                stageNumber:
                                    campaignContinueStage ??
                                    (replaySelectedStage ? stageNumber : null),
                                replayStage: replaySelectedStage,
                              ),
                            ),
                          );
                        },
                        icon: Icon(actionIcon, size: 20),
                        label: Text(actionLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageCompletionConfetti extends StatefulWidget {
  const _StageCompletionConfetti({required this.accent});

  final Color accent;

  @override
  State<_StageCompletionConfetti> createState() =>
      _StageCompletionConfettiState();
}

class _StageCompletionConfettiState extends State<_StageCompletionConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return IgnorePointer(
        child: CustomPaint(
          painter: _StageCompletionConfettiPainter(
            progress: 0.62,
            accent: widget.accent,
          ),
        ),
      );
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _StageCompletionConfettiPainter(
              progress: Curves.easeOutCubic.transform(_controller.value),
              accent: widget.accent,
            ),
          );
        },
      ),
    );
  }
}

class _StageCompletionApplause extends StatefulWidget {
  const _StageCompletionApplause({required this.accent});

  final Color accent;

  @override
  State<_StageCompletionApplause> createState() =>
      _StageCompletionApplauseState();
}

class _StageCompletionApplauseState extends State<_StageCompletionApplause>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  static const _cues = [
    _ApplauseCue(Alignment(-0.88, -0.72), 0.00, -0.32),
    _ApplauseCue(Alignment(0.84, -0.66), 0.08, 0.28),
    _ApplauseCue(Alignment(-0.66, -0.34), 0.16, -0.18),
    _ApplauseCue(Alignment(0.66, -0.30), 0.24, 0.22),
    _ApplauseCue(Alignment(-0.36, -0.78), 0.32, -0.26),
    _ApplauseCue(Alignment(0.34, -0.76), 0.40, 0.26),
  ];

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final progress = reduceMotion ? 0.68 : _controller.value;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final value = reduceMotion ? progress : _controller.value;
          return Stack(
            children: [
              for (var index = 0; index < _cues.length; index++)
                _ApplauseHand(
                  cue: _cues[index],
                  progress: value,
                  color: index.isEven ? widget.accent : AppTheme.pressGold,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ApplauseCue {
  const _ApplauseCue(this.alignment, this.delay, this.rotation);

  final Alignment alignment;
  final double delay;
  final double rotation;
}

class _ApplauseHand extends StatelessWidget {
  const _ApplauseHand({
    required this.cue,
    required this.progress,
    required this.color,
  });

  final _ApplauseCue cue;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = ((progress - cue.delay) / 0.56).clamp(0.0, 1.0).toDouble();
    final wave = math.sin(t * math.pi).clamp(0.0, 1.0).toDouble();
    final scale = 0.62 + (Curves.easeOutBack.transform(t) * 0.48);
    final lift = wave * 22;
    final opacity = wave * 0.92;

    return Align(
      alignment: cue.alignment,
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(0, -lift),
          child: Transform.rotate(
            angle: cue.rotation + (math.sin(t * math.pi * 2) * 0.16),
            child: Transform.scale(
              scale: scale,
              child: Icon(
                Icons.waving_hand_rounded,
                color: color,
                size: 32,
                shadows: [
                  Shadow(
                    color: AppTheme.midnight.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StageCompletionConfettiPainter extends CustomPainter {
  const _StageCompletionConfettiPainter({
    required this.progress,
    required this.accent,
  });

  final double progress;
  final Color accent;

  static const _pieceCount = 96;
  static const _palette = [
    AppTheme.pressGold,
    AppTheme.pressRed,
    AppTheme.pressBlue,
    AppTheme.pressGreen,
    Colors.white,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final fade = (1 - ((progress - 0.82) / 0.18).clamp(0.0, 1.0)).toDouble();
    final random = math.Random(7);
    for (var index = 0; index < _pieceCount; index++) {
      final startX = random.nextDouble() * size.width;
      final drift = (random.nextDouble() - 0.5) * 120;
      final fall = 40 + (random.nextDouble() * size.height * 1.08);
      final x = startX + (drift * progress);
      final y = -14 + (fall * progress);
      final width = 5 + random.nextDouble() * 7;
      final height = 8 + random.nextDouble() * 11;
      final rotation = (random.nextDouble() * math.pi) + (progress * math.pi);
      final color = index % 5 == 0 ? accent : _palette[index % _palette.length];

      final paint = Paint()
        ..color = color.withValues(alpha: 0.86 * fade)
        ..style = PaintingStyle.fill;

      canvas
        ..save()
        ..translate(x, y)
        ..rotate(rotation)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: width, height: height),
            const Radius.circular(1.5),
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StageCompletionConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.accent != accent;
  }
}

class _CompletionBanner extends StatelessWidget {
  const _CompletionBanner({required this.level, required this.completedGame});

  final GameLevel level;
  final bool completedGame;

  @override
  Widget build(BuildContext context) {
    final title = completedGame
        ? 'Edição entregue'
        : switch (level) {
            GameLevel.easy => 'Pauta concluída',
            GameLevel.medium => 'Redação concluída',
            GameLevel.hard => 'Fechamento concluído',
            GameLevel.pautaLivre => 'Plantão concluído',
          };
    final subtitle = completedGame
        ? 'Você fechou a campanha inteira. A edição está pronta para circular.'
        : switch (level) {
            GameLevel.easy =>
              'A apuração inicial está pronta para virar matéria.',
            GameLevel.medium =>
              'O texto ganhou corpo e segue para o fechamento.',
            GameLevel.hard => 'A última página foi revisada com sucesso.',
            GameLevel.pautaLivre => 'Rodada livre registrada no plantão.',
          };

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          alignment: Alignment.centerLeft,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: level.accent.withValues(alpha: 0.72)),
        ),
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 760),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: (1 - value) * -0.45,
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: level.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  completedGame
                      ? Icons.local_shipping_rounded
                      : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightedRankingResult extends StatelessWidget {
  const _HighlightedRankingResult({
    required this.position,
    required this.entry,
    required this.accent,
  });

  final int position;
  final RankingEntry entry;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Seu resultado no ranking',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.my_location_rounded, color: accent, size: 18),
              const SizedBox(width: 7),
              Text(
                'Seu resultado',
                style: TextStyle(
                  color: AppTheme.midnight,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _RankingCard(
            position: position,
            entry: entry,
            accent: accent,
            isHighlighted: true,
          ),
        ],
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({
    required this.position,
    required this.entry,
    required this.accent,
    this.isHighlighted = false,
  });

  final int position;
  final RankingEntry entry;
  final Color accent;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final positionFontSize = position >= 1000
        ? 11.0
        : position >= 100
        ? 12.0
        : 14.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? accent.withValues(alpha: 0.13)
            : AppTheme.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted ? accent : AppTheme.rule.withValues(alpha: 0.86),
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: position <= 3
                  ? AppTheme.pressGold
                  : accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Text(
              '$position',
              style: TextStyle(
                color: position <= 3 ? Colors.white : AppTheme.ink,
                fontSize: positionFontSize,
                fontWeight: FontWeight.w900,
                height: 1,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.initials,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.words} palavras • ${_formatTime(entry.elapsedSeconds)}',
                  style: TextStyle(
                    color: AppTheme.ink.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (isHighlighted) ...[
            const SizedBox(width: 10),
            _CurrentPlayerBadge(accent: accent),
          ],
          _ScoreBadge(score: entry.score),
        ],
      ),
    );
  }
}

class _CurrentPlayerBadge extends StatelessWidget {
  const _CurrentPlayerBadge({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Você',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.midnight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          Text(
            'pts',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRanking extends StatelessWidget {
  const _EmptyRanking();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.rule.withValues(alpha: 0.86)),
      ),
      child: Column(
        children: [
          const Icon(Icons.leaderboard_rounded, size: 38),
          const SizedBox(height: 12),
          Text(
            'Ainda sem campeões',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete esta fase e registre de 3 a 6 letras ou números para aparecer aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.ink.withValues(alpha: 0.72),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

bool _sameRankingEntry(RankingEntry a, RankingEntry b) {
  final sameCompletedAt =
      a.completedAt.difference(b.completedAt).abs() <
      const Duration(seconds: 2);

  return a.initials == b.initials &&
      a.level == b.level &&
      a.stageNumber == b.stageNumber &&
      a.score == b.score &&
      a.words == b.words &&
      a.elapsedSeconds == b.elapsedSeconds &&
      a.errors == b.errors &&
      a.skipsUsed == b.skipsUsed &&
      sameCompletedAt;
}

String _formatTime(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _rankingPrimaryActionLabel({
  required GameLevel level,
  required int? stageNumber,
  required RankingEntry? highlightEntry,
  required GameLevel? continueLevel,
  required int? continueStageNumber,
  required bool completedGame,
}) {
  final stageLabel =
      stageNumber != null && stageNumber > 0 && level != GameLevel.pautaLivre
      ? campaignStageLabelForLevel(level, stageNumber)
      : null;

  if (highlightEntry == null) {
    return stageLabel == null
        ? 'Jogar ${level.title.toLowerCase()}'
        : 'Jogar $stageLabel $stageNumber';
  }

  if (completedGame || continueLevel == null) {
    return 'Jogar novamente';
  }

  if (continueLevel == level &&
      continueStageNumber != null &&
      continueStageNumber > 0) {
    final nextStageLabel = campaignStageLabelForLevel(
      level,
      continueStageNumber,
    );
    return 'Próxima fase: $nextStageLabel $continueStageNumber';
  }

  if (continueLevel == level) {
    return 'Próxima fase';
  }

  return 'Avançar para ${continueLevel.title}';
}
