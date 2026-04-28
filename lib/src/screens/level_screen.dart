import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:jogopalavras/src/game/game_level.dart';
import 'package:jogopalavras/src/navigation/app_page_route.dart';
import 'package:jogopalavras/src/screens/game_screen.dart';
import 'package:jogopalavras/src/screens/ranking_screen.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';
import 'package:jogopalavras/src/widgets/ad_banner_slot.dart';
import 'package:jogopalavras/src/widgets/app_backdrop.dart';
import 'package:jogopalavras/src/widgets/reveal_on_mount.dart';

class LevelScreen extends StatelessWidget {
  const LevelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AdBannerSlot(
        adSize: AdSize.largeBanner,
        safeAreaMinimum: EdgeInsets.fromLTRB(18, 0, 18, 10),
      ),
      body: AppBackdrop(
        primary: AppTheme.pressBlue,
        secondary: AppTheme.pressRed,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const padding = EdgeInsets.fromLTRB(18, 4, 18, 18);
              final shouldScroll = constraints.maxHeight < 680;

              if (shouldScroll) {
                return ListView(
                  padding: padding,
                  children: const [
                    _LevelHero(),
                    SizedBox(height: 14),
                    _LevelList(expanded: false),
                  ],
                );
              }

              return Padding(
                padding: padding,
                child: const Column(
                  children: [
                    _LevelHero(),
                    SizedBox(height: 14),
                    Expanded(child: _LevelList(expanded: true)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
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
              'Cada nível muda o tamanho das palavras e a densidade do tabuleiro.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.86),
                height: 1.18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            const _HeroSummary(
              icon: Icons.subject_rounded,
              label:
                  'Palavras de 4 a 9 letras • da nota curta ao caderno especial',
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    appPageRoute<void>(
                      settings: const RouteSettings(name: '/ranking'),
                      builder: (_) => const RankingScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.leaderboard_rounded, size: 18),
                label: const Text('Ver ranking'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelList extends StatelessWidget {
  const _LevelList({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final cards = [
      for (var index = 0; index < GameLevel.values.length; index++)
        RevealOnMount(
          delay: Duration(milliseconds: 100 + (index * 70)),
          child: _LevelCard(
            level: GameLevel.values[index],
            prominent: expanded,
          ),
        ),
    ];

    if (!expanded) {
      return Column(
        children: [
          for (final card in cards) ...[
            card,
            if (card != cards.last) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Column(
      children: [
        for (final card in cards) ...[
          Expanded(child: card),
          if (card != cards.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, this.prominent = false});

  final GameLevel level;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = prominent ? 48.0 : 42.0;

    return Material(
      color: AppTheme.card.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.rule.withValues(alpha: 0.9)),
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
          onTap: () {
            Navigator.of(context).push(
              appPageRoute<void>(
                settings: RouteSettings(name: '/game/${level.name}'),
                builder: (_) => GameScreen(level: level),
              ),
            );
          },
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
                    color: level.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    level.icon,
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
                              level.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            level.wordSizeShortLabel,
                            style: TextStyle(
                              color: level.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        level.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.ink.withValues(alpha: 0.78),
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
                            _ctaLabel(level),
                            style: TextStyle(
                              color: AppTheme.ink.withValues(alpha: 0.9),
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
                  Icons.arrow_forward_rounded,
                  color: AppTheme.midnight.withValues(alpha: 0.72),
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

String _ctaLabel(GameLevel level) => switch (level) {
  GameLevel.easy => 'Começar no fácil',
  GameLevel.medium => 'Encara o médio',
  GameLevel.hard => 'Partir para o difícil',
  GameLevel.pautaLivre => 'Abrir pauta livre',
};

String _goalLabel(GameLevel level) => switch (level) {
  GameLevel.easy => 'Ritmo leve',
  GameLevel.medium => 'Bom equilíbrio',
  GameLevel.hard => 'Desafio forte',
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
