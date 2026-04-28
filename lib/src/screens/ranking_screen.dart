import 'package:flutter/material.dart';
import 'package:jogopalavras/src/game/game_level.dart';
import 'package:jogopalavras/src/game/ranking_store.dart';
import 'package:jogopalavras/src/navigation/app_page_route.dart';
import 'package:jogopalavras/src/screens/game_screen.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';
import 'package:jogopalavras/src/widgets/ad_banner_slot.dart';
import 'package:jogopalavras/src/widgets/app_backdrop.dart';
import 'package:jogopalavras/src/widgets/reveal_on_mount.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key, this.initialLevel});

  final GameLevel? initialLevel;

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
          bottom: TabBar(
            labelColor: AppTheme.midnight,
            indicatorColor: AppTheme.pressRed,
            tabs: [
              for (final level in GameLevel.values) Tab(text: level.title),
            ],
          ),
        ),
        bottomNavigationBar: const AdBannerSlot(
          compact: true,
          safeAreaMinimum: EdgeInsets.fromLTRB(18, 0, 18, 10),
        ),
        body: AppBackdrop(
          primary: AppTheme.pressBlue,
          secondary: AppTheme.pressRed,
          child: SafeArea(
            top: false,
            child: TabBarView(
              children: [
                for (final level in GameLevel.values)
                  _RankingLevelView(level: level),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RankingLevelView extends StatelessWidget {
  const _RankingLevelView({required this.level});

  final GameLevel level;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RankingEntry>>(
      future: RankingStore.instance.loadEntries(level: level),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? <RankingEntry>[];

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          children: [
            RevealOnMount(child: _RankingHeader(level: level)),
            const SizedBox(height: 18),
            if (snapshot.connectionState != ConnectionState.done)
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
                    accent: level.accent,
                  ),
                ),
                const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }
}

class _RankingHeader extends StatelessWidget {
  const _RankingHeader({required this.level});

  final GameLevel level;

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: level.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white),
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
                  'Maior pontuação, menos palavras e menor tempo.',
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
                      Navigator.of(context).pushReplacement(
                        appPageRoute<void>(
                          settings: RouteSettings(name: '/game/${level.name}'),
                          builder: (_) => GameScreen(level: level),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: Text('Jogar no ${level.title.toLowerCase()}'),
                  ),
                ),
              ],
            ),
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
  });

  final int position;
  final RankingEntry entry;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.rule.withValues(alpha: 0.86)),
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
          _ScoreBadge(score: entry.score),
        ],
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
            'Complete uma rodada e registre suas 3 letras para aparecer aqui.',
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

String _formatTime(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
