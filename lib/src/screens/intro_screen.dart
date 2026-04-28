import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jogopalavras/src/game/intro_preferences.dart';
import 'package:jogopalavras/src/navigation/app_page_route.dart';
import 'package:jogopalavras/src/screens/level_screen.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';
import 'package:jogopalavras/src/widgets/app_backdrop.dart';
import 'package:jogopalavras/src/widgets/reveal_on_mount.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _typewriterController;

  static const String _typedLine =
      'Arraste pelas letras, forme palavras e feche a manchete.';

  @override
  void initState() {
    super.initState();
    unawaited(IntroPreferences.markIntroSeen());
    _typewriterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
  }

  @override
  void dispose() {
    _typewriterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AppBackdrop(
        primary: AppTheme.pressBlue,
        secondary: AppTheme.pressRed,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RevealOnMount(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.card.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.midnight),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.midnight.withValues(alpha: 0.1),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.pressRed,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.newspaper_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'EXTRA • PRIMEIRA EDIÇÃO',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: AppTheme.pressRed,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(height: 2, color: AppTheme.midnight),
                              const SizedBox(height: 3),
                              Container(
                                height: 1,
                                color: AppTheme.midnight.withValues(
                                  alpha: 0.48,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Entreletras',
                                style: theme.textTheme.displayMedium?.copyWith(
                                  color: AppTheme.midnight,
                                  height: 0.95,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  9,
                                  12,
                                  9,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: AppTheme.pressRed,
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: AnimatedBuilder(
                                  animation: _typewriterController,
                                  builder: (context, child) {
                                    final visibleCharacters =
                                        (_typedLine.length *
                                                _typewriterController.value)
                                            .round()
                                            .clamp(0, _typedLine.length)
                                            .toInt();
                                    final showCursor =
                                        (_typewriterController.value < 1) ||
                                        (DateTime.now().millisecond ~/ 420)
                                            .isEven;

                                    return Text(
                                      '${_typedLine.substring(0, visibleCharacters)}${showCursor ? '|' : ''}',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: AppTheme.ink.withValues(
                                              alpha: 0.86,
                                            ),
                                            height: 1.32,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: const [
                                  _PressChip(
                                    icon: Icons.touch_app_rounded,
                                    label: 'arraste',
                                  ),
                                  _PressChip(
                                    icon: Icons.spellcheck_rounded,
                                    label: 'forme',
                                  ),
                                  _PressChip(
                                    icon: Icons.emoji_events_rounded,
                                    label: 'pontue',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      RevealOnMount(
                        delay: const Duration(milliseconds: 140),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppTheme.card.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.rule.withValues(alpha: 0.9),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Como jogar',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const _StepTile(
                                number: '1',
                                text: 'Escolha a editoria.',
                                accent: AppTheme.pressBlue,
                              ),
                              const SizedBox(height: 10),
                              const _StepTile(
                                number: '2',
                                text: 'Ligue letras vizinhas.',
                                accent: AppTheme.pressRed,
                              ),
                              const SizedBox(height: 10),
                              const _StepTile(
                                number: '3',
                                text: 'Ache palavras e suba no ranking.',
                                accent: AppTheme.pressGold,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      RevealOnMount(
                        delay: const Duration(milliseconds: 240),
                        beginOffset: const Offset(0, 0.06),
                        child: _PlayButton(
                          onPressed: () => _openLevelScreen(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openLevelScreen(BuildContext context) async {
    try {
      await IntroPreferences.markIntroSeen();
    } finally {
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          appPageRoute<void>(
            settings: const RouteSettings(name: '/levels'),
            builder: (_) => const LevelScreen(),
          ),
        );
      }
    }
  }
}

class _PressChip extends StatelessWidget {
  const _PressChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.midnight.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppTheme.rule.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.pressRed),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.midnight,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.text,
    required this.accent,
  });

  final String number;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.rule.withValues(alpha: 0.74)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.25, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onPressed});

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
              color: AppTheme.midnight.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.pressRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Iniciar jogo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
