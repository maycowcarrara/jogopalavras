import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jogopalavras/src/core/audio/game_music_service.dart';
import 'package:jogopalavras/src/game/ranking_store.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({
    super.key,
    required this.child,
    this.primary = AppTheme.pressBlue,
    this.secondary = AppTheme.pressRed,
    this.showOptionsControl = true,
    this.topRightActions = const [],
  });

  final Widget child;
  final Color primary;
  final Color secondary;
  final bool showOptionsControl;
  final List<Widget> topRightActions;

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
          if (showOptionsControl || topRightActions.isNotEmpty)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final action in topRightActions) ...[
                        action,
                        if (showOptionsControl || action != topRightActions.last)
                          const SizedBox(width: 8),
                      ],
                      if (showOptionsControl) const AppOptionsControl(),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AppOptionsControl extends StatefulWidget {
  const AppOptionsControl({super.key, this.dark = false});

  final bool dark;

  @override
  State<AppOptionsControl> createState() => _AppOptionsControlState();
}

class _AppOptionsControlState extends State<AppOptionsControl> {
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
    return AppOptionsButton(
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

class AppOptionsButton extends StatelessWidget {
  const AppOptionsButton({
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
    return Icons.settings_rounded;
  }

  Future<void> _showPanel(BuildContext context) async {
    await onSync?.call();
    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => _OptionsDialog(
        enabled: enabled,
        effectsEnabled: effectsEnabled,
        volume: volume,
        onToggleMusic: onToggleMusic,
        onToggleEffects: onToggleEffects,
        onVolumeChanged: onVolumeChanged,
      ),
    );

    await onSync?.call();
  }

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : AppTheme.pressBlue;
    final background = dark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.96);

    return Semantics(
      button: true,
      label: 'Opções',
      child: Tooltip(
        message: 'Opções',
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(8),
          elevation: dark ? 0 : 10,
          shadowColor: AppTheme.midnight.withValues(alpha: 0.28),
          child: InkWell(
            key: const ValueKey<String>('app_options_button'),
            onTap: () => _showPanel(context),
            borderRadius: BorderRadius.circular(8),
            child: SizedBox.square(
              dimension: dark ? 44 : 42,
              child: Icon(_icon, color: foreground, size: dark ? 23 : 21),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionsDialog extends StatefulWidget {
  const _OptionsDialog({
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
  State<_OptionsDialog> createState() => _OptionsDialogState();
}

class _OptionsDialogState extends State<_OptionsDialog> {
  late bool _musicEnabled = widget.enabled;
  late bool _effectsEnabled = widget.effectsEnabled;
  late double _volume = widget.volume;
  late final TextEditingController _initialsController =
      TextEditingController();
  String _currentInitials = '';
  String _draftInitials = '';
  Duration? _cooldown;
  bool _savingInitials = false;
  String? _initialsMessage;

  @override
  void initState() {
    super.initState();
    _loadSignature();
  }

  @override
  void dispose() {
    _initialsController.dispose();
    super.dispose();
  }

  Future<void> _loadSignature() async {
    final initials = await RankingStore.instance.loadLastInitials();
    final cooldown = await RankingStore.instance.remainingInitialsCooldown();
    if (!mounted) {
      return;
    }

    _initialsController.text = initials;
    _initialsController.selection = TextSelection.collapsed(
      offset: initials.length,
    );
    setState(() {
      _currentInitials = initials;
      _draftInitials = initials;
      _cooldown = cooldown;
    });
  }

  void _handleInitialsChanged(String value) {
    final nextInitials = value.toUpperCase();
    if (_initialsController.text != nextInitials) {
      _initialsController.value = TextEditingValue(
        text: nextInitials,
        selection: TextSelection.collapsed(offset: nextInitials.length),
      );
    }

    setState(() {
      _draftInitials = nextInitials;
      _initialsMessage = null;
    });
  }

  Future<void> _saveInitials() async {
    setState(() {
      _savingInitials = true;
      _initialsMessage = null;
    });

    final result = await RankingStore.instance.updatePlayerInitials(
      _draftInitials,
    );
    final cooldown = await RankingStore.instance.remainingInitialsCooldown();
    if (!mounted) {
      return;
    }

    setState(() {
      _savingInitials = false;
      _cooldown = cooldown;
      if (result.saved) {
        final savedInitials = result.initials ?? _draftInitials;
        _currentInitials = savedInitials;
        _draftInitials = savedInitials;
        _initialsController.text = savedInitials;
        _initialsController.selection = TextSelection.collapsed(
          offset: savedInitials.length,
        );
        _initialsMessage = 'Assinatura salva.';
      } else {
        _initialsMessage = _messageForInitialsResult(result);
      }
    });
  }

  String _messageForInitialsResult(InitialsUpdateResult result) {
    return switch (result.status) {
      InitialsUpdateStatus.invalid => 'Use de 3 a 5 letras.',
      InitialsUpdateStatus.unavailable =>
        'Essa assinatura já está em uso no ranking.',
      InitialsUpdateStatus.cooldown =>
        'Você poderá alterar novamente em ${_formatCooldown(result.remainingCooldown)}.',
      InitialsUpdateStatus.saved => 'Assinatura salva.',
    };
  }

  String _formatCooldown(Duration? duration) {
    if (duration == null || duration.isNegative) {
      return 'breve';
    }

    final days = duration.inDays + (duration.inHours % 24 > 0 ? 1 : 0);
    if (days <= 1) {
      return '1 dia';
    }

    return '$days dias';
  }

  bool get _canSaveInitials {
    final validLength = _draftInitials.length >= 3 && _draftInitials.length <= 5;
    final changed = _draftInitials != _currentInitials;
    final locked = _currentInitials.isNotEmpty && _cooldown != null && changed;
    return validLength && changed && !locked && !_savingInitials;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.rule),
        borderRadius: BorderRadius.circular(12),
      ),
      title: const Text(
        'Opções',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _OptionsSectionTitle(
                icon: Icons.volume_up_rounded,
                label: 'Som',
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text(
                  'Música',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                value: _musicEnabled,
                onChanged: (value) {
                  setState(() => _musicEnabled = value);
                  widget.onToggleMusic();
                },
              ),
              Row(
                children: [
                  const SizedBox(
                    width: 28,
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: AppTheme.pressBlue,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      onChanged: (value) {
                        setState(() {
                          _volume = value;
                          if (value > 0) {
                            _musicEnabled = true;
                          }
                        });
                        widget.onVolumeChanged(value);
                      },
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text(
                  'Efeitos',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                value: _effectsEnabled,
                onChanged: (value) {
                  setState(() => _effectsEnabled = value);
                  widget.onToggleEffects();
                },
              ),
              const Divider(height: 24),
              const _OptionsSectionTitle(
                icon: Icons.badge_rounded,
                label: 'Ranking',
              ),
              TextField(
                controller: _initialsController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 5,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                  LengthLimitingTextInputFormatter(5),
                ],
                decoration: InputDecoration(
                  counterText: '',
                  labelText: _currentInitials.isEmpty
                      ? 'Criar assinatura'
                      : 'Assinatura',
                  helperText: _currentInitials.isNotEmpty && _cooldown != null
                      ? 'Nova troca em ${_formatCooldown(_cooldown)}'
                      : 'Use de 3 a 5 letras',
                  border: const OutlineInputBorder(),
                ),
                onChanged: _handleInitialsChanged,
              ),
              if (_initialsMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _initialsMessage!,
                  style: TextStyle(
                    color: _initialsMessage == 'Assinatura salva.'
                        ? AppTheme.pressGreen
                        : AppTheme.pressRed,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _canSaveInitials ? _saveInitials : null,
                  icon: _savingInitials
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Salvar assinatura'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class _OptionsSectionTitle extends StatelessWidget {
  const _OptionsSectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.pressBlue, size: 19),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.midnight,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
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
