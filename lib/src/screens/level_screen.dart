import 'package:flutter/material.dart';
import 'package:jogopalavras/src/game/game_level.dart';
import 'package:jogopalavras/src/navigation/app_page_route.dart';
import 'package:jogopalavras/src/screens/game_screen.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';
import 'package:jogopalavras/src/widgets/ad_banner_slot.dart';
import 'package:jogopalavras/src/widgets/app_backdrop.dart';
import 'package:jogopalavras/src/widgets/reveal_on_mount.dart';

class LevelScreen extends StatelessWidget {
  const LevelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: AppBackdrop(
        primary: AppTheme.pressBlue,
        secondary: AppTheme.pressRed,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              RevealOnMount(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.midnight,
                    borderRadius: BorderRadius.circular(12),
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cada nível muda o tamanho das palavras e a densidade do tabuleiro.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _HeroSummary(
                        icon: Icons.subject_rounded,
                        label:
                            'Palavras de 4 a 9 letras • da nota curta ao caderno especial',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              for (var index = 0; index < GameLevel.values.length; index++) ...[
                RevealOnMount(
                  delay: Duration(milliseconds: 100 + (index * 70)),
                  child: _LevelCard(level: GameLevel.values[index]),
                ),
                const SizedBox(height: 18),
              ],
              const AdBannerSlot(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level});

  final GameLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.rule.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: level.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(level.icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      level.subtitle,
                      style: TextStyle(
                        height: 1.35,
                        color: AppTheme.ink.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: level.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: level.accent.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  level.wordSizeShortLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _LevelNote(
                  icon: Icons.text_fields_rounded,
                  text: level.wordSizeLabel,
                  accent: level.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LevelNote(
                  icon: Icons.emoji_events_rounded,
                  text: _goalLabel(level),
                  accent: level.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _LevelPlayButton(
            label: _ctaLabel(level),
            accent: level.accent,
            onPressed: () {
              Navigator.of(context).push(
                appPageRoute<void>(builder: (_) => GameScreen(level: level)),
              );
            },
          ),
        ],
      ),
    );
  }
}

String _ctaLabel(GameLevel level) => switch (level) {
  GameLevel.easy => 'Começar no fácil',
  GameLevel.medium => 'Encara o médio',
  GameLevel.hard => 'Partir para o difícil',
};

String _goalLabel(GameLevel level) => switch (level) {
  GameLevel.easy => 'Ritmo leve',
  GameLevel.medium => 'Bom equilíbrio',
  GameLevel.hard => 'Desafio forte',
};

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelNote extends StatelessWidget {
  const _LevelNote({
    required this.icon,
    required this.text,
    required this.accent,
  });

  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.midnight, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelPlayButton extends StatelessWidget {
  const _LevelPlayButton({
    required this.label,
    required this.accent,
    required this.onPressed,
  });

  final String label;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppTheme.midnight,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppTheme.midnight.withValues(alpha: 0.16),
              blurRadius: 16,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
