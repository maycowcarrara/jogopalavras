import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
    this.highlightEntry,
    this.continueLevel,
    this.completedLevel,
    this.completedGame = false,
  });

  final GameLevel? initialLevel;
  final RankingEntry? highlightEntry;
  final GameLevel? continueLevel;
  final GameLevel? completedLevel;
  final bool completedGame;

  @override
  Widget build(BuildContext context) {
    final initialIndex = initialLevel == null
        ? 0
        : GameLevel.values.indexOf(initialLevel!);

    return DefaultTabController(
      length: GameLevel.values.length,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Ranking',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: const [AppOptionsControl()],
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
                    highlightEntry: highlightEntry?.level == level
                        ? highlightEntry
                        : null,
                    continueLevel: highlightEntry?.level == level
                        ? continueLevel
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
    );
  }
}

class _RankingLevelView extends StatefulWidget {
  const _RankingLevelView({
    required this.level,
    this.highlightEntry,
    this.continueLevel,
    this.completedLevel,
    this.completedGame = false,
  });

  final GameLevel level;
  final RankingEntry? highlightEntry;
  final GameLevel? continueLevel;
  final GameLevel? completedLevel;
  final bool completedGame;

  @override
  State<_RankingLevelView> createState() => _RankingLevelViewState();
}

class _RankingLevelViewState extends State<_RankingLevelView> {
  late Future<List<RankingEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _loadEntries();
  }

  Future<List<RankingEntry>> _loadEntries() {
    return RankingStore.instance.loadEntries(level: widget.level);
  }

  Future<void> _refreshEntries() async {
    final nextEntries = _loadEntries();
    setState(() {
      _entriesFuture = nextEntries;
    });
    await nextEntries;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RankingEntry>>(
      future: _entriesFuture,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? <RankingEntry>[];
        final isLoading = snapshot.connectionState != ConnectionState.done;
        final highlightPosition = widget.highlightEntry == null || isLoading
            ? 0
            : entries.indexWhere(
                    (entry) => _sameRankingEntry(entry, widget.highlightEntry!),
                  ) +
                  1;

        return RefreshIndicator(
          onRefresh: _refreshEntries,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              RevealOnMount(
                child: _RankingHeader(
                  level: widget.level,
                  highlightEntry: widget.highlightEntry,
                  highlightPosition: highlightPosition,
                  continueLevel: widget.continueLevel,
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
              else
                for (var index = 0; index < entries.length; index++) ...[
                  RevealOnMount(
                    delay: Duration(milliseconds: 70 + (index * 35)),
                    child: _RankingCard(
                      position: index + 1,
                      entry: entries[index],
                      accent: widget.level.accent,
                      isHighlighted:
                          widget.highlightEntry != null &&
                          _sameRankingEntry(
                            entries[index],
                            widget.highlightEntry!,
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _RankingHeader extends StatelessWidget {
  const _RankingHeader({
    required this.level,
    this.highlightEntry,
    this.highlightPosition = 0,
    this.continueLevel,
    this.completedLevel,
    this.completedGame = false,
    this.isLoading = false,
  });

  final GameLevel level;
  final RankingEntry? highlightEntry;
  final int highlightPosition;
  final GameLevel? continueLevel;
  final GameLevel? completedLevel;
  final bool completedGame;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final resultText = highlightEntry == null
        ? 'Pontuação por eficiência: menos palavras e menor tempo.'
        : isLoading
        ? 'Calculando sua posição nesta fase...'
        : highlightPosition > 0
        ? 'Sua rodada ficou em #$highlightPosition com ${highlightEntry!.score} pontos.'
        : 'Sua rodada foi salva com ${highlightEntry!.score} pontos e ficou fora do top 10.';

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
                      'Melhores em ${level.title.toLowerCase()}',
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                        ),
                        onPressed: () {
                          final nextLevel = continueLevel ?? level;
                          Navigator.of(context).pushReplacement(
                            appPageRoute<void>(
                              settings: RouteSettings(
                                name: '/game/${nextLevel.name}',
                              ),
                              builder: (_) => GameScreen(level: nextLevel),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: Text(
                          highlightEntry == null
                              ? 'Jogar no ${level.title.toLowerCase()}'
                              : continueLevel == null || continueLevel == level
                              ? 'Continuar fase'
                              : 'Continuar no ${continueLevel!.title.toLowerCase()}',
                        ),
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
                fontWeight: FontWeight.w900,
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
            'Complete uma rodada e registre de 3 a 5 letras para aparecer aqui.',
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
