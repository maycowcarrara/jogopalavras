import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jogopalavras/src/core/audio/game_music_service.dart';
import 'package:jogopalavras/src/game/hint_display_preferences.dart';
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
                        if (showOptionsControl ||
                            action != topRightActions.last)
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
  HintDisplayMode _hintDisplayMode = HintDisplayPreferences.instance.mode;

  @override
  void initState() {
    super.initState();
    _syncMusicState();
  }

  Future<void> _syncMusicState() async {
    await GameMusicService.instance.initialize();
    await HintDisplayPreferences.instance.initialize();
    if (!mounted) {
      return;
    }
    setState(() {
      _musicEnabled = GameMusicService.instance.enabled;
      _effectsEnabled = GameMusicService.instance.effectsEnabled;
      _musicVolume = GameMusicService.instance.volume;
      _hintDisplayMode = HintDisplayPreferences.instance.mode;
    });
  }

  Future<void> _setHintDisplayMode(HintDisplayMode mode) async {
    setState(() {
      _hintDisplayMode = mode;
    });
    await HintDisplayPreferences.instance.setMode(mode);
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
      hintDisplayMode: _hintDisplayMode,
      dark: widget.dark,
      onSync: _syncMusicState,
      onToggleMusic: _toggleMusic,
      onToggleEffects: _toggleEffects,
      onVolumeChanged: _setVolume,
      onHintDisplayModeChanged: _setHintDisplayMode,
    );
  }
}

class AppOptionsButton extends StatelessWidget {
  const AppOptionsButton({
    super.key,
    required this.enabled,
    required this.effectsEnabled,
    required this.volume,
    required this.hintDisplayMode,
    required this.onToggleMusic,
    required this.onToggleEffects,
    required this.onVolumeChanged,
    required this.onHintDisplayModeChanged,
    this.onSync,
    this.dark = false,
  });

  final bool enabled;
  final bool effectsEnabled;
  final double volume;
  final HintDisplayMode hintDisplayMode;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<HintDisplayMode> onHintDisplayModeChanged;
  final Future<void> Function()? onSync;
  final bool dark;

  IconData get _icon {
    return Icons.settings_rounded;
  }

  Future<void> _showPanel(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _OptionsDialog(
        enabled: enabled,
        effectsEnabled: effectsEnabled,
        volume: volume,
        hintDisplayMode: hintDisplayMode,
        onToggleMusic: onToggleMusic,
        onToggleEffects: onToggleEffects,
        onVolumeChanged: onVolumeChanged,
        onHintDisplayModeChanged: onHintDisplayModeChanged,
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
    required this.hintDisplayMode,
    required this.onToggleMusic,
    required this.onToggleEffects,
    required this.onVolumeChanged,
    required this.onHintDisplayModeChanged,
  });

  final bool enabled;
  final bool effectsEnabled;
  final double volume;
  final HintDisplayMode hintDisplayMode;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<HintDisplayMode> onHintDisplayModeChanged;

  @override
  State<_OptionsDialog> createState() => _OptionsDialogState();
}

class _OptionsDialogState extends State<_OptionsDialog> {
  late bool _musicEnabled = widget.enabled;
  late bool _effectsEnabled = widget.effectsEnabled;
  late double _volume = widget.volume;
  late HintDisplayMode _hintDisplayMode = widget.hintDisplayMode;
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
      InitialsUpdateStatus.invalid => 'Use de 3 a 6 letras ou números.',
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
    final validLength =
        _draftInitials.length >= 3 && _draftInitials.length <= 6;
    final changed = _draftInitials != _currentInitials;
    final locked = _currentInitials.isNotEmpty && _cooldown != null && changed;
    return validLength && changed && !locked && !_savingInitials;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.card,
            border: Border.all(color: AppTheme.rule),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.midnight.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OptionsHeader(onClose: () => Navigator.of(context).pop()),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _OptionsCard(
                          icon: Icons.article_outlined,
                          title: 'Dica',
                          subtitle: 'Escolha como a pista aparece no jogo.',
                          child: SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<HintDisplayMode>(
                              showSelectedIcon: false,
                              style: _segmentedButtonStyle(),
                              segments: [
                                for (final mode in HintDisplayMode.values)
                                  ButtonSegment<HintDisplayMode>(
                                    value: mode,
                                    label: Text(mode.label),
                                  ),
                              ],
                              selected: {_hintDisplayMode},
                              onSelectionChanged: (selection) {
                                final mode = selection.first;
                                setState(() => _hintDisplayMode = mode);
                                widget.onHintDisplayModeChanged(mode);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _OptionsCard(
                          icon: Icons.volume_up_rounded,
                          title: 'Som',
                          subtitle: _musicEnabled
                              ? 'Trilha em ${(_volume * 100).round()}%.'
                              : 'Trilha desligada.',
                          child: Column(
                            children: [
                              _OptionSwitchRow(
                                icon: _musicEnabled
                                    ? Icons.music_note_rounded
                                    : Icons.music_off_rounded,
                                title: 'Música',
                                subtitle: 'Liga ou pausa a trilha de fundo.',
                                value: _musicEnabled,
                                onChanged: (value) {
                                  setState(() => _musicEnabled = value);
                                  widget.onToggleMusic();
                                },
                              ),
                              const SizedBox(height: 10),
                              _VolumeControl(
                                volume: _volume,
                                enabled: _musicEnabled,
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
                              const SizedBox(height: 10),
                              _OptionSwitchRow(
                                icon: _effectsEnabled
                                    ? Icons.auto_awesome_rounded
                                    : Icons.motion_photos_off_rounded,
                                title: 'Efeitos',
                                subtitle:
                                    'Animações e pequenos retornos visuais.',
                                value: _effectsEnabled,
                                onChanged: (value) {
                                  setState(() => _effectsEnabled = value);
                                  widget.onToggleEffects();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _OptionsCard(
                          icon: Icons.badge_rounded,
                          title: 'Ranking',
                          subtitle: _currentInitials.isEmpty
                              ? 'Crie uma assinatura para disputar posições.'
                              : 'Sua assinatura aparece nos placares.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _initialsController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                maxLength: 6,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp('[a-zA-Z0-9]'),
                                  ),
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.62,
                                  ),
                                  labelText: _currentInitials.isEmpty
                                      ? 'Criar assinatura'
                                      : 'Assinatura',
                                  helperText:
                                      _currentInitials.isNotEmpty &&
                                          _cooldown != null
                                      ? 'Nova troca em ${_formatCooldown(_cooldown)}'
                                      : 'Use de 3 a 6 letras ou números',
                                  prefixIcon: const Icon(
                                    Icons.edit_note_rounded,
                                    color: AppTheme.pressBlue,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: AppTheme.rule,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: AppTheme.pressBlue,
                                      width: 1.4,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onChanged: _handleInitialsChanged,
                              ),
                              if (_initialsMessage != null) ...[
                                const SizedBox(height: 8),
                                _InitialsMessage(
                                  message: _initialsMessage!,
                                  success:
                                      _initialsMessage == 'Assinatura salva.',
                                ),
                              ],
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _canSaveInitials
                                      ? _saveInitials
                                      : null,
                                  icon: _savingInitials
                                      ? const SizedBox.square(
                                          dimension: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.save_rounded,
                                          size: 18,
                                        ),
                                  label: const Text('Salvar assinatura'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _segmentedButtonStyle() {
    return SegmentedButton.styleFrom(
      backgroundColor: Colors.white.withValues(alpha: 0.48),
      selectedBackgroundColor: AppTheme.pressBlue.withValues(alpha: 0.14),
      selectedForegroundColor: AppTheme.pressBlue,
      foregroundColor: AppTheme.ink,
      side: const BorderSide(color: AppTheme.rule),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
    );
  }
}

class _OptionsHeader extends StatelessWidget {
  const _OptionsHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.midnight,
        border: Border(
          bottom: BorderSide(color: AppTheme.pressGold.withValues(alpha: 0.55)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        child: Row(
          children: [
            const _OptionsIconBadge(
              icon: Icons.settings_rounded,
              background: Colors.white,
              foreground: AppTheme.midnight,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Opções',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Som, dicas e ranking em um só lugar.',
                    style: TextStyle(
                      color: Color(0xFFECE4D7),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Fechar',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionsCard extends StatelessWidget {
  const _OptionsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.42),
        border: Border.all(color: AppTheme.rule.withValues(alpha: 0.86)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OptionsIconBadge(icon: icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.midnight,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.ink.withValues(alpha: 0.72),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          height: 1.18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _OptionsIconBadge extends StatelessWidget {
  const _OptionsIconBadge({
    required this.icon,
    this.background,
    this.foreground = AppTheme.pressBlue,
  });

  final IconData icon;
  final Color? background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? AppTheme.pressBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: SizedBox.square(
        dimension: 34,
        child: Icon(icon, color: foreground, size: 19),
      ),
    );
  }
}

class _OptionSwitchRow extends StatelessWidget {
  const _OptionSwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 32,
              child: Icon(icon, color: AppTheme.pressBlue, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.midnight,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.ink.withValues(alpha: 0.68),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _VolumeControl extends StatelessWidget {
  const _VolumeControl({
    required this.volume,
    required this.enabled,
    required this.onChanged,
  });

  final double volume;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final percent = (volume * 100).round();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.newsprint.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
        child: Row(
          children: [
            Icon(
              enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: enabled
                  ? AppTheme.pressBlue
                  : AppTheme.ink.withValues(alpha: 0.45),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(value: volume, onChanged: onChanged),
            ),
            SizedBox(
              width: 42,
              child: Text(
                '$percent%',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppTheme.ink.withValues(alpha: enabled ? 0.84 : 0.5),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialsMessage extends StatelessWidget {
  const _InitialsMessage({required this.message, required this.success});

  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = success ? AppTheme.pressGreen : AppTheme.pressRed;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.42)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.info_rounded,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  height: 1.18,
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
