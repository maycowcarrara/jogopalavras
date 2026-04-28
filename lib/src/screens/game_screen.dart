import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jogopalavras/src/core/ads/ad_service.dart';
import 'package:jogopalavras/src/core/audio/game_music_service.dart';
import 'package:jogopalavras/src/game/game_level.dart';
import 'package:jogopalavras/src/game/ranking_store.dart';
import 'package:jogopalavras/src/game/word_bank.dart';
import 'package:jogopalavras/src/game/word_deck.dart';
import 'package:jogopalavras/src/navigation/app_page_route.dart';
import 'package:jogopalavras/src/screens/ranking_screen.dart';
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

enum _VictoryAction { back, ranking, replay }

class _InitialsDialog extends StatefulWidget {
  const _InitialsDialog({required this.score, required this.words});

  final int score;
  final int words;

  @override
  State<_InitialsDialog> createState() => _InitialsDialogState();
}

class _InitialsDialogState extends State<_InitialsDialog> {
  late final TextEditingController _controller;
  String _currentInitials = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    final nextInitials = value.toUpperCase();
    if (_controller.text != nextInitials) {
      _controller.value = TextEditingValue(
        text: nextInitials,
        selection: TextSelection.collapsed(offset: nextInitials.length),
      );
    }

    setState(() {
      _currentInitials = nextInitials;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.rule),
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Assine o placar',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Você fez ${widget.score} pontos com ${widget.words} acertos. Digite 3 letras para salvar no ranking.',
              style: const TextStyle(height: 1.35),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              maxLength: 3,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                LengthLimitingTextInputFormatter(3),
              ],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
              ),
              decoration: const InputDecoration(
                counterText: '',
                hintText: 'ABC',
                border: OutlineInputBorder(),
              ),
              onChanged: _handleChanged,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: _currentInitials.length == 3
                ? () => Navigator.of(context).pop(_currentInitials)
                : null,
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  static const int _goalScore = 150;
  static const int _pointsPerHit = 10;
  static const int _pointsPerHintHit = 6;
  static const int _pointsPerError = 5;
  static const int _maxSpeedBonus = 10;
  static const int _progressFragments = 10;
  static const Duration _hintDelay = Duration(seconds: 22);
  static const Duration _typewriterTick = Duration(milliseconds: 78);
  static const Duration _hitCelebrationHold = Duration(milliseconds: 900);

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
  bool _isHitCelebrating = false;
  String _typedHitWord = '';
  DateTime _gameStartedAt = DateTime.now();
  DateTime _wordStartedAt = DateTime.now();
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
      _isHitCelebrating = false;
      _typedHitWord = '';
      _wordStartedAt = DateTime.now();
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
    if (_isHitCelebrating) {
      return;
    }

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
    if (_isHitCelebrating) {
      return;
    }

    if (_currentWord.isEmpty) {
      setState(() => _dragPosition = null);
      return;
    }

    if (_currentWord == _targetWord) {
      _hintTimer?.cancel();
      final completedWord = _targetWord;
      final speedBonus = _speedBonusFor(
        DateTime.now().difference(_wordStartedAt),
      );
      final earnedPoints =
          (_hintRevealed ? _pointsPerHintHit : _pointsPerHit) +
          (_hintRevealed ? speedBonus ~/ 2 : speedBonus);
      setState(() {
        _dragPosition = null;
        _score += earnedPoints;
        _discoveredWords = [completedWord, ..._discoveredWords];
        _isHitCelebrating = true;
        _typedHitWord = '';
      });

      await _playHitCelebration(completedWord);
      if (!mounted) {
        return;
      }

      if (_score >= _goalScore) {
        final entry = await _showInitialsDialog();
        if (entry == null || !mounted) {
          return;
        }

        final ranking = await RankingStore.instance.saveEntry(entry);
        if (!mounted) {
          return;
        }

        final action = await _showVictoryDialog(entry, ranking);
        if (!mounted || action == null) {
          return;
        }

        await _handleVictoryAction(action);
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

  int _speedBonusFor(Duration elapsed) {
    final seconds = elapsed.inSeconds;
    if (seconds <= 5) {
      return _maxSpeedBonus;
    }
    if (seconds <= 10) {
      return 8;
    }
    if (seconds <= 15) {
      return 6;
    }
    if (seconds <= 22) {
      return 4;
    }
    if (seconds <= 30) {
      return 2;
    }
    return 0;
  }

  Future<void> _playHitCelebration(String word) async {
    for (var i = 1; i <= word.length; i++) {
      await Future<void>.delayed(_typewriterTick);
      if (!mounted) {
        return;
      }
      setState(() {
        _typedHitWord = word.substring(0, i);
      });
    }

    await Future<void>.delayed(_hitCelebrationHold);
    if (!mounted) {
      return;
    }

    setState(() {
      _isHitCelebrating = false;
    });
  }

  Future<RankingEntry?> _showInitialsDialog() async {
    final completedEntry = RankingEntry(
      initials: '',
      level: widget.level,
      score: _score,
      words: _discoveredWords.length,
      elapsedSeconds: DateTime.now().difference(_gameStartedAt).inSeconds,
      completedAt: DateTime.now(),
    );

    final initials = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _InitialsDialog(
        score: completedEntry.score,
        words: completedEntry.words,
      ),
    );

    if (initials == null) {
      return null;
    }

    return RankingEntry(
      initials: initials,
      level: completedEntry.level,
      score: completedEntry.score,
      words: completedEntry.words,
      elapsedSeconds: completedEntry.elapsedSeconds,
      completedAt: completedEntry.completedAt,
    );
  }

  Future<_VictoryAction?> _showVictoryDialog(
    RankingEntry entry,
    List<RankingEntry> ranking,
  ) async {
    final position =
        ranking.indexWhere(
          (candidate) =>
              candidate.initials == entry.initials &&
              candidate.completedAt == entry.completedAt,
        ) +
        1;

    return showDialog<_VictoryAction>(
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
            'Você fez ${entry.words} acertos, somou ${entry.score} pontos e entrou no ranking${position > 0 ? ' em #$position' : ''}. Quer começar outra rodada?',
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(_VictoryAction.back),
              child: const Text('Voltar'),
            ),
            TextButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(_VictoryAction.ranking),
              icon: const Icon(Icons.leaderboard_rounded, size: 18),
              label: const Text('Ranking'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_VictoryAction.replay),
              child: const Text('Jogar de novo'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleVictoryAction(_VictoryAction action) async {
    switch (action) {
      case _VictoryAction.back:
        Navigator.of(context).pop();
      case _VictoryAction.ranking:
        await Navigator.of(context).pushReplacement(
          appPageRoute<void>(
            settings: const RouteSettings(name: '/ranking'),
            builder: (_) => RankingScreen(initialLevel: widget.level),
          ),
        );
      case _VictoryAction.replay:
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
          _isHitCelebrating = false;
          _typedHitWord = '';
          _gameStartedAt = DateTime.now();
        });
        _generateRound();
    }
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
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, contentConstraints) {
                              final gap = layout.contentGap;
                              final maxMiddleHeight =
                                  contentConstraints.maxHeight;
                              final statusHeight = min(
                                layout.statusHeight,
                                max(68.0, maxMiddleHeight * 0.18),
                              );
                              final targetBoardSize = min(
                                contentConstraints.maxWidth,
                                maxMiddleHeight * layout.boardHeightFactor,
                              );
                              final maxBoardWithScene = max(
                                layout.minBoardSize,
                                maxMiddleHeight -
                                    statusHeight -
                                    (gap * 2) -
                                    layout.minSceneHeight,
                              );
                              final boardSize = min(
                                targetBoardSize,
                                maxBoardWithScene,
                              );
                              final sceneHeight = max(
                                72.0,
                                maxMiddleHeight -
                                    boardSize -
                                    statusHeight -
                                    (gap * 2),
                              );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  RevealOnMount(
                                    delay: const Duration(milliseconds: 80),
                                    child: SizedBox(
                                      height: sceneHeight,
                                      child: _ScenePreview(
                                        level: widget.level,
                                        revealedFragments: revealedFragments,
                                        totalFragments: _progressFragments,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: gap),
                                  RevealOnMount(
                                    delay: const Duration(milliseconds: 120),
                                    child: SizedBox(
                                      height: statusHeight,
                                      child: _RoundShowcaseCard(
                                        level: widget.level,
                                        currentWord: _currentWord,
                                        targetWordLength: _targetWord.length,
                                        hint: _currentHint,
                                        hintSuggested: _hintSuggested,
                                        hintRevealed: _hintRevealed,
                                        hintedHitPoints: _pointsPerHintHit,
                                        hasError: _hasError,
                                        isHitCelebrating: _isHitCelebrating,
                                        typedHitWord: _typedHitWord,
                                        score: _score,
                                        goalScore: _goalScore,
                                        discoveredCount:
                                            _discoveredWords.length,
                                        compact: layout.compact,
                                        musicEnabled: _musicEnabled,
                                        onToggleMusic: _toggleMusic,
                                        onRevealHint: _revealHint,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: gap),
                                  RevealOnMount(
                                    delay: const Duration(milliseconds: 160),
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
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
                                ],
                              );
                            },
                          ),
                        ),
                        SizedBox(height: layout.bannerGap),
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
    required this.isHitCelebrating,
    required this.typedHitWord,
    required this.score,
    required this.goalScore,
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
  final bool isHitCelebrating;
  final String typedHitWord;
  final int score;
  final int goalScore;
  final int discoveredCount;
  final bool compact;
  final bool musicEnabled;
  final VoidCallback onToggleMusic;
  final VoidCallback onRevealHint;

  @override
  Widget build(BuildContext context) {
    final displayWord = isHitCelebrating ? typedHitWord : currentWord;
    final currentText = List<String>.generate(targetWordLength, (index) {
      if (index < displayWord.length) {
        return displayWord[index];
      }

      return '•';
    }).join(' ');
    final typingText = isHitCelebrating ? '$currentText ▌' : currentText;
    final showHintControl = hintSuggested || hintRevealed;
    final progressText = '$score/$goalScore pontos';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.all(compact ? 14 : 16),
          decoration: BoxDecoration(
            color: isHitCelebrating
                ? AppTheme.card.withValues(alpha: 0.99)
                : AppTheme.card.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHitCelebrating
                  ? AppTheme.pressGold.withValues(alpha: 0.72)
                  : AppTheme.rule.withValues(alpha: 0.9),
            ),
            boxShadow: [
              BoxShadow(
                color: isHitCelebrating
                    ? AppTheme.pressGold.withValues(alpha: 0.2)
                    : AppTheme.midnight.withValues(alpha: 0.08),
                blurRadius: isHitCelebrating ? 20 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ultraCompact =
                  constraints.maxHeight < 142 || constraints.maxWidth < 360;

              if (ultraCompact) {
                if (constraints.maxHeight < 58) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 4,
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
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 5,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Text(
                            isHitCelebrating ? typingText : progressText,
                            key: ValueKey<String>(
                              '$typingText-$score-$goalScore-$isHitCelebrating',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isHitCelebrating
                                  ? AppTheme.pressRed
                                  : hasError
                                  ? AppTheme.pressRed
                                  : AppTheme.midnight,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MusicToggleButton(
                        enabled: musicEnabled,
                        onPressed: onToggleMusic,
                        size: 32,
                      ),
                    ],
                  );
                }

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
                              isHitCelebrating
                                  ? typingText
                                  : '$currentText  •  $progressText',
                              key: ValueKey<String>(
                                '$typingText-$score-$goalScore-$isHitCelebrating',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isHitCelebrating
                                    ? AppTheme.pressRed
                                    : hasError
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
                                      color: AppTheme.ink.withValues(
                                        alpha: 0.76,
                                      ),
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
                                            : AppTheme.ink.withValues(
                                                alpha: 0.6,
                                              ),
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
                          isHitCelebrating ? 'Na rotativa' : 'Montagem atual',
                          style: TextStyle(
                            color: isHitCelebrating
                                ? AppTheme.pressRed
                                : AppTheme.ink.withValues(alpha: 0.66),
                            fontWeight: FontWeight.w700,
                            fontSize: compact ? 11 : 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Text(
                            typingText,
                            key: ValueKey<String>(
                              '$typingText-$isHitCelebrating',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isHitCelebrating
                                  ? AppTheme.pressRed
                                  : hasError
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
                              label: progressText,
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
                ],
              );
            },
          ),
        ),
        _HitCelebrationBadge(visible: isHitCelebrating),
      ],
    );
  }
}

class _HitCelebrationBadge extends StatelessWidget {
  const _HitCelebrationBadge({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -8,
      right: 12,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedScale(
            scale: visible ? 1 : 0.86,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.pressRed,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppTheme.card, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.pressRed.withValues(alpha: 0.26),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'ACERTO!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
      return SizedBox(
        width: double.infinity,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 8 : 10,
            vertical: dense ? 6 : 7,
          ),
          decoration: BoxDecoration(
            color: AppTheme.pressGold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: AppTheme.pressGold.withValues(alpha: 0.34),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: AppTheme.pressGold,
                size: dense ? 13 : 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Dica: $hint',
                  maxLines: dense ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.midnight,
                    fontWeight: FontWeight.w800,
                    fontSize: dense
                        ? 10.5
                        : compact
                        ? 11
                        : 12,
                    height: 1.18,
                  ),
                ),
              ),
            ],
          ),
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
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 0,
            end: totalFragments <= 0
                ? 0
                : (revealedFragments / totalFragments).clamp(0.0, 1.0),
          ),
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          builder: (context, completion, child) {
            return CustomPaint(
              painter: _ScenePreviewPainter(
                level: level,
                completion: completion,
                totalFragments: totalFragments,
              ),
              child: child,
            );
          },
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ScenePreviewPainter extends CustomPainter {
  const _ScenePreviewPainter({
    required this.level,
    required this.completion,
    required this.totalFragments,
  });

  final GameLevel level;
  final double completion;
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
      RRect.fromRectAndRadius(page.translate(2, 2), pageRadius),
      Paint()..color = AppTheme.midnight.withValues(alpha: 0.1),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(page, pageRadius),
      Paint()..color = AppTheme.card.withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(page, pageRadius),
      Paint()
        ..color = AppTheme.midnight.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final inner = page.deflate(max(5.0, size.shortestSide * 0.08));
    final foldPaint = Paint()
      ..color = AppTheme.midnight.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(page.left + (page.width * 0.52), page.top + 2),
      Offset(page.left + (page.width * 0.52), page.bottom - 2),
      foldPaint,
    );

    final headerHeight = max(12.0, inner.height * 0.16);
    final header = Rect.fromLTWH(
      inner.left,
      inner.top,
      inner.width,
      headerHeight,
    );
    _drawMasthead(canvas, header);

    final storyArea = Rect.fromLTWH(
      inner.left,
      header.bottom + max(4.0, inner.height * 0.05),
      inner.width,
      inner.height * 0.74,
    );
    _drawStorySections(canvas, storyArea);
  }

  void _drawMasthead(Canvas canvas, Rect header) {
    final rulePaint = Paint()
      ..color = AppTheme.midnight.withValues(alpha: 0.54)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = max(0.8, header.height * 0.07);
    canvas.drawLine(header.topLeft, header.topRight, rulePaint);
    canvas.drawLine(header.bottomLeft, header.bottomRight, rulePaint);

    final titlePainter = TextPainter(
      text: TextSpan(
        text: 'JORNAL',
        style: TextStyle(
          color: AppTheme.midnight.withValues(alpha: 0.82),
          fontFamily: 'Georgia',
          fontFamilyFallback: AppTheme.serifFallback,
          fontSize: max(7.0, header.height * 0.42),
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: header.width * 0.52);
    titlePainter.paint(
      canvas,
      Offset(
        header.center.dx - (titlePainter.width / 2),
        header.center.dy - (titlePainter.height / 2),
      ),
    );

    final ornamentPaint = Paint()
      ..color = level.accent.withValues(alpha: 0.66)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = max(1.0, header.height * 0.09);
    final ornamentWidth = max(5.0, header.width * 0.17);
    final gap = max(5.0, header.width * 0.06);
    canvas.drawLine(
      Offset(header.left, header.center.dy),
      Offset(
        min(header.center.dx - gap, header.left + ornamentWidth),
        header.center.dy,
      ),
      ornamentPaint,
    );
    canvas.drawLine(
      Offset(
        max(header.center.dx + gap, header.right - ornamentWidth),
        header.center.dy,
      ),
      Offset(header.right, header.center.dy),
      ornamentPaint,
    );

    final datePaint = Paint()
      ..color = AppTheme.midnight.withValues(alpha: 0.18)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = max(0.8, header.height * 0.05);
    canvas.drawLine(
      Offset(header.left, header.top + header.height * 0.28),
      Offset(
        header.left + header.width * 0.22,
        header.top + header.height * 0.28,
      ),
      datePaint,
    );
    canvas.drawLine(
      Offset(
        header.right - header.width * 0.2,
        header.top + header.height * 0.72,
      ),
      Offset(header.right, header.top + header.height * 0.72),
      datePaint,
    );
  }

  void _drawStorySections(Canvas canvas, Rect area) {
    if (totalFragments <= 0) {
      return;
    }

    final photoWidth = area.width * 0.38;
    final photo = Rect.fromLTWH(
      area.left,
      area.top + area.height * 0.18,
      photoWidth,
      area.height * 0.48,
    );
    final contentLeft = photo.right + max(5.0, area.width * 0.08);
    final contentWidth = area.right - contentLeft;

    final sections = <_PaperSection>[
      _PaperSection(
        rect: Rect.fromLTWH(
          area.left,
          area.top,
          area.width * 0.58,
          area.height * 0.08,
        ),
        color: level.accent,
        type: _PaperSectionType.rule,
      ),
      _PaperSection(
        rect: Rect.fromLTWH(
          area.left,
          area.top + area.height * 0.11,
          area.width,
          area.height * 0.12,
        ),
        color: AppTheme.midnight,
        type: _PaperSectionType.headline,
      ),
      _PaperSection(
        rect: photo,
        color: level.accent,
        type: _PaperSectionType.photo,
      ),
      _PaperSection(
        rect: Rect.fromLTWH(
          contentLeft,
          photo.top,
          contentWidth,
          area.height * 0.09,
        ),
        color: AppTheme.pressRed,
        type: _PaperSectionType.rule,
      ),
      _PaperSection(
        rect: Rect.fromLTWH(
          contentLeft,
          photo.top + area.height * 0.14,
          contentWidth * 0.82,
          area.height * 0.08,
        ),
        color: AppTheme.pressBlue,
        type: _PaperSectionType.rule,
      ),
      _PaperSection(
        rect: Rect.fromLTWH(
          contentLeft,
          photo.top + area.height * 0.28,
          contentWidth,
          area.height * 0.08,
        ),
        color: AppTheme.pressGold,
        type: _PaperSectionType.rule,
      ),
      _PaperSection(
        rect: Rect.fromLTWH(
          area.left,
          photo.bottom + area.height * 0.08,
          area.width * 0.46,
          area.height * 0.13,
        ),
        color: AppTheme.pressGreen,
        type: _PaperSectionType.column,
      ),
      _PaperSection(
        rect: Rect.fromLTWH(
          area.left + area.width * 0.52,
          photo.bottom + area.height * 0.08,
          area.width * 0.48,
          area.height * 0.13,
        ),
        color: level.accent,
        type: _PaperSectionType.column,
      ),
      _PaperSection(
        rect: Rect.fromLTWH(
          area.left,
          area.bottom - area.height * 0.09,
          area.width * 0.68,
          area.height * 0.07,
        ),
        color: AppTheme.pressRed,
        type: _PaperSectionType.rule,
      ),
      _PaperSection(
        rect: Rect.fromLTWH(
          area.right - area.height * 0.16,
          area.bottom - area.height * 0.16,
          area.height * 0.16,
          area.height * 0.16,
        ),
        color: AppTheme.pressGold,
        type: _PaperSectionType.seal,
      ),
    ];

    final completedSections = completion * sections.length;
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      final reveal = (completedSections - i).clamp(0.0, 1.0);
      _drawSectionPlaceholder(canvas, section);
      if (reveal > 0) {
        _drawCompletedSection(canvas, section, reveal);
      }
    }
  }

  void _drawSectionPlaceholder(Canvas canvas, _PaperSection section) {
    switch (section.type) {
      case _PaperSectionType.seal:
        canvas.drawCircle(
          section.rect.center,
          section.rect.shortestSide / 2,
          Paint()..color = AppTheme.midnight.withValues(alpha: 0.08),
        );
      case _PaperSectionType.column:
        final linePaint = Paint()
          ..color = AppTheme.midnight.withValues(alpha: 0.12)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = max(1.4, section.rect.height * 0.18);
        for (var i = 0; i < 3; i++) {
          final y = section.rect.top + (i * section.rect.height * 0.36);
          final widthFactor = i == 2 ? 0.72 : 1.0;
          canvas.drawLine(
            Offset(section.rect.left, y),
            Offset(section.rect.left + (section.rect.width * widthFactor), y),
            linePaint,
          );
        }
      case _PaperSectionType.photo:
      case _PaperSectionType.headline:
      case _PaperSectionType.rule:
        final radius = Radius.circular(max(2.5, section.rect.height * 0.35));
        canvas.drawRRect(
          RRect.fromRectAndRadius(section.rect, radius),
          Paint()..color = AppTheme.midnight.withValues(alpha: 0.08),
        );
    }
  }

  void _drawCompletedSection(
    Canvas canvas,
    _PaperSection section,
    double reveal,
  ) {
    final rect = section.rect;
    final clippedRect = Rect.fromLTRB(
      rect.left,
      rect.top,
      rect.left + (rect.width * reveal),
      rect.bottom,
    );

    canvas.save();
    canvas.clipRect(clippedRect);

    switch (section.type) {
      case _PaperSectionType.seal:
        final radius = (rect.shortestSide / 2) * (0.82 + (0.18 * reveal));
        canvas.drawCircle(
          rect.center,
          radius,
          Paint()..color = section.color.withValues(alpha: 0.9),
        );
        final checkPaint = Paint()
          ..color = AppTheme.card.withValues(alpha: 0.96)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = max(1.4, rect.shortestSide * 0.14);
        final check = Path()
          ..moveTo(rect.left + rect.width * 0.28, rect.top + rect.height * 0.52)
          ..lineTo(rect.left + rect.width * 0.44, rect.top + rect.height * 0.68)
          ..lineTo(
            rect.left + rect.width * 0.74,
            rect.top + rect.height * 0.34,
          );
        canvas.drawPath(check, checkPaint);
      case _PaperSectionType.column:
        final linePaint = Paint()
          ..color = section.color.withValues(alpha: 0.7 + (0.18 * reveal))
          ..strokeCap = StrokeCap.round
          ..strokeWidth = max(1.6, rect.height * 0.2);
        for (var i = 0; i < 3; i++) {
          final y = rect.top + (i * rect.height * 0.36);
          final widthFactor = i == 2 ? 0.76 : 1.0;
          canvas.drawLine(
            Offset(rect.left, y),
            Offset(rect.left + (rect.width * widthFactor), y),
            linePaint,
          );
        }
      case _PaperSectionType.photo:
        final radius = Radius.circular(max(4.0, rect.width * 0.12));
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, radius),
          Paint()
            ..color = section.color.withValues(alpha: 0.28 + (0.42 * reveal)),
        );
        final sparklePaint = Paint()
          ..color = AppTheme.card.withValues(alpha: 0.74)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = max(1.0, rect.shortestSide * 0.06);
        canvas.drawLine(
          Offset(rect.left + rect.width * 0.24, rect.top + rect.height * 0.68),
          Offset(rect.left + rect.width * 0.46, rect.top + rect.height * 0.42),
          sparklePaint,
        );
        canvas.drawLine(
          Offset(rect.left + rect.width * 0.46, rect.top + rect.height * 0.42),
          Offset(rect.left + rect.width * 0.72, rect.top + rect.height * 0.62),
          sparklePaint,
        );
      case _PaperSectionType.headline:
        final radius = Radius.circular(max(3.0, rect.height * 0.28));
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, radius),
          Paint()..color = section.color.withValues(alpha: 0.82),
        );
        final highlight = Rect.fromLTWH(
          rect.left,
          rect.top + rect.height * 0.66,
          rect.width,
          max(1.0, rect.height * 0.16),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(highlight, Radius.circular(highlight.height)),
          Paint()..color = AppTheme.pressGold.withValues(alpha: 0.72),
        );
      case _PaperSectionType.rule:
        final radius = Radius.circular(max(2.5, rect.height * 0.38));
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, radius),
          Paint()..color = section.color.withValues(alpha: 0.78),
        );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScenePreviewPainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.completion != completion ||
        oldDelegate.totalFragments != totalFragments;
  }
}

enum _PaperSectionType { rule, headline, photo, column, seal }

class _PaperSection {
  const _PaperSection({
    required this.rect,
    required this.color,
    required this.type,
  });

  final Rect rect;
  final Color color;
  final _PaperSectionType type;
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
    required this.contentGap,
    required this.bannerGap,
    required this.statusHeight,
    required this.minSceneHeight,
    required this.minBoardSize,
    required this.boardHeightFactor,
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
    final boardHeightFactor = switch (gridSize) {
      >= 8 => veryCompact ? 0.56 : 0.58,
      >= 6 => veryCompact ? 0.52 : 0.54,
      _ => veryCompact ? 0.44 : 0.48,
    };

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
      contentGap: veryCompact ? 7.0 : 8.0,
      bannerGap: veryCompact ? 6.0 : 8.0,
      statusHeight: prioritizeBoard
          ? veryCompact
                ? 78.0
                : 86.0
          : compact
          ? 92.0
          : 104.0,
      minSceneHeight: prioritizeBoard
          ? veryCompact
                ? 92.0
                : 112.0
          : compact
          ? 124.0
          : 150.0,
      minBoardSize: gridSize >= 8
          ? 270.0
          : gridSize >= 6
          ? 248.0
          : 188.0,
      boardHeightFactor: boardHeightFactor,
      compact: compact,
      prioritizeBoard: prioritizeBoard,
    );
  }

  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final double sectionGap;
  final double contentGap;
  final double bannerGap;
  final double statusHeight;
  final double minSceneHeight;
  final double minBoardSize;
  final double boardHeightFactor;
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
