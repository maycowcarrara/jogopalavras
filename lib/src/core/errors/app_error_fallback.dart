import 'package:flutter/material.dart';
import 'package:jogopalavras/src/screens/level_screen.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';
import 'package:jogopalavras/src/widgets/app_backdrop.dart';

class AppErrorFallback extends StatelessWidget {
  const AppErrorFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackdrop(
        primary: AppTheme.pressBlue,
        secondary: AppTheme.pressRed,
        showOptionsControl: false,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.card.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.rule),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.midnight.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.restart_alt_rounded,
                          color: AppTheme.pressRed,
                          size: 34,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Ops, vamos continuar',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Encontramos uma falha nesta tela, mas seu jogo não precisa parar. O diagnóstico foi salvo para correção.',
                          style: TextStyle(height: 1.35),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _goBack(context),
                                child: const Text('Voltar'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _goHome(context),
                                child: const Text('Início'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _goBack(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final didPop = await navigator.maybePop();
    if (!didPop && context.mounted) {
      _goHome(context);
    }
  }

  void _goHome(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/levels'),
        builder: (_) => const LevelScreen(),
      ),
      (route) => false,
    );
  }
}
