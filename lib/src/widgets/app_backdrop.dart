import 'package:flutter/material.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({
    super.key,
    required this.child,
    this.primary = AppTheme.pressBlue,
    this.secondary = AppTheme.pressRed,
  });

  final Widget child;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppTheme.cream),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _NewsprintPainter(
                primary: primary,
                secondary: secondary,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.62),
                  AppTheme.cream.withValues(alpha: 0.8),
                  AppTheme.newsprint.withValues(alpha: 0.62),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          child,
        ],
      ),
    );
  }
}

class _NewsprintPainter extends CustomPainter {
  const _NewsprintPainter({required this.primary, required this.secondary});

  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final rulePaint = Paint()
      ..color = AppTheme.midnight.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    final columnPaint = Paint()
      ..color = AppTheme.midnight.withValues(alpha: 0.06)
      ..strokeWidth = 1.2;
    final accentPaint = Paint()
      ..color = secondary.withValues(alpha: 0.16)
      ..strokeWidth = 2.4;

    for (var y = 28.0; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rulePaint);
    }

    for (var x = 26.0; x < size.width; x += 112) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), columnPaint);
    }

    canvas.drawLine(
      Offset(0, size.height * 0.16),
      Offset(size.width, size.height * 0.16),
      accentPaint,
    );

    final mastheadPaint = Paint()
      ..color = primary.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final masthead = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.21)
      ..lineTo(0, size.height * 0.13)
      ..close();

    canvas.drawPath(masthead, mastheadPaint);
  }

  @override
  bool shouldRepaint(covariant _NewsprintPainter oldDelegate) {
    return oldDelegate.primary != primary || oldDelegate.secondary != secondary;
  }
}
