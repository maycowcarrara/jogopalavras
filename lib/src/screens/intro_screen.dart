import 'package:flutter/material.dart';
import 'package:jogopalavras/src/navigation/app_page_route.dart';
import 'package:jogopalavras/src/screens/level_screen.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';
import 'package:jogopalavras/src/widgets/app_backdrop.dart';
import 'package:jogopalavras/src/widgets/reveal_on_mount.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

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
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      RevealOnMount(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.card.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(12),
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
                                      'EDIÇÃO DE PALAVRAS',
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
                                'Anagrama\nOculto',
                                style: theme.textTheme.displaySmall?.copyWith(
                                  color: AppTheme.midnight,
                                  height: 0.95,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.only(left: 12),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: AppTheme.pressRed,
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Passe o dedo pelas letras e descubra palavras em português em uma edição feita para leitura rápida.',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppTheme.ink.withValues(alpha: 0.86),
                                    height: 1.36,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      RevealOnMount(
                        delay: const Duration(milliseconds: 140),
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppTheme.card.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.rule.withValues(alpha: 0.9),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Como funciona',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const _StepTile(
                                number: '1',
                                text: 'Escolha um nível.',
                                accent: AppTheme.pressBlue,
                              ),
                              const SizedBox(height: 12),
                              const _StepTile(
                                number: '2',
                                text:
                                    'Arraste o dedo pelas letras do tabuleiro.',
                                accent: AppTheme.pressRed,
                              ),
                              const SizedBox(height: 12),
                              const _StepTile(
                                number: '3',
                                text:
                                    'Encontre 10 palavras para vencer a rodada.',
                                accent: AppTheme.pressGold,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      RevealOnMount(
                        delay: const Duration(milliseconds: 200),
                        child: const _TransparencyNotice(),
                      ),
                      const SizedBox(height: 28),
                      RevealOnMount(
                        delay: const Duration(milliseconds: 240),
                        beginOffset: const Offset(0, 0.06),
                        child: _PlayButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              appPageRoute<void>(
                                builder: (_) => const LevelScreen(),
                              ),
                            );
                          },
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
}

class _TransparencyNotice extends StatelessWidget {
  const _TransparencyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.rule.withValues(alpha: 0.78)),
      ),
      child: Column(
        children: [
          const _InfoLine(
            icon: Icons.psychology_alt_rounded,
            title: 'Jogo rapido e inteligente',
            text:
                'Rodadas curtas para treinar vocabulario, atencao e raciocinio sem pressa.',
            accent: AppTheme.pressBlue,
          ),
          const SizedBox(height: 14),
          const _InfoLine(
            icon: Icons.campaign_rounded,
            title: 'Anuncios poucos e claros',
            text:
                'Quando ativados, ajudam a manter o app gratuito e aparecem apenas em espacos discretos ou pausas naturais.',
            accent: AppTheme.pressRed,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _showAdsInfo(context),
              icon: const Icon(Icons.info_outline_rounded, size: 18),
              label: const Text('Entender anuncios'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdsInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.card,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppTheme.rule),
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Anuncios no Anagrama Oculto'),
          content: const Text(
            'O jogo foi planejado para mostrar poucos anuncios. Banners ficam em areas reservadas e interstitials so podem aparecer depois de pausas naturais, nunca no meio da jogada. A receita ajuda a manter o app gratuito e financiar melhorias.',
            style: TextStyle(height: 1.35, fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.title,
    required this.text,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.midnight,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.ink.withValues(alpha: 0.76),
                  height: 1.32,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
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
              style: const TextStyle(height: 1.35, fontWeight: FontWeight.w600),
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
