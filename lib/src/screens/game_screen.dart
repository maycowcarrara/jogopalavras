import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jogopalavras/src/core/ads/ad_service.dart';
import 'package:jogopalavras/src/core/audio/game_music_service.dart';
import 'package:jogopalavras/src/game/game_level.dart';
import 'package:jogopalavras/src/game/word_bank.dart';
import 'package:jogopalavras/src/game/word_deck.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';
import 'package:jogopalavras/src/widgets/ad_banner_slot.dart';
import 'package:jogopalavras/src/widgets/app_backdrop.dart';
import 'package:jogopalavras/src/widgets/reveal_on_mount.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level});

  final GameLevel level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  static const int _goalScore = 100;
  static const int _pointsPerHit = 10;
  static const int _pointsPerHintHit = 6;
  static const int _pointsPerError = 5;
  static const int _progressFragments = 10;
  static const Duration _hintDelay = Duration(seconds: 22);

  late final WordDeck<WordEntry> _wordDeck;
  late final Random _random;
  Timer? _hintTimer;

  List<String> _grid = <String>[];
  List<int> _selectedIndices = <int>[];
  List<String> _discoveredWords = <String>[];
  String _currentWord = '';
  String _targetWord = '';
  String _currentHint = '';
  int _score = 0;
  int _roundErrors = 0;
  bool _hasError = false;
  bool _hintSuggested = false;
  bool _hintRevealed = false;
  bool _musicEnabled = true;
  Offset? _dragPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _random = Random();
    _wordDeck = WordDeck(wordBank[widget.level]!, random: _random);
    _musicEnabled = GameMusicService.instance.enabled;
    _generateRound();
    _startMusic();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    GameMusicService.instance.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeMusic();
      return;
    }

    GameMusicService.instance.pause();
  }

  Future<void> _startMusic() async {
    await GameMusicService.instance.playForLevel(widget.level);
  }

  Future<void> _resumeMusic() async {
    await GameMusicService.instance.resume(widget.level);
  }

  Future<void> _toggleMusic() async {
    final nextValue = !_musicEnabled;
    setState(() {
      _musicEnabled = nextValue;
    });
    await GameMusicService.instance.setEnabled(
      nextValue,
      fallbackLevel: widget.level,
    );
  }

  void _generateRound() {
    _hintTimer?.cancel();
    final nextEntry = _wordDeck.nextWord();
    final nextWord = nextEntry.text;
    final totalCells = widget.level.gridSize * widget.level.gridSize;
    final nextGrid = List<String>.filled(totalCells, '');
    final positions = List<int>.generate(totalCells, (index) => index)
      ..shuffle(_random);

    for (var i = 0; i < nextWord.length; i++) {
      nextGrid[positions[i]] = nextWord[i];
    }

    setState(() {
      _targetWord = nextWord;
      _currentHint = nextEntry.hint;
      _grid = nextGrid;
      _selectedIndices = <int>[];
      _currentWord = '';
      _dragPosition = null;
      _hasError = false;
      _roundErrors = 0;
      _hintSuggested = false;
      _hintRevealed = false;
    });
    _scheduleHintPrompt();
  }

  void _scheduleHintPrompt() {
    _hintTimer = Timer(_hintDelay, () {
      if (!mounted || _hintRevealed) {
        return;
      }

      setState(() {
        _hintSuggested = true;
      });
    });
  }

  void _revealHint() {
    if (_hintRevealed || _currentHint.isEmpty) {
      return;
    }

    _hintTimer?.cancel();
    setState(() {
      _hintRevealed = true;
      _hintSuggested = false;
    });
  }

  void _handleDrag(Offset localPosition, _BoardMetrics metrics) {
    final index = metrics.indexFor(localPosition);

    setState(() {
      _dragPosition = localPosition;

      if (index == null ||
          _grid[index].isEmpty ||
          _selectedIndices.contains(index)) {
        return;
      }

      _selectedIndices = [..._selectedIndices, index];
      _currentWord += _grid[index];
      _hasError = false;
    });
  }

  Future<void> _onDragEnd() async {
    if (_currentWord.isEmpty) {
      setState(() => _dragPosition = null);
      return;
    }

    if (_currentWord == _targetWord) {
      final earnedPoints = _hintRevealed ? _pointsPerHintHit : _pointsPerHit;
      setState(() {
        _dragPosition = null;
        _score += earnedPoints;
        _discoveredWords = [_targetWord, ..._discoveredWords];
      });

      if (_score >= _goalScore) {
        _hintTimer?.cancel();
        await _showVictoryDialog();
      } else {
        _generateRound();
      }
      return;
    }

    setState(() {
      _dragPosition = null;
      _score = max(0, _score - _pointsPerError);
      _hasError = true;
      _roundErrors += 1;
      _hintSuggested = _hintSuggested || (!_hintRevealed && _roundErrors >= 2);
      _selectedIndices = <int>[];
      _currentWord = '';
    });
  }

  Future<void> _showVictoryDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppTheme.card,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppTheme.rule),
            borderRadius: BorderRadius.circular(12),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.pressRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Você venceu!',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: Text(
            'Você encontrou ${_discoveredWords.length} palavras e somou $_score pontos. Quer começar outra rodada?',
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context)
                ..pop()
                ..pop(),
              child: const Text('Voltar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AdService.instance.registerNaturalBreak();
                if (!mounted) {
                  return;
                }
                setState(() {
                  _score = 0;
                  _discoveredWords = <String>[];
                  _currentWord = '';
                  _selectedIndices = <int>[];
                  _dragPosition = null;
                  _hasError = false;
                  _roundErrors = 0;
                  _hintSuggested = false;
                  _hintRevealed = false;
                });
                _generateRound();
              },
              child: const Text('Jogar de novo'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_score / _goalScore).clamp(0.0, 1.0);
    final revealedFragments = _score <= 0
        ? 0
        : ((_score / _goalScore) * _progressFragments).ceil().clamp(
            0,
            _progressFragments,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            AppBackdrop(
              primary: widget.level.accent,
              secondary: AppTheme.pressRed,
              child: const SizedBox.expand(),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.midnight.withValues(alpha: 0.08),
                      AppTheme.pressRed.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.38, 1],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final layout = _GameLayoutMetrics.fromConstraints(
                    constraints,
                    gridSize: widget.level.gridSize,
                  );

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      layout.horizontalPadding,
                      layout.topPadding,
                      layout.horizontalPadding,
                      layout.bottomPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RevealOnMount(
                          child: _GameHeader(
                            level: widget.level,
                            score: _score,
                            progress: progress,
                            compact: layout.compact,
                            prioritizeBoard: layout.prioritizeBoard,
                          ),
                        ),
                        SizedBox(height: layout.sectionGap),
                        RevealOnMount(
                          delay: const Duration(milliseconds: 80),
                          child: SizedBox(
                            height: layout.showcaseHeight,
                            child: _RoundShowcaseCard(
                              level: widget.level,
                              currentWord: _currentWord,
                              targetWordLength: _targetWord.length,
                              hint: _currentHint,
                              hintSuggested: _hintSuggested,
                              hintRevealed: _hintRevealed,
                              hintedHitPoints: _pointsPerHintHit,
                              hasError: _hasError,
                              revealedFragments: revealedFragments,
                              totalFragments: _progressFragments,
                              discoveredCount: _discoveredWords.length,
                              compact: layout.compact,
                              musicEnabled: _musicEnabled,
                              onToggleMusic: _toggleMusic,
                              onRevealHint: _revealHint,
                            ),
                          ),
                        ),
                        SizedBox(height: layout.sectionGap),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, contentConstraints) {
                              final boardSize = min(
                                contentConstraints.maxWidth,
                                contentConstraints.maxHeight,
                              );

                              return Padding(
                                padding: EdgeInsets.only(
                                  top: layout.boardTopInset,
                                ),
                                child: RevealOnMount(
                                  delay: const Duration(milliseconds: 150),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: SizedBox.square(
                                      dimension: boardSize,
                                      child: _GridBoard(
                                        grid: _grid,
                                        selectedIndices: _selectedIndices,
                                        hasError: _hasError,
                                        dragPosition: _dragPosition,
                                        gridSize: widget.level.gridSize,
                                        accent: widget.level.accent,
                                        compact: layout.compact,
                                        onPanStart: _handleDrag,
                                        onPanUpdate: _handleDrag,
                                        onPanEnd: _onDragEnd,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        AdBannerSlot(compact: layout.compact),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.level,
    required this.score,
    required this.progress,
    required this.compact,
    required this.prioritizeBoard,
  });

  final GameLevel level;
  final int score;
  final double progress;
  final bool compact;
  final bool prioritizeBoard;

  @override
  Widget build(BuildContext context) {
    final padding = prioritizeBoard
        ? 12.0
        : compact
        ? 12.0
        : 14.0;
    final titleSize = prioritizeBoard
        ? 15.0
        : compact
        ? 15.0
        : 17.0;
    final scoreSize = prioritizeBoard
        ? 16.0
        : compact
        ? 17.0
        : 18.0;
    final iconSize = prioritizeBoard
        ? 38.0
        : compact
        ? 42.0
        : 44.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppTheme.midnight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.midnight),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _HeaderBackButton(),
              SizedBox(width: prioritizeBoard ? 8 : 10),
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: level.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(level.icon, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.title,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.96),
                        fontWeight: FontWeight.w900,
                        fontSize: titleSize,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${level.wordSizeShortLabel} • tabuleiro ${level.tag}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                        fontSize: prioritizeBoard ? 12 : null,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderScorePill(
                score: score,
                total: _GameScreenState._goalScore,
                fontSize: scoreSize,
                compact: compact,
              ),
            ],
          ),
          SizedBox(height: prioritizeBoard ? 8 : 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: prioritizeBoard
                  ? 6
                  : compact
                  ? 7
                  : 8,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.pressGold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundShowcaseCard extends StatelessWidget {
  const _RoundShowcaseCard({
    required this.level,
    required this.currentWord,
    required this.targetWordLength,
    required this.hint,
    required this.hintSuggested,
    required this.hintRevealed,
    required this.hintedHitPoints,
    required this.hasError,
    required this.revealedFragments,
    required this.totalFragments,
    required this.discoveredCount,
    required this.compact,
    required this.musicEnabled,
    required this.onToggleMusic,
    required this.onRevealHint,
  });

  final GameLevel level;
  final String currentWord;
  final int targetWordLength;
  final String hint;
  final bool hintSuggested;
  final bool hintRevealed;
  final int hintedHitPoints;
  final bool hasError;
  final int revealedFragments;
  final int totalFragments;
  final int discoveredCount;
  final bool compact;
  final bool musicEnabled;
  final VoidCallback onToggleMusic;
  final VoidCallback onRevealHint;

  @override
  Widget build(BuildContext context) {
    final currentText = List<String>.generate(targetWordLength, (index) {
      if (index < currentWord.length) {
        return currentWord[index];
      }

      return '•';
    }).join(' ');
    final showHintControl = hintSuggested || hintRevealed;

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppTheme.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.rule.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ultraCompact =
              constraints.maxHeight < 126 || constraints.maxWidth < 360;

          if (ultraCompact) {
            return Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              level.sceneTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.midnight,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _MusicToggleButton(
                            enabled: musicEnabled,
                            onPressed: onToggleMusic,
                            size: 34,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          '$currentText  •  $revealedFragments/$totalFragments',
                          key: ValueKey<String>(
                            '$currentText-$revealedFragments',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasError
                                ? AppTheme.pressRed
                                : AppTheme.midnight,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      if (showHintControl) ...[
                        const SizedBox(height: 6),
                        _HintPanel(
                          hint: hint,
                          suggested: hintSuggested,
                          revealed: hintRevealed,
                          hintedHitPoints: hintedHitPoints,
                          compact: true,
                          dense: true,
                          onPressed: onRevealHint,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 74,
                  height: double.infinity,
                  child: _ScenePreview(
                    level: level,
                    revealedFragments: revealedFragments,
                    totalFragments: totalFragments,
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                level.sceneTitle,
                                style: TextStyle(
                                  color: AppTheme.midnight,
                                  fontWeight: FontWeight.w900,
                                  fontSize: compact ? 15 : 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                level.sceneSubtitle,
                                maxLines: compact ? 2 : 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppTheme.ink.withValues(alpha: 0.76),
                                  fontWeight: FontWeight.w600,
                                  fontSize: compact ? 11.5 : 12.5,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (showHintControl)
                                _HintPanel(
                                  hint: hint,
                                  suggested: hintSuggested,
                                  revealed: hintRevealed,
                                  hintedHitPoints: hintedHitPoints,
                                  compact: compact,
                                  onPressed: onRevealHint,
                                )
                              else
                                Text(
                                  musicEnabled
                                      ? 'Trilha: ${level.soundtrackLabel}'
                                      : 'Trilha pausada',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: musicEnabled
                                        ? AppTheme.pressBlue
                                        : AppTheme.ink.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w800,
                                    fontSize: compact ? 11 : 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _MusicToggleButton(
                          enabled: musicEnabled,
                          onPressed: onToggleMusic,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Montagem atual',
                      style: TextStyle(
                        color: AppTheme.ink.withValues(alpha: 0.66),
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 11 : 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        currentText,
                        key: ValueKey<String>(currentText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasError
                              ? AppTheme.pressRed
                              : AppTheme.midnight,
                          fontWeight: FontWeight.w900,
                          fontSize: compact ? 20 : 22,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ShowcasePill(
                          icon: Icons.article_outlined,
                          label: '$revealedFragments/$totalFragments revelados',
                        ),
                        _ShowcasePill(
                          icon: Icons.check_circle_rounded,
                          label: '$discoveredCount acertos',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 12 : 16),
              AspectRatio(
                aspectRatio: 0.9,
                child: SizedBox(
                  width: compact ? 118 : 132,
                  child: _ScenePreview(
                    level: level,
                    revealedFragments: revealedFragments,
                    totalFragments: totalFragments,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HintPanel extends StatelessWidget {
  const _HintPanel({
    required this.hint,
    required this.suggested,
    required this.revealed,
    required this.hintedHitPoints,
    required this.compact,
    required this.onPressed,
    this.dense = false,
  });

  final String hint;
  final bool suggested;
  final bool revealed;
  final int hintedHitPoints;
  final bool compact;
  final bool dense;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (revealed) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10,
          vertical: dense ? 6 : 7,
        ),
        decoration: BoxDecoration(
          color: AppTheme.pressGold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppTheme.pressGold.withValues(alpha: 0.34)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              color: AppTheme.pressGold,
              size: dense ? 13 : 14,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Dica: $hint',
                maxLines: dense ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.midnight,
                  fontWeight: FontWeight.w800,
                  fontSize: dense
                      ? 10.5
                      : compact
                      ? 11
                      : 12,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!suggested) {
      return const SizedBox.shrink();
    }

    return Material(
      color: AppTheme.pressGold.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 8 : 10,
            vertical: dense ? 6 : 7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: AppTheme.pressGold,
                size: dense ? 13 : 14,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Ver dica • +$hintedHitPoints pts',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.midnight,
                    fontWeight: FontWeight.w900,
                    fontSize: dense
                        ? 10.5
                        : compact
                        ? 11
                        : 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScenePreview extends StatelessWidget {
  const _ScenePreview({
    required this.level,
    required this.revealedFragments,
    required this.totalFragments,
  });

  final GameLevel level;
  final int revealedFragments;
  final int totalFragments;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: level.sceneGradient,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.rule.withValues(alpha: 0.68)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CustomPaint(
          painter: _ScenePreviewPainter(
            level: level,
            revealedFragments: revealedFragments,
            totalFragments: totalFragments,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ScenePreviewPainter extends CustomPainter {
  const _ScenePreviewPainter({
    required this.level,
    required this.revealedFragments,
    required this.totalFragments,
  });

  final GameLevel level;
  final int revealedFragments;
  final int totalFragments;

  @override
  void paint(Canvas canvas, Size size) {
    final shinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.32),
          Colors.white.withValues(alpha: 0.04),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, shinePaint);

    final pad = min(10.0, max(6.0, size.shortestSide * 0.12));
    final page = Rect.fromLTWH(
      pad,
      pad,
      max(1.0, size.width - (pad * 2)),
      max(1.0, size.height - (pad * 2)),
    );
    final pageRadius = Radius.circular(max(5.0, size.shortestSide * 0.08));

    canvas.drawRRect(
      RRect.fromRectAndRadius(page, pageRadius),
      Paint()..color = AppTheme.card.withValues(alpha: 0.82),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(page, pageRadius),
      Paint()
        ..color = AppTheme.midnight.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final inner = page.deflate(max(5.0, size.shortestSide * 0.08));
    final headerHeight = max(5.0, inner.height * 0.11);
    final header = Rect.fromLTWH(
      inner.left,
      inner.top,
      inner.width,
      headerHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(header, Radius.circular(headerHeight * 0.42)),
      Paint()..color = level.accent.withValues(alpha: 0.62),
    );

    final storyArea = Rect.fromLTWH(
      inner.left,
      header.bottom + max(5.0, inner.height * 0.06),
      inner.width,
      inner.height * 0.58,
    );
    _drawStoryBlocks(canvas, storyArea);

    final markerArea = Rect.fromLTWH(
      inner.left,
      page.bottom - max(17.0, page.height * 0.2),
      inner.width,
      max(10.0, page.height * 0.12),
    );
    _drawProgressMarkers(canvas, markerArea);
  }

  void _drawStoryBlocks(Canvas canvas, Rect area) {
    final photoWidth = area.width * 0.38;
    final photo = Rect.fromLTWH(
      area.left,
      area.top,
      photoWidth,
      area.height * 0.74,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        photo,
        Radius.circular(max(4.0, photo.width * 0.12)),
      ),
      Paint()..color = level.accent.withValues(alpha: 0.2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        photo.deflate(1),
        Radius.circular(max(3.0, photo.width * 0.1)),
      ),
      Paint()
        ..color = AppTheme.midnight.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final contentLeft = photo.right + max(5.0, area.width * 0.08);
    final contentWidth = area.right - contentLeft;
    final linePaint = Paint()
      ..color = AppTheme.midnight.withValues(alpha: 0.34)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = max(2.0, area.height * 0.05);

    final rows = min(4, max(2, (area.height / 13).floor()));
    for (var i = 0; i < rows; i++) {
      final y = area.top + (i * area.height * 0.18);
      final widthFactor = i.isEven ? 1.0 : 0.74;
      canvas.drawLine(
        Offset(contentLeft, y),
        Offset(contentLeft + (contentWidth * widthFactor), y),
        linePaint,
      );
    }

    final footerLinePaint = Paint()
      ..color = AppTheme.midnight.withValues(alpha: 0.18)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = max(1.6, area.height * 0.04);
    final footerTop = area.top + area.height * 0.82;
    canvas.drawLine(
      Offset(area.left, footerTop),
      Offset(area.right, footerTop),
      footerLinePaint,
    );
    canvas.drawLine(
      Offset(area.left, footerTop + max(5.0, area.height * 0.12)),
      Offset(
        area.left + (area.width * 0.72),
        footerTop + max(5.0, area.height * 0.12),
      ),
      footerLinePaint,
    );
  }

  void _drawProgressMarkers(Canvas canvas, Rect area) {
    if (totalFragments <= 0) {
      return;
    }

    final count = totalFragments;
    final spacing = max(2.0, area.width * 0.035);
    final columns = count <= 5 ? count : 5;
    final rows = (count / columns).ceil();
    final markerWidth = (area.width - (spacing * (columns - 1))) / columns;
    final markerHeight = min(
      max(4.0, markerWidth * 0.42),
      (area.height - (spacing * (rows - 1))) / rows,
    );
    final totalHeight = (markerHeight * rows) + (spacing * (rows - 1));
    final top = area.top + ((area.height - totalHeight) / 2);

    for (var i = 0; i < count; i++) {
      final row = i ~/ columns;
      final column = i % columns;
      final rect = Rect.fromLTWH(
        area.left + (column * (markerWidth + spacing)),
        top + (row * (markerHeight + spacing)),
        markerWidth,
        markerHeight,
      );
      final isRevealed = i < revealedFragments;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(markerHeight * 0.4)),
        Paint()
          ..color = isRevealed
              ? level.accent.withValues(alpha: 0.88)
              : AppTheme.midnight.withValues(alpha: 0.12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePreviewPainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.revealedFragments != revealedFragments ||
        oldDelegate.totalFragments != totalFragments;
  }
}

class _GridBoard extends StatelessWidget {
  const _GridBoard({
    required this.grid,
    required this.selectedIndices,
    required this.hasError,
    required this.dragPosition,
    required this.gridSize,
    required this.accent,
    required this.compact,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final List<String> grid;
  final List<int> selectedIndices;
  final bool hasError;
  final Offset? dragPosition;
  final int gridSize;
  final Color accent;
  final bool compact;
  final void Function(Offset localPosition, _BoardMetrics metrics) onPanStart;
  final void Function(Offset localPosition, _BoardMetrics metrics) onPanUpdate;
  final Future<void> Function() onPanEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.card.withValues(alpha: 0.97),
            AppTheme.newsprint.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.midnight.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _BoardMetrics.forSize(
              size: constraints.biggest.shortestSide,
              gridSize: gridSize,
            );
            final letterSize = max(
              12.0,
              min(28.0, metrics.cellSize * (gridSize >= 8 ? 0.48 : 0.44)),
            );
            final radius = max(6.0, min(10.0, metrics.cellSize * 0.22));

            return Center(
              child: SizedBox.square(
                dimension: metrics.size,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) =>
                      onPanStart(details.localPosition, metrics),
                  onPanUpdate: (details) =>
                      onPanUpdate(details.localPosition, metrics),
                  onPanEnd: (_) => onPanEnd(),
                  onPanCancel: () {
                    onPanEnd();
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _SelectionPathPainter(
                            metrics: metrics,
                            selectedIndices: selectedIndices,
                            dragPosition: dragPosition,
                            color: accent,
                            hasError: hasError,
                          ),
                        ),
                      ),
                      for (var index = 0; index < grid.length; index++)
                        Positioned.fromRect(
                          rect: metrics.rectFor(index),
                          child: _GridCell(
                            letter: grid[index],
                            isEmpty: grid[index].isEmpty,
                            isSelected: selectedIndices.contains(index),
                            hasError: hasError,
                            accent: accent,
                            radius: radius,
                            fontSize: letterSize,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.letter,
    required this.isEmpty,
    required this.isSelected,
    required this.hasError,
    required this.accent,
    required this.radius,
    required this.fontSize,
  });

  final String letter;
  final bool isEmpty;
  final bool isSelected;
  final bool hasError;
  final Color accent;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.midnight.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppTheme.rule.withValues(alpha: 0.28)),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSelected
              ? [accent, AppTheme.midnight]
              : hasError
              ? [AppTheme.pressRed.withValues(alpha: 0.18), AppTheme.card]
              : [AppTheme.card, AppTheme.newsprint.withValues(alpha: 0.58)],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isSelected
              ? Colors.transparent
              : hasError
              ? AppTheme.pressRed.withValues(alpha: 0.45)
              : AppTheme.midnight.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: (isSelected ? accent : AppTheme.midnight).withValues(
              alpha: isSelected ? 0.24 : 0.08,
            ),
            blurRadius: isSelected ? 14 : 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            color: isSelected ? Colors.white : AppTheme.midnight,
          ),
        ),
      ),
    );
  }
}

class _BoardMetrics {
  const _BoardMetrics({
    required this.size,
    required this.gridSize,
    required this.spacing,
  });

  factory _BoardMetrics.forSize({required double size, required int gridSize}) {
    final spacing = switch (gridSize) {
      >= 8 when size < 240 => 4.0,
      >= 8 => 5.0,
      >= 6 when size < 240 => 5.0,
      >= 6 => 7.0,
      _ when size < 240 => 8.0,
      _ => 10.0,
    };

    return _BoardMetrics(size: size, gridSize: gridSize, spacing: spacing);
  }

  final double size;
  final int gridSize;
  final double spacing;

  double get cellSize => (size - (spacing * (gridSize - 1))) / gridSize;

  Rect rectFor(int index) {
    final row = index ~/ gridSize;
    final column = index % gridSize;
    final stride = cellSize + spacing;

    return Rect.fromLTWH(column * stride, row * stride, cellSize, cellSize);
  }

  Offset centerFor(int index) => rectFor(index).center;

  int? indexFor(Offset position) {
    if (position.dx < 0 ||
        position.dy < 0 ||
        position.dx >= size ||
        position.dy >= size) {
      return null;
    }

    final stride = cellSize + spacing;
    final column = (position.dx / stride).floor();
    final row = (position.dy / stride).floor();

    if (column < 0 || column >= gridSize || row < 0 || row >= gridSize) {
      return null;
    }

    final localX = position.dx - (column * stride);
    final localY = position.dy - (row * stride);

    if (localX > cellSize || localY > cellSize) {
      return null;
    }

    return (row * gridSize) + column;
  }
}

class _GameLayoutMetrics {
  const _GameLayoutMetrics({
    required this.horizontalPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.sectionGap,
    required this.showcaseHeight,
    required this.boardTopInset,
    required this.compact,
    required this.prioritizeBoard,
  });

  factory _GameLayoutMetrics.fromConstraints(
    BoxConstraints constraints, {
    required int gridSize,
  }) {
    final compact = constraints.maxHeight < 720 || constraints.maxWidth < 380;
    final veryCompact =
        constraints.maxHeight < 620 || constraints.maxWidth < 340;
    final prioritizeBoard = gridSize >= 8 || constraints.maxHeight < 640;
    final showcaseHeight = min(
      prioritizeBoard
          ? compact
                ? 134.0
                : 144.0
          : compact
          ? 146.0
          : 162.0,
      max(
        prioritizeBoard ? 118.0 : 124.0,
        constraints.maxHeight *
            (prioritizeBoard
                ? veryCompact
                      ? 0.2
                      : 0.22
                : veryCompact
                ? 0.21
                : 0.24),
      ),
    );

    return _GameLayoutMetrics(
      horizontalPadding: veryCompact
          ? 14.0
          : compact
          ? 16.0
          : 20.0,
      topPadding: veryCompact ? 0.0 : 2.0,
      bottomPadding: veryCompact ? 12.0 : 20.0,
      sectionGap: prioritizeBoard
          ? 8.0
          : veryCompact
          ? 10.0
          : compact
          ? 12.0
          : 16.0,
      showcaseHeight: showcaseHeight,
      boardTopInset: prioritizeBoard
          ? 8.0
          : compact
          ? 10.0
          : 14.0,
      compact: compact,
      prioritizeBoard: prioritizeBoard,
    );
  }

  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final double sectionGap;
  final double showcaseHeight;
  final double boardTopInset;
  final bool compact;
  final bool prioritizeBoard;
}

class _SelectionPathPainter extends CustomPainter {
  const _SelectionPathPainter({
    required this.metrics,
    required this.selectedIndices,
    required this.dragPosition,
    required this.color,
    required this.hasError,
  });

  final _BoardMetrics metrics;
  final List<int> selectedIndices;
  final Offset? dragPosition;
  final Color color;
  final bool hasError;

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedIndices.isEmpty) {
      return;
    }

    final points = [
      for (final index in selectedIndices) metrics.centerFor(index),
    ];

    final linePaint = Paint()
      ..color = (hasError ? AppTheme.pressRed : color).withValues(alpha: 0.58)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(6.0, metrics.cellSize * 0.18);

    final glowPaint = Paint()
      ..color = (hasError ? AppTheme.pressRed : color).withValues(alpha: 0.14)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = linePaint.strokeWidth + 10;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    if (dragPosition != null) {
      path.lineTo(dragPosition!.dx, dragPosition!.dy);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SelectionPathPainter oldDelegate) {
    return oldDelegate.metrics != metrics ||
        oldDelegate.dragPosition != dragPosition ||
        oldDelegate.color != color ||
        oldDelegate.hasError != hasError ||
        !_sameSelection(oldDelegate.selectedIndices, selectedIndices);
  }

  bool _sameSelection(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }

    return true;
  }
}

class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(8),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _HeaderScorePill extends StatelessWidget {
  const _HeaderScorePill({
    required this.score,
    required this.total,
    required this.fontSize,
    required this.compact,
  });

  final int score;
  final int total;
  final double fontSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 13,
        vertical: compact ? 8 : 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$score/$total',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: fontSize,
            ),
          ),
          Text(
            'pontos',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MusicToggleButton extends StatelessWidget {
  const _MusicToggleButton({
    required this.enabled,
    required this.onPressed,
    this.size = 42,
  });

  final bool enabled;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? AppTheme.pressBlue.withValues(alpha: 0.12)
          : AppTheme.midnight.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            enabled ? Icons.music_note_rounded : Icons.music_off_rounded,
            color: enabled ? AppTheme.pressBlue : AppTheme.ink,
            size: size * 0.48,
          ),
        ),
      ),
    );
  }
}

class _ShowcasePill extends StatelessWidget {
  const _ShowcasePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.midnight.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppTheme.rule.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.pressBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.midnight,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
