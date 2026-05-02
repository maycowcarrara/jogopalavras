import 'package:flutter/material.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';

class NewsTickerBar extends StatefulWidget {
  const NewsTickerBar({
    super.key,
    this.label = 'NEWS',
    this.messages = const [
      'Em breve: fases especiais do Clarim Diário (Marvel), Planeta Diário (DC) e Gazeta de Gotham (DC)',
      'Novas campanhas temáticas entrarão no mapa do Entreletras em futuras atualizações.',
    ],
    this.compact = false,
    this.margin = EdgeInsets.zero,
    this.safeAreaMinimum = const EdgeInsets.fromLTRB(0, 0, 0, 0),
    this.duration = const Duration(seconds: 30),
  });

  final String label;
  final List<String> messages;
  final bool compact;
  final EdgeInsetsGeometry margin;
  final EdgeInsets safeAreaMinimum;
  final Duration duration;

  @override
  State<NewsTickerBar> createState() => _NewsTickerBarState();
}

class _NewsTickerBarState extends State<NewsTickerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTickerMotion();
  }

  @override
  void didUpdateWidget(covariant NewsTickerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    _syncTickerMotion();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncTickerMotion() {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shouldAnimate = TickerMode.valuesOf(context).enabled && !reduceMotion;

    if (shouldAnimate) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
      return;
    }

    _controller.stop();
    _controller.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.messages
        .map((message) => message.trim())
        .where((message) => message.isNotEmpty)
        .toList();
    final tickerText = messages.join('     /     ');
    final height = widget.compact ? 34.0 : 38.0;
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w900,
      fontSize: widget.compact ? 11 : 12,
      letterSpacing: 0.6,
    );
    final messageStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w800,
      fontSize: widget.compact ? 12.5 : 13.5,
      letterSpacing: 0,
    );

    return SafeArea(
      top: false,
      minimum: widget.safeAreaMinimum,
      child: Padding(
        padding: widget.margin,
        child: Semantics(
          label: '${widget.label}: $tickerText',
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: AppTheme.pressRed,
              border: Border(
                top: BorderSide(
                  color: AppTheme.midnight.withValues(alpha: 0.28),
                ),
                bottom: BorderSide(
                  color: AppTheme.midnight.withValues(alpha: 0.28),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.midnight.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.compact ? 12 : 14,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.midnight,
                    border: Border(
                      right: BorderSide(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                  child: Text(widget.label, style: labelStyle),
                ),
                Expanded(
                  child: _ScrollingNewsText(
                    text: tickerText,
                    style: messageStyle,
                    controller: _controller,
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

class _ScrollingNewsText extends StatelessWidget {
  const _ScrollingNewsText({
    required this.text,
    required this.style,
    required this.controller,
  });

  final String text;
  final TextStyle? style;
  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final textScaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (reduceMotion) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          );
        }

        final textWidth = _measureTextWidth(
          context: context,
          text: text,
          style: style,
          textScaler: textScaler,
        );

        return ClipRect(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final travelDistance = constraints.maxWidth + textWidth + 48;
              final x =
                  constraints.maxWidth +
                  24 -
                  (controller.value * travelDistance);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: x,
                    top: 0,
                    bottom: 0,
                    width: textWidth,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        text,
                        maxLines: 1,
                        softWrap: false,
                        style: style,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  double _measureTextWidth({
    required BuildContext context,
    required String text,
    required TextStyle? style,
    required TextScaler textScaler,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: textScaler,
    )..layout();

    return painter.width;
  }
}
