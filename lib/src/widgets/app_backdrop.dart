import 'package:flutter/material.dart';
import 'package:jogopalavras/src/core/audio/game_music_service.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({
    super.key,
    required this.child,
    this.primary = AppTheme.pressBlue,
    this.secondary = AppTheme.pressRed,
    this.showAudioControl = true,
  });

  final Widget child;
  final Color primary;
  final Color secondary;
  final bool showAudioControl;

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
          if (showAudioControl)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                  child: AppAudioControl(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AppAudioControl extends StatefulWidget {
  const AppAudioControl({super.key, this.dark = false});

  final bool dark;

  @override
  State<AppAudioControl> createState() => _AppAudioControlState();
}

class _AppAudioControlState extends State<AppAudioControl> {
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
    await _syncMusicState();
  }

  Future<void> _toggleEffects() async {
    final nextValue = !_effectsEnabled;
    setState(() {
      _effectsEnabled = nextValue;
    });
    await GameMusicService.instance.setEffectsEnabled(nextValue);
    await _syncMusicState();
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
    await _syncMusicState();
  }

  @override
  Widget build(BuildContext context) {
    return AppAudioControlButton(
      enabled: _musicEnabled,
      effectsEnabled: _effectsEnabled,
      volume: _musicVolume,
      dark: widget.dark,
      onSync: _syncMusicState,
      onToggleMusic: _toggleMusic,
      onToggleEffects: _toggleEffects,
      onVolumeChanged: _setVolume,
    );
  }
}

class AppAudioControlButton extends StatelessWidget {
  const AppAudioControlButton({
    super.key,
    required this.enabled,
    required this.effectsEnabled,
    required this.volume,
    required this.onToggleMusic,
    required this.onToggleEffects,
    required this.onVolumeChanged,
    this.onSync,
    this.dark = false,
  });

  final bool enabled;
  final bool effectsEnabled;
  final double volume;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;
  final ValueChanged<double> onVolumeChanged;
  final Future<void> Function()? onSync;
  final bool dark;

  IconData get _icon {
    if (!enabled) {
      return Icons.volume_off_rounded;
    }

    return volume > 0.55 ? Icons.volume_up_rounded : Icons.volume_down_rounded;
  }

  Future<void> _showPanel(BuildContext context) async {
    final buttonBox = context.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final buttonOffset =
        buttonBox?.localToGlobal(Offset.zero, ancestor: overlayBox) ??
        Offset.zero;
    final buttonSize = buttonBox?.size ?? const Size(42, 42);

    onSync?.call();

    await showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        var panelMusicEnabled = enabled;
        var panelEffectsEnabled = effectsEnabled;
        var panelVolume = volume;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final screenWidth = MediaQuery.sizeOf(context).width;
            final right = (screenWidth - buttonOffset.dx - buttonSize.width)
                .clamp(8.0, screenWidth);

            return Stack(
              children: [
                Positioned(
                  top: buttonOffset.dy + buttonSize.height + 8,
                  right: right,
                  child: Material(
                    color: Colors.transparent,
                    child: _AudioControlPanel(
                      enabled: panelMusicEnabled,
                      effectsEnabled: panelEffectsEnabled,
                      volume: panelVolume,
                      onToggleMusic: () {
                        final nextValue = !panelMusicEnabled;
                        setDialogState(() {
                          panelMusicEnabled = nextValue;
                        });
                        onToggleMusic();
                      },
                      onToggleEffects: () {
                        final nextValue = !panelEffectsEnabled;
                        setDialogState(() {
                          panelEffectsEnabled = nextValue;
                        });
                        onToggleEffects();
                      },
                      onVolumeChanged: (value) {
                        setDialogState(() {
                          panelVolume = value;
                          if (value > 0) {
                            panelMusicEnabled = true;
                          }
                        });
                        onVolumeChanged(value);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 120),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : AppTheme.pressBlue;
    final background = dark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.96);

    return Semantics(
      button: true,
      label: 'Controle de audio',
      child: Tooltip(
        message: 'Áudio',
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(8),
          elevation: dark ? 0 : 10,
          shadowColor: AppTheme.midnight.withValues(alpha: 0.28),
          child: InkWell(
            key: const ValueKey<String>('app_audio_control_button'),
            onTap: () => _showPanel(context),
            borderRadius: BorderRadius.circular(8),
            child: SizedBox.square(
              dimension: dark ? 40 : 42,
              child: Icon(_icon, color: foreground, size: 21),
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioControlPanel extends StatelessWidget {
  const _AudioControlPanel({
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.rule),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: 184,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AudioPanelButton(
                icon: enabled
                    ? Icons.music_note_rounded
                    : Icons.music_off_rounded,
                label: enabled ? 'Música' : 'Música mute',
                active: enabled,
                onTap: onToggleMusic,
              ),
              SizedBox(
                height: 36,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 34,
                      child: Icon(
                        Icons.volume_up_rounded,
                        color: AppTheme.pressBlue,
                        size: 18,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          activeTrackColor: AppTheme.pressBlue,
                          inactiveTrackColor: AppTheme.rule,
                          thumbColor: AppTheme.pressBlue,
                          overlayColor: AppTheme.pressBlue.withValues(
                            alpha: 0.12,
                          ),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                        ),
                        child: Slider(value: volume, onChanged: onVolumeChanged),
                      ),
                    ),
                  ],
                ),
              ),
              _AudioPanelButton(
                icon: effectsEnabled
                    ? Icons.auto_awesome_rounded
                    : Icons.do_not_disturb_on_rounded,
                label: effectsEnabled ? 'Efeitos' : 'Efeitos mute',
                active: effectsEnabled,
                onTap: onToggleEffects,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioPanelButton extends StatelessWidget {
  const _AudioPanelButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 34,
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Icon(
                icon,
                color: active
                    ? AppTheme.pressBlue
                    : AppTheme.midnight.withValues(alpha: 0.64),
                size: 18,
              ),
            ),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.midnight.withValues(alpha: 0.86),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
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
