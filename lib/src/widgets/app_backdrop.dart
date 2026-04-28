import 'package:flutter/material.dart';
import 'package:jogopalavras/src/core/audio/game_music_service.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';

class AppBackdrop extends StatefulWidget {
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
  State<AppBackdrop> createState() => _AppBackdropState();
}

class _AppBackdropState extends State<AppBackdrop> {
  bool _musicEnabled = GameMusicService.instance.enabled;
  bool _effectsEnabled = GameMusicService.instance.effectsEnabled;
  double _musicVolume = GameMusicService.instance.volume;

  @override
  void initState() {
    super.initState();
    _syncMusicState();
  }

  Future<void> _syncMusicState() async {
    await GameMusicService.instance.initialize();
    if (!mounted) {
      return;
    }
    setState(() {
      _musicEnabled = GameMusicService.instance.enabled;
      _effectsEnabled = GameMusicService.instance.effectsEnabled;
      _musicVolume = GameMusicService.instance.volume;
    });
  }

  Future<void> _toggleMusic() async {
    final nextValue = !_musicEnabled;
    setState(() {
      _musicEnabled = nextValue;
    });
    await GameMusicService.instance.setEnabled(nextValue);
    if (!mounted) {
      return;
    }
    setState(() {
      _musicEnabled = GameMusicService.instance.enabled;
      _effectsEnabled = GameMusicService.instance.effectsEnabled;
      _musicVolume = GameMusicService.instance.volume;
    });
  }

  Future<void> _toggleEffects() async {
    final nextValue = !_effectsEnabled;
    setState(() {
      _effectsEnabled = nextValue;
    });
    await GameMusicService.instance.setEffectsEnabled(nextValue);
    if (!mounted) {
      return;
    }
    setState(() {
      _effectsEnabled = GameMusicService.instance.effectsEnabled;
    });
  }

  Future<void> _setVolume(double value) async {
    setState(() {
      _musicVolume = value;
      if (!_musicEnabled && value > 0) {
        _musicEnabled = true;
      }
    });

    if (!GameMusicService.instance.enabled && value > 0) {
      await GameMusicService.instance.setEnabled(true);
    }
    await GameMusicService.instance.setVolume(value);

    if (!mounted) {
      return;
    }
    setState(() {
      _musicEnabled = GameMusicService.instance.enabled;
      _effectsEnabled = GameMusicService.instance.effectsEnabled;
      _musicVolume = GameMusicService.instance.volume;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppTheme.cream),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _NewsprintPainter(
                primary: widget.primary,
                secondary: widget.secondary,
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
          widget.child,
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: _BackdropMusicControl(
                  enabled: _musicEnabled,
                  effectsEnabled: _effectsEnabled,
                  volume: _musicVolume,
                  onToggleMusic: _toggleMusic,
                  onToggleEffects: _toggleEffects,
                  onVolumeChanged: _setVolume,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropMusicControl extends StatelessWidget {
  const _BackdropMusicControl({
    required this.enabled,
    required this.effectsEnabled,
    required this.volume,
    required this.onToggleMusic,
    required this.onToggleEffects,
    required this.onVolumeChanged,
  });

  final bool enabled;
  final bool effectsEnabled;
  final double volume;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;
  final ValueChanged<double> onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Controle de musica',
      child: Material(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(999),
        elevation: 10,
        shadowColor: AppTheme.midnight.withValues(alpha: 0.28),
        child: SizedBox(
          width: 218,
          height: 50,
          child: Row(
            children: [
              Tooltip(
                message: enabled ? 'Desligar música' : 'Ligar música',
                child: InkWell(
                  onTap: onToggleMusic,
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox.square(
                    dimension: 50,
                    child: Icon(
                      enabled
                          ? volume > 0.55
                                ? Icons.volume_up_rounded
                                : Icons.volume_down_rounded
                          : Icons.volume_off_rounded,
                      color: enabled ? AppTheme.pressBlue : AppTheme.midnight,
                      size: 25,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    activeTrackColor: AppTheme.pressBlue,
                    inactiveTrackColor: AppTheme.rule,
                    thumbColor: AppTheme.pressBlue,
                    overlayColor: AppTheme.pressBlue.withValues(alpha: 0.12),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                  ),
                  child: Slider(value: volume, onChanged: onVolumeChanged),
                ),
              ),
              Tooltip(
                message: effectsEnabled ? 'Desligar efeitos' : 'Ligar efeitos',
                child: InkWell(
                  onTap: onToggleEffects,
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox.square(
                    dimension: 42,
                    child: Icon(
                      effectsEnabled
                          ? Icons.auto_awesome_rounded
                          : Icons.do_not_disturb_on_rounded,
                      color: effectsEnabled
                          ? AppTheme.pressGold
                          : AppTheme.midnight.withValues(alpha: 0.7),
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
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
