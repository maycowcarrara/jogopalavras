import 'package:flutter/material.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({
    super.key,
    required this.child,
    this.primary = AppTheme.electricBlue,
    this.secondary = AppTheme.coral,
  });

  final Widget child;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            AppTheme.cream,
            AppTheme.amber.withValues(alpha: 0.08),
            primary.withValues(alpha: 0.08),
            secondary.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _GlowOrb(color: secondary.withValues(alpha: 0.2), size: 280),
          ),
          Positioned(
            top: 120,
            left: -90,
            child: _GlowOrb(color: primary.withValues(alpha: 0.12), size: 240),
          ),
          Positioned(
            bottom: -110,
            left: 40,
            child: _GlowOrb(
              color: AppTheme.amber.withValues(alpha: 0.2),
              size: 220,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
