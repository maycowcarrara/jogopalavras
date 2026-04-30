import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jogopalavras/src/core/ads/ad_service.dart';
import 'package:jogopalavras/src/core/audio/game_music_service.dart';
import 'package:jogopalavras/src/game/campaign_progress_store.dart';
import 'package:jogopalavras/src/game/game_level.dart';
import 'package:jogopalavras/src/game/hint_display_preferences.dart';
import 'package:jogopalavras/src/game/ranking_store.dart';
import 'package:jogopalavras/src/game/word_bank.dart';
import 'package:jogopalavras/src/game/word_deck.dart';
import 'package:jogopalavras/src/game/word_progress_store.dart';
import 'package:jogopalavras/src/navigation/app_page_route.dart';
import 'package:jogopalavras/src/screens/ranking_screen.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';
import 'package:jogopalavras/src/widgets/app_backdrop.dart';
import 'package:jogopalavras/src/widgets/reveal_on_mount.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.level,
    this.stageNumber,
    this.replayStage = false,
  });

  final GameLevel level;
  final int? stageNumber;
  final bool replayStage;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _InitialsDialog extends StatefulWidget {
  const _InitialsDialog({
    required this.score,
    required this.words,
    required this.initialInitials,
  });

  final int score;
  final int words;
  final String initialInitials;

  @override
  State<_InitialsDialog> createState() => _InitialsDialogState();
}

class _InitialsDialogState extends State<_InitialsDialog> {
  late final TextEditingController _controller;
  String _currentInitials = '';

  @override
  void initState() {
    super.initState();
    _currentInitials = widget.initialInitials;
    _controller = TextEditingController(text: _currentInitials);
    _controller.selection = TextSelection.collapsed(
      offset: _currentInitials.length,
    );
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
              'Você fez ${widget.score} pontos com ${widget.words} acertos. Digite de 3 a 6 letras ou números para salvar no ranking.',
              style: const TextStyle(height: 1.35),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                LengthLimitingTextInputFormatter(6),
              ],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
              decoration: const InputDecoration(
                counterText: '',
                hintText: 'MRC',
                border: OutlineInputBorder(),
              ),
              onChanged: _handleChanged,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed:
                _currentInitials.length >= 3 && _currentInitials.length <= 6
                ? () => Navigator.of(context).pop(_currentInitials)
                : null,
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

int _stageNumberForUsedWords({
  required GameLevel level,
  required int usedWords,
}) {
  final totalWords = wordBank[level]?.length ?? 0;
  if (totalWords == 0) {
    return 0;
  }

  final stageCount = (totalWords / level.targetWordCount).ceil();
  final nextStage = (usedWords / level.targetWordCount).floor() + 1;
  return nextStage.clamp(1, stageCount).toInt();
}

int _targetWordCountForStage({
  required GameLevel level,
  required int stageNumber,
}) {
  if (stageNumber <= 0 || level.mixesAllLevels) {
    return level.targetWordCount;
  }

  final totalWords = wordBank[level]?.length ?? 0;
  if (totalWords == 0) {
    return level.targetWordCount;
  }

  final wordsBeforeStage = (stageNumber - 1) * level.targetWordCount;
  final remainingWords = max(1, totalWords - wordsBeforeStage);
  return min(level.targetWordCount, remainingWords);
}

int _normalizedStageNumberForLevel({
  required GameLevel level,
  required int? stageNumber,
}) {
  final totalStages = _stageCountForLevel(level);
  if (stageNumber == null || stageNumber <= 0 || totalStages == 0) {
    return 0;
  }

  return stageNumber.clamp(1, totalStages).toInt();
}

List<WordEntry> _wordEntriesForStage({
  required GameLevel level,
  required int stageNumber,
}) {
  final entries = wordBank[level] ?? const <WordEntry>[];
  if (stageNumber <= 0 || level.mixesAllLevels || entries.isEmpty) {
    return entries;
  }

  final start = (stageNumber - 1) * level.targetWordCount;
  if (start < 0 || start >= entries.length) {
    return entries;
  }

  final end = min(start + level.targetWordCount, entries.length);
  return entries.sublist(start, end);
}

int _stageCountForLevel(GameLevel level) {
  if (level.mixesAllLevels) {
    return 0;
  }

  final totalWords = wordBank[level]?.length ?? 0;
  if (totalWords == 0) {
    return 0;
  }

  return (totalWords / level.targetWordCount).ceil();
}

String _chapterTitleForLevel(GameLevel level) => switch (level) {
  GameLevel.easy => 'Pauta',
  GameLevel.medium => 'Redação',
  GameLevel.hard => 'Fechamento',
  GameLevel.pautaLivre => 'Pauta Livre',
};

String _subStageLabelForLevel(GameLevel level) => switch (level) {
  GameLevel.easy => 'Página',
  GameLevel.medium => 'Matéria',
  GameLevel.hard => 'Prova',
  GameLevel.pautaLivre => 'Rodada',
};

String _editionLabelForLevel(GameLevel level) => switch (level) {
  GameLevel.easy => 'Edição 01',
  GameLevel.medium => 'Edição 02',
  GameLevel.hard => 'Edição 03',
  GameLevel.pautaLivre => 'Plantão',
};

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  static const int _pointsPerSkip = RankingStore.pointsPerSkip;
  static const Duration _typewriterTick = Duration(milliseconds: 78);
  static const Duration _hitCelebrationHold = Duration(milliseconds: 900);

  late final Map<GameLevel, WordDeck<WordEntry>> _wordDecks;
  late final Map<GameLevel, List<WordEntry>> _wordEntriesByLevel;
  late final Random _random;
  Timer? _scoreTimer;

  final Map<GameLevel, Set<String>> _usedWordsByLevel =
      <GameLevel, Set<String>>{};
  List<String> _grid = <String>[];
  List<int> _selectedIndices = <int>[];
  List<String> _discoveredWords = <String>[];
  final Set<String> _sessionWords = <String>{};
  String _currentWord = '';
  String _targetWord = '';
  String _currentHint = '';
  late int _score;
  int _errors = 0;
  int _skipsUsed = 0;
  int _elapsedSeconds = 0;
  int _roundTargetWordCount = 1;
  int _roundStageNumber = 0;
  bool _hasError = false;
  bool _isPreparingRound = true;
  bool _isHitCelebrating = false;
  bool _isCompletingRound = false;
  bool _isPaused = false;
  bool _exitDialogOpen = false;
  bool _pausedByLifecycle = false;
  String _typedHitWord = '';
  Offset? _dragPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _random = Random();
    _score = RankingStore.startingScoreForLevel(widget.level);
    final replayStageNumber = widget.replayStage
        ? _normalizedStageNumberForLevel(
            level: widget.level,
            stageNumber: widget.stageNumber,
          )
        : 0;
    _wordEntriesByLevel = <GameLevel, List<WordEntry>>{
      for (final level in widget.level.sourceLevels)
        level: _wordEntriesForStage(
          level: level,
          stageNumber: replayStageNumber,
        ),
    };
    _wordDecks = <GameLevel, WordDeck<WordEntry>>{
      for (final level in widget.level.sourceLevels)
        level: WordDeck(_wordEntriesByLevel[level]!, random: _random),
    };
    unawaited(_prepareGame());
    unawaited(HintDisplayPreferences.instance.initialize());
    _startMusic();
  }

  Future<void> _prepareGame() async {
    if (_recordsCampaignProgress) {
      final usedWords = await WordProgressStore.instance.loadUsedWords(
        widget.level,
      );
      final totalWords = wordBank[widget.level]!.length;
      if (usedWords.length >= totalWords) {
        await WordProgressStore.instance.resetLevel(widget.level);
        usedWords.clear();
      }

      _usedWordsByLevel[widget.level] = usedWords;
      _roundStageNumber = _stageNumberForUsedWords(
        level: widget.level,
        usedWords: usedWords.length,
      );
      _roundTargetWordCount = min(
        widget.level.targetWordCount,
        max(1, totalWords - usedWords.length),
      );
    } else {
      _roundStageNumber = _normalizedStageNumberForLevel(
        level: widget.level,
        stageNumber: widget.stageNumber,
      );
      _roundTargetWordCount = _targetWordCountForStage(
        level: widget.level,
        stageNumber: _roundStageNumber,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isPreparingRound = false;
    });
    _generateRound();
    _startScoreTimer();
  }

  @override
  void dispose() {
    _scoreTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    GameMusicService.instance.clearGamePause();
    super.dispose();
  }

  void _startScoreTimer() {
    _scoreTimer?.cancel();
    _scoreTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (!_isHitCelebrating && !_isPaused) {
          _elapsedSeconds += 1;
        }
        _score = _scoreFromStats();
      });
    });
  }

  int _scoreFromStats() {
    return RankingStore.scoreForPerformance(
      level: widget.level,
      words: _discoveredWords.length,
      elapsedSeconds: _elapsedSeconds,
      errors: _errors,
      skipsUsed: _skipsUsed,
    );
  }

  Future<void> _startMusic() async {
    await GameMusicService.instance.playForLevel(widget.level);
  }

  Future<void> _togglePause() async {
    _pausedByLifecycle = false;
    await _setPaused(!_isPaused);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_pausedByLifecycle) {
        _pausedByLifecycle = false;
        unawaited(_setPaused(false));
      } else if (_isPaused) {
        unawaited(GameMusicService.instance.pause());
      }
      return;
    }

    if (!_isPaused) {
      _pausedByLifecycle = true;
      unawaited(_setPaused(true));
    }
  }

  Future<void> _setPaused(bool nextValue) async {
    if (_isPaused == nextValue) {
      if (nextValue) {
        await GameMusicService.instance.pause();
      }
      return;
    }

    setState(() {
      _isPaused = nextValue;
      _dragPosition = null;
      if (nextValue) {
        _selectedIndices = <int>[];
        _currentWord = '';
        _hasError = false;
      }
    });

    if (nextValue) {
      await GameMusicService.instance.pause(holdForGame: true);
      return;
    }

    await GameMusicService.instance.resume(widget.level);
  }

  void _generateRound({String? avoidWord}) {
    final nextEntry = _nextWordEntry(avoidWord: avoidWord);
    final nextWord = nextEntry.text;
    _sessionWords.add(nextWord);
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
      _isHitCelebrating = false;
      _typedHitWord = '';
    });
  }

  WordEntry _nextWordEntry({String? avoidWord}) {
    final sourceLevel = _sourceLevelForNextWord();
    final usedWords = _usedWordsByLevel[sourceLevel] ?? const <String>{};

    bool isFreshCandidate(WordEntry entry) =>
        !_sessionWords.contains(entry.text) && !usedWords.contains(entry.text);

    if (_hasWordCandidate(sourceLevel, isFreshCandidate)) {
      return _wordDecks[sourceLevel]!.nextWhere(isFreshCandidate);
    }

    bool isSkippedCandidate(WordEntry entry) =>
        !_discoveredWords.contains(entry.text) &&
        !usedWords.contains(entry.text) &&
        entry.text != avoidWord;

    if (_hasWordCandidate(sourceLevel, isSkippedCandidate)) {
      return _wordDecks[sourceLevel]!.nextWhere(isSkippedCandidate);
    }

    bool isAnyUnsolvedCandidate(WordEntry entry) =>
        !_discoveredWords.contains(entry.text) &&
        !usedWords.contains(entry.text);

    if (_hasWordCandidate(sourceLevel, isAnyUnsolvedCandidate)) {
      return _wordDecks[sourceLevel]!.nextWhere(isAnyUnsolvedCandidate);
    }

    return _wordDecks[sourceLevel]!.nextWhere(
      (entry) => !usedWords.contains(entry.text),
    );
  }

  bool _hasWordCandidate(GameLevel level, bool Function(WordEntry entry) test) {
    return _wordEntriesByLevel[level]!.any(test);
  }

  bool get _recordsCampaignProgress =>
      !widget.level.mixesAllLevels && !widget.replayStage;

  GameLevel _sourceLevelForNextWord() {
    if (!widget.level.mixesAllLevels) {
      return widget.level;
    }

    final sourceLevels = widget.level.sourceLevels;
    return sourceLevels[_random.nextInt(sourceLevels.length)];
  }

  Future<void> _skipWord() async {
    if (_isPaused || _isHitCelebrating) {
      return;
    }

    final shouldSkip = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.rule),
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Pular palavra?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Você perde $_pointsPerSkip pontos e recebe outra palavra.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.skip_next_rounded, size: 18),
            label: const Text('Pular'),
          ),
        ],
      ),
    );

    if (shouldSkip != true || !mounted) {
      return;
    }

    setState(() {
      _skipsUsed += 1;
      _score = _scoreFromStats();
    });
    _generateRound(avoidWord: _targetWord);
  }

  Future<void> _confirmExitGame() async {
    if (_exitDialogOpen || !mounted) {
      return;
    }

    _exitDialogOpen = true;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.rule),
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Sair da partida?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Seu progresso nesta rodada será perdido.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar jogando'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Sair'),
          ),
        ],
      ),
    );
    _exitDialogOpen = false;

    if (shouldExit == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleDrag(Offset localPosition, _BoardMetrics metrics) {
    if (_isPaused || _isHitCelebrating) {
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
    if (_isPaused || _isHitCelebrating || _isCompletingRound) {
      return;
    }

    if (_currentWord.isEmpty) {
      setState(() => _dragPosition = null);
      return;
    }

    if (_currentWord == _targetWord) {
      final completedWord = _targetWord;
      final completedWords = _discoveredWords.length + 1;
      setState(() {
        _dragPosition = null;
        _discoveredWords = [completedWord, ..._discoveredWords];
        _score = _scoreFromStats();
        _isHitCelebrating = true;
        _typedHitWord = '';
      });

      await _playHitCelebration(completedWord);
      if (!mounted) {
        return;
      }

      if (completedWords >= _roundTargetWordCount) {
        _isCompletingRound = true;
        _scoreTimer?.cancel();
        await GameMusicService.instance.playEndOfGame();
        final entry = await _completedRankingEntry();
        if (entry == null || !mounted) {
          return;
        }

        GameLevel? continueLevel = widget.level;
        GameLevel? completedLevel;
        var completedGame = false;
        if (_recordsCampaignProgress) {
          final usedWords = await WordProgressStore.instance.markWordsUsed(
            widget.level,
            _discoveredWords,
          );
          final levelCompleted =
              usedWords.length >= wordBank[widget.level]!.length;
          if (levelCompleted) {
            completedLevel = widget.level;
            completedGame = widget.level == GameLevel.hard;
            final campaignProgress = await CampaignProgressStore.instance
                .completeLevel(widget.level);
            continueLevel = campaignProgress.nextLevelAfter(widget.level);
          }
        }

        final rankingResult = await RankingStore.instance.saveEntryResult(
          entry,
        );
        if (!mounted) {
          return;
        }

        await AdService.instance.registerNaturalBreak();
        if (!mounted) {
          return;
        }

        await Navigator.of(context).pushReplacement(
          appPageRoute<void>(
            settings: RouteSettings(
              name: '/ranking/${widget.level.name}/${entry.stageNumber}',
            ),
            builder: (_) => RankingScreen(
              initialLevel: widget.level,
              initialStageNumber: entry.stageNumber > 0
                  ? entry.stageNumber
                  : null,
              highlightEntry: entry,
              initialResult: rankingResult,
              continueLevel: continueLevel,
              completedLevel: completedLevel,
              completedGame: completedGame,
            ),
          ),
        );
      } else {
        _generateRound();
      }
      return;
    }

    setState(() {
      _dragPosition = null;
      _hasError = true;
      _errors += 1;
      _score = _scoreFromStats();
      _selectedIndices = <int>[];
      _currentWord = '';
    });
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
      unawaited(GameMusicService.instance.playWordVictory());
    }

    await Future<void>.delayed(_hitCelebrationHold);
    if (!mounted) {
      return;
    }

    setState(() {
      _isHitCelebrating = false;
    });
  }

  Future<RankingEntry?> _completedRankingEntry() async {
    final finalScore = _scoreFromStats();
    final completedEntry = RankingEntry(
      initials: '',
      level: widget.level,
      stageNumber: _roundStageNumber,
      score: finalScore,
      words: _discoveredWords.length,
      elapsedSeconds: _elapsedSeconds,
      completedAt: DateTime.now(),
      errors: _errors,
      skipsUsed: _skipsUsed,
    );

    final lastInitials = await RankingStore.instance.loadLastInitials();
    if (!mounted) {
      return null;
    }

    var initials = lastInitials;
    while (initials.isEmpty) {
      final candidate = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _InitialsDialog(
          score: completedEntry.score,
          words: completedEntry.words,
          initialInitials: lastInitials,
        ),
      );

      if (candidate == null || !mounted) {
        return null;
      }

      final result = await RankingStore.instance.updatePlayerInitials(
        candidate,
      );
      if (result.saved) {
        initials = result.initials ?? candidate;
        break;
      }

      await _showInitialsError(result);
      if (!mounted) {
        return null;
      }
    }

    return RankingEntry(
      initials: initials,
      level: completedEntry.level,
      stageNumber: completedEntry.stageNumber,
      score: completedEntry.score,
      words: completedEntry.words,
      elapsedSeconds: completedEntry.elapsedSeconds,
      completedAt: completedEntry.completedAt,
      errors: completedEntry.errors,
      skipsUsed: completedEntry.skipsUsed,
    );
  }

  Future<void> _showInitialsError(InitialsUpdateResult result) async {
    final message = switch (result.status) {
      InitialsUpdateStatus.invalid => 'Use de 3 a 6 letras ou números.',
      InitialsUpdateStatus.unavailable =>
        'Essa assinatura já está em uso no ranking.',
      InitialsUpdateStatus.cooldown =>
        'Você só pode alterar a assinatura a cada 30 dias.',
      InitialsUpdateStatus.saved => 'Assinatura salva.',
    };

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.rule),
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Assinatura indisponível',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(message, style: const TextStyle(height: 1.35)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tentar outra'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetWordCount = _roundTargetWordCount;
    final progress = (_discoveredWords.length / targetWordCount).clamp(
      0.0,
      1.0,
    );
    final systemUiStyle = SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    );

    if (_isPreparingRound) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemUiStyle,
        child: Scaffold(
          body: AppBackdrop(
            primary: widget.level.accent,
            secondary: AppTheme.pressRed,
            showOptionsControl: false,
            child: const Center(
              child: SizedBox.square(
                dimension: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiStyle,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            return;
          }
          unawaited(_confirmExitGame());
        },
        child: Scaffold(
          body: Stack(
            children: [
              AppBackdrop(
                primary: widget.level.accent,
                secondary: AppTheme.pressRed,
                showOptionsControl: false,
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
                            child: _LevelIdentityBar(
                              level: widget.level,
                              stageNumber: _roundStageNumber,
                              stageCount: _stageCountForLevel(widget.level),
                              targetWordCount: targetWordCount,
                              discoveredCount: _discoveredWords.length,
                              replayStage: widget.replayStage,
                              compact: layout.compact,
                            ),
                          ),
                          SizedBox(height: layout.identityGap),
                          RevealOnMount(
                            delay: const Duration(milliseconds: 50),
                            child: _GameHeader(
                              score: _score,
                              progress: progress,
                              isPaused: _isPaused,
                              compact: layout.compact,
                              prioritizeBoard: layout.prioritizeBoard,
                              onBack: () => unawaited(_confirmExitGame()),
                              onTogglePause: _togglePause,
                            ),
                          ),
                          SizedBox(height: layout.sectionGap),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, contentConstraints) {
                                final gap = layout.contentGap;
                                final panelHeight = layout.minPanelHeight;
                                final actionHeight = layout.actionPanelHeight;

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    RevealOnMount(
                                      delay: const Duration(milliseconds: 80),
                                      child: SizedBox(
                                        height: panelHeight,
                                        child: _RoundScenePanel(
                                          level: widget.level,
                                          currentWord: _currentWord,
                                          targetWordLength: _targetWord.length,
                                          hasError: _hasError,
                                          isHitCelebrating: _isHitCelebrating,
                                          typedHitWord: _typedHitWord,
                                          targetWordCount: targetWordCount,
                                          discoveredCount:
                                              _discoveredWords.length,
                                          compact: layout.compact,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: gap),
                                    Expanded(
                                      child: LayoutBuilder(
                                        builder: (context, boardConstraints) {
                                          final boardSize = min(
                                            boardConstraints.maxWidth,
                                            boardConstraints.maxHeight,
                                          );

                                          return RevealOnMount(
                                            delay: const Duration(
                                              milliseconds: 130,
                                            ),
                                            child: Center(
                                              child: SizedBox.square(
                                                dimension: boardSize,
                                                child: AnimatedSwitcher(
                                                  duration: const Duration(
                                                    milliseconds: 180,
                                                  ),
                                                  child: _isPaused
                                                      ? _PausedBoard(
                                                          key:
                                                              const ValueKey<
                                                                String
                                                              >('paused'),
                                                          accent: widget
                                                              .level
                                                              .accent,
                                                          compact:
                                                              layout.compact,
                                                          onResume:
                                                              _togglePause,
                                                        )
                                                      : _GridBoard(
                                                          key:
                                                              const ValueKey<
                                                                String
                                                              >('board'),
                                                          grid: _grid,
                                                          selectedIndices:
                                                              _selectedIndices,
                                                          hasError: _hasError,
                                                          dragPosition:
                                                              _dragPosition,
                                                          gridSize: widget
                                                              .level
                                                              .gridSize,
                                                          accent: widget
                                                              .level
                                                              .accent,
                                                          compact:
                                                              layout.compact,
                                                          onPanStart:
                                                              _handleDrag,
                                                          onPanUpdate:
                                                              _handleDrag,
                                                          onPanEnd: _onDragEnd,
                                                        ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(height: gap),
                                    RevealOnMount(
                                      delay: const Duration(milliseconds: 170),
                                      child: SizedBox(
                                        height: actionHeight,
                                        child: _RoundActionPanel(
                                          level: widget.level,
                                          hint: _currentHint,
                                          skipPenalty: _pointsPerSkip,
                                          compact: layout.compact,
                                          onSkipWord: _skipWord,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelIdentityBar extends StatelessWidget {
  const _LevelIdentityBar({
    required this.level,
    required this.stageNumber,
    required this.stageCount,
    required this.targetWordCount,
    required this.discoveredCount,
    required this.replayStage,
    required this.compact,
  });

  final GameLevel level;
  final int stageNumber;
  final int stageCount;
  final int targetWordCount;
  final int discoveredCount;
  final bool replayStage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 34.0 : 42.0;
    final chapterTitle = _chapterTitleForLevel(level);
    final stageLabel = level.mixesAllLevels || stageNumber <= 0
        ? 'Rodada solta'
        : '${_subStageLabelForLevel(level)} $stageNumber/$stageCount';
    final subtitle = replayStage
        ? 'Revisão do arquivo • $targetWordCount palavras'
        : '$stageLabel • $discoveredCount/$targetWordCount palavras';

    return Material(
      color: AppTheme.card.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(10),
      elevation: 6,
      shadowColor: AppTheme.midnight.withValues(alpha: 0.12),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          compact ? 8 : 12,
          compact ? 6 : 10,
          compact ? 8 : 12,
          compact ? 6 : 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.rule.withValues(alpha: 0.72)),
        ),
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: level.accent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: level.accent.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                level.icon,
                color: Colors.white,
                size: compact ? 18 : 23,
              ),
            ),
            SizedBox(width: compact ? 8 : 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!compact) ...[
                    Text(
                      _editionLabelForLevel(level),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.ink.withValues(alpha: 0.56),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    chapterTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.midnight,
                      fontWeight: FontWeight.w900,
                      fontSize: compact ? 17 : 23,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: compact ? 3 : 5),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.ink.withValues(alpha: 0.72),
                      fontSize: compact ? 10.5 : 12.5,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _TinyPressBadge(
              label: level.mixesAllLevels
                  ? level.wordSizeShortLabel
                  : level.tag,
              color: level.accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyPressBadge extends StatelessWidget {
  const _TinyPressBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.score,
    required this.progress,
    required this.isPaused,
    required this.compact,
    required this.prioritizeBoard,
    required this.onBack,
    required this.onTogglePause,
  });

  final int score;
  final double progress;
  final bool isPaused;
  final bool compact;
  final bool prioritizeBoard;
  final VoidCallback onBack;
  final VoidCallback onTogglePause;

  @override
  Widget build(BuildContext context) {
    final padding = prioritizeBoard
        ? 10.0
        : compact
        ? 10.0
        : 12.0;
    final scoreSize = prioritizeBoard
        ? 19.0
        : compact
        ? 20.0
        : 21.0;

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
              _HeaderBackButton(onPressed: onBack),
              SizedBox(width: prioritizeBoard ? 8 : 10),
              const Spacer(),
              SizedBox(width: compact ? 8 : 10),
              _HeaderPauseButton(
                paused: isPaused,
                onPressed: onTogglePause,
                compact: compact,
              ),
              SizedBox(width: compact ? 8 : 10),
              const AppOptionsControl(dark: true),
              SizedBox(width: compact ? 8 : 10),
              _HeaderScorePill(
                score: score,
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

class _RoundScenePanel extends StatelessWidget {
  const _RoundScenePanel({
    required this.level,
    required this.currentWord,
    required this.targetWordLength,
    required this.hasError,
    required this.isHitCelebrating,
    required this.typedHitWord,
    required this.targetWordCount,
    required this.discoveredCount,
    required this.compact,
  });

  final GameLevel level;
  final String currentWord;
  final int targetWordLength;
  final bool hasError;
  final bool isHitCelebrating;
  final String typedHitWord;
  final int targetWordCount;
  final int discoveredCount;
  final bool compact;

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
    final progressText = '$discoveredCount/$targetWordCount palavras';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.all(compact ? 9 : 10),
          decoration: BoxDecoration(
            color: AppTheme.midnight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHitCelebrating
                  ? AppTheme.pressGold.withValues(alpha: 0.72)
                  : level.accent.withValues(alpha: 0.32),
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
              final availableTextWidth = max(80.0, constraints.maxWidth - 18);
              final tightHeight = constraints.maxHeight <= 96;
              final maxWordFont = compact ? 22.0 : 27.0;
              final fittedWordFont = min(
                maxWordFont,
                availableTextWidth / max(1, typingText.length) * 1.7,
              ).clamp(15.0, maxWordFont);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!tightHeight) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.title_rounded,
                          color: level.accent.withValues(alpha: 0.95),
                          size: compact ? 16 : 17,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Manchete oculta',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.68),
                              fontSize: compact ? 10.5 : 11.5,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ScoreChip(
                          progressText: progressText,
                          compact: compact,
                          dark: true,
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 6 : 8),
                  ] else
                    Align(
                      alignment: Alignment.centerRight,
                      child: _ScoreChip(
                        progressText: progressText,
                        compact: true,
                        dark: true,
                      ),
                    ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: SizedBox(
                      key: ValueKey<String>(
                        '$typingText-$targetWordCount-$isHitCelebrating',
                      ),
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          typingText,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isHitCelebrating
                                ? AppTheme.pressGold
                                : hasError
                                ? AppTheme.pressRed
                                : Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: fittedWordFont.toDouble(),
                            letterSpacing: 0,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: tightHeight
                        ? 5
                        : compact
                        ? 6
                        : 8,
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: targetWordCount == 0
                          ? 0
                          : discoveredCount / targetWordCount,
                      minHeight: compact ? 4 : 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(level.accent),
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

class _RoundActionPanel extends StatelessWidget {
  const _RoundActionPanel({
    required this.level,
    required this.hint,
    required this.skipPenalty,
    required this.compact,
    required this.onSkipWord,
  });

  final GameLevel level;
  final String hint;
  final int skipPenalty;
  final bool compact;
  final VoidCallback onSkipWord;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.card.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.rule.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _ActionPanelNewsPainter(accent: level.accent),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HintPanel(
              level: level,
              hint: hint,
              compact: compact,
              accent: level.accent,
            ),
            SizedBox(height: compact ? 8 : 10),
            _SkipWordButton(
              penalty: skipPenalty,
              dense: compact,
              compact: compact,
              onPressed: onSkipWord,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionPanelNewsPainter extends CustomPainter {
  const _ActionPanelNewsPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rulePaint = Paint()
      ..color = AppTheme.midnight.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    final accentPaint = Paint()
      ..color = accent.withValues(alpha: 0.08)
      ..strokeWidth = 2;

    for (var y = 18.0; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rulePaint);
    }

    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ActionPanelNewsPainter oldDelegate) {
    return oldDelegate.accent != accent;
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

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.progressText,
    required this.compact,
    this.dark = false,
  });

  final String progressText;
  final bool compact;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: compact ? 74 : 84),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.12)
            : AppTheme.midnight.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.14)
              : AppTheme.rule.withValues(alpha: 0.72),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          progressText,
          maxLines: 1,
          style: TextStyle(
            color: dark ? Colors.white : AppTheme.midnight,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _HintPanel extends StatelessWidget {
  const _HintPanel({
    required this.level,
    required this.hint,
    required this.compact,
    required this.accent,
  });

  final GameLevel level;
  final String hint;
  final bool compact;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 9 : 10,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: accent.withValues(alpha: 0.34)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.article_outlined,
              color: accent,
              size: compact ? 16 : 17,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ValueListenableBuilder<HintDisplayMode>(
                valueListenable: HintDisplayPreferences.instance.modeNotifier,
                builder: (context, mode, child) {
                  final style = TextStyle(
                    color: AppTheme.midnight,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 13.5 : 14.5,
                    height: 1.22,
                  );
                  if (mode == HintDisplayMode.dicaAberta) {
                    return Text(
                      'Nota da redação: $hint',
                      maxLines: 3,
                      overflow: TextOverflow.visible,
                      style: style,
                    );
                  }

                  return _FlickeringHintText(
                    level: level,
                    hint: hint,
                    maxLines: 3,
                    style: style,
                  );
                },
                child: const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlickeringHintText extends StatefulWidget {
  const _FlickeringHintText({
    required this.level,
    required this.hint,
    required this.maxLines,
    required this.style,
  });

  final GameLevel level;
  final String hint;
  final int maxLines;
  final TextStyle style;

  @override
  State<_FlickeringHintText> createState() => _FlickeringHintTextState();
}

class _FlickeringHintTextState extends State<_FlickeringHintText> {
  static const Duration _tickInterval = Duration(milliseconds: 95);

  late final Timer _timer;
  late Random _random;
  late _HintRevealProfile _profile;
  List<String> _words = [];
  List<_HintWordReveal> _wordReveals = [];
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _resetHintAnimation();
    _timer = Timer.periodic(_tickInterval, (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _advanceHintAnimation();
      });
    });
  }

  @override
  void didUpdateWidget(covariant _FlickeringHintText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hint != widget.hint || oldWidget.level != widget.level) {
      _resetHintAnimation();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.style.color ?? AppTheme.midnight;
    return Semantics(
      label: 'Nota da redação: ${widget.hint}',
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(style: widget.style, children: _buildHintSpans(baseColor)),
          maxLines: widget.maxLines,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }

  List<InlineSpan> _buildHintSpans(Color baseColor) {
    var wordIndex = 0;
    return [
      const TextSpan(text: 'Nota da redação: '),
      for (final token
          in widget.hint
              .splitMapJoin(
                RegExp(r'\s+'),
                onMatch: (match) => '\u0000${match.group(0)}\u0000',
                onNonMatch: (text) => text,
              )
              .split('\u0000'))
        if (token.trim().isEmpty)
          TextSpan(text: token)
        else
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _TypewriterHintWord(
              fullWord: token,
              visibleWord: _visibleWordFor(wordIndex++, token),
              style: widget.style.copyWith(color: baseColor),
            ),
          ),
    ];
  }

  void _resetHintAnimation() {
    _random = Random();
    _profile = _HintRevealProfile.forLevel(widget.level);
    _tick = 0;
    _words = widget.hint
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    _wordReveals = [
      for (var index = 0; index < _words.length; index++)
        _HintWordReveal(
          hiddenUntil:
              _profile.initialDelayBase +
              _random.nextInt(_profile.initialDelayJitter) +
              (index % 4) * _profile.indexDelayStep,
          typeEvery: _profile.typeEveryMin + _random.nextInt(3),
        ),
    ];
  }

  void _advanceHintAnimation() {
    _tick++;
    final maxVisibleWords = _maxVisibleWords;
    var visibleWords = _wordReveals
        .where((reveal) => reveal.visibleCharacters > 0)
        .length;

    for (var index = 0; index < _wordReveals.length; index++) {
      final reveal = _wordReveals[index];
      final wordLength = _words[index].runes.length;

      if (reveal.visibleCharacters == 0) {
        if (_tick < reveal.hiddenUntil || visibleWords >= maxVisibleWords) {
          continue;
        }
        reveal.visibleCharacters = 1;
        reveal.lastTypedAt = _tick;
        visibleWords++;
        continue;
      }

      if (reveal.visibleCharacters < wordLength) {
        if (_tick - reveal.lastTypedAt >= reveal.typeEvery) {
          reveal.visibleCharacters++;
          reveal.lastTypedAt = _tick;
          if (reveal.visibleCharacters >= wordLength) {
            reveal.holdUntil =
                _tick + _profile.holdMin + _random.nextInt(_profile.holdJitter);
          }
        }
        continue;
      }

      if (_tick >= reveal.holdUntil) {
        reveal.visibleCharacters = 0;
        reveal.holdUntil = 0;
        reveal.hiddenUntil =
            _tick +
            _profile.repeatDelayBase +
            _random.nextInt(_profile.repeatDelayJitter) +
            (index % 3) * _profile.indexDelayStep;
        reveal.typeEvery = _profile.typeEveryMin + _random.nextInt(3);
        visibleWords--;
      }
    }
  }

  int get _maxVisibleWords {
    if (_words.length <= 3) {
      return min(_profile.maxVisibleWords, 1);
    }
    if (_words.length <= 8) {
      return min(_profile.maxVisibleWords, _profile.compactVisibleWords);
    }
    return _profile.maxVisibleWords;
  }

  String _visibleWordFor(int index, String token) {
    if (index >= _wordReveals.length) {
      return '';
    }
    final visibleCharacters = min(
      _wordReveals[index].visibleCharacters,
      token.runes.length,
    );
    return String.fromCharCodes(token.runes.take(visibleCharacters));
  }
}

class _TypewriterHintWord extends StatelessWidget {
  const _TypewriterHintWord({
    required this.fullWord,
    required this.visibleWord,
    required this.style,
  });

  final String fullWord;
  final String visibleWord;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(opacity: 0, child: Text(fullWord, style: style)),
        Text(visibleWord, style: style),
      ],
    );
  }
}

class _HintRevealProfile {
  const _HintRevealProfile({
    required this.initialDelayBase,
    required this.initialDelayJitter,
    required this.repeatDelayBase,
    required this.repeatDelayJitter,
    required this.indexDelayStep,
    required this.holdMin,
    required this.holdJitter,
    required this.typeEveryMin,
    required this.compactVisibleWords,
    required this.maxVisibleWords,
  });

  final int initialDelayBase;
  final int initialDelayJitter;
  final int repeatDelayBase;
  final int repeatDelayJitter;
  final int indexDelayStep;
  final int holdMin;
  final int holdJitter;
  final int typeEveryMin;
  final int compactVisibleWords;
  final int maxVisibleWords;

  static _HintRevealProfile forLevel(GameLevel level) {
    return switch (level) {
      GameLevel.easy => const _HintRevealProfile(
        initialDelayBase: 6,
        initialDelayJitter: 24,
        repeatDelayBase: 8,
        repeatDelayJitter: 30,
        indexDelayStep: 3,
        holdMin: 12,
        holdJitter: 8,
        typeEveryMin: 1,
        compactVisibleWords: 3,
        maxVisibleWords: 4,
      ),
      GameLevel.medium => const _HintRevealProfile(
        initialDelayBase: 5,
        initialDelayJitter: 20,
        repeatDelayBase: 7,
        repeatDelayJitter: 24,
        indexDelayStep: 3,
        holdMin: 16,
        holdJitter: 10,
        typeEveryMin: 1,
        compactVisibleWords: 2,
        maxVisibleWords: 3,
      ),
      GameLevel.hard || GameLevel.pautaLivre => const _HintRevealProfile(
        initialDelayBase: 4,
        initialDelayJitter: 18,
        repeatDelayBase: 6,
        repeatDelayJitter: 20,
        indexDelayStep: 2,
        holdMin: 22,
        holdJitter: 14,
        typeEveryMin: 1,
        compactVisibleWords: 3,
        maxVisibleWords: 5,
      ),
    };
  }
}

class _HintWordReveal {
  _HintWordReveal({required this.hiddenUntil, required this.typeEvery});

  int hiddenUntil;
  int typeEvery;
  int visibleCharacters = 0;
  int lastTypedAt = 0;
  int holdUntil = 0;
}

class _SkipWordButton extends StatelessWidget {
  const _SkipWordButton({
    required this.penalty,
    required this.dense,
    required this.compact,
    required this.onPressed,
  });

  final int penalty;
  final bool dense;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.skip_next_rounded, size: dense ? 19 : 20),
      label: Text(
        'Pular palavra  -$penalty pts',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.pressRed,
        backgroundColor: AppTheme.pressRed.withValues(alpha: 0.075),
        side: BorderSide(color: AppTheme.pressRed.withValues(alpha: 0.5)),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size(double.infinity, dense ? 50 : 54),
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 18 : 20,
          vertical: dense ? 13 : 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        textStyle: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: dense
              ? 13
              : compact
              ? 14
              : 15,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _GridBoard extends StatelessWidget {
  const _GridBoard({
    super.key,
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
        padding: EdgeInsets.all(compact ? 3 : 5),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _BoardMetrics.forSize(
              size: constraints.biggest.shortestSide,
              gridSize: gridSize,
            );
            final letterSize = max(
              16.0,
              min(36.0, metrics.cellSize * (gridSize >= 6 ? 0.52 : 0.5)),
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

class _PausedBoard extends StatelessWidget {
  const _PausedBoard({
    super.key,
    required this.accent,
    required this.compact,
    required this.onResume,
  });

  final Color accent;
  final bool compact;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.midnight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.42), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? 18 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 54 : 62,
                height: compact ? 54 : 62,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.pause_rounded,
                  color: Colors.white,
                  size: compact ? 30 : 34,
                ),
              ),
              SizedBox(height: compact ? 12 : 16),
              Text(
                'Pausado',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 20 : 24,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tempo congelado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 12 : 13,
                ),
              ),
              SizedBox(height: compact ? 14 : 18),
              ElevatedButton.icon(
                onPressed: onResume,
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('Continuar'),
              ),
            ],
          ),
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
      >= 6 when size < 300 => 3.0,
      >= 6 => 4.0,
      >= 5 when size < 300 => 4.0,
      >= 5 => 5.0,
      _ when size < 240 => 6.0,
      _ => 7.0,
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

    return (row * gridSize) + column;
  }
}

class _GameLayoutMetrics {
  const _GameLayoutMetrics({
    required this.horizontalPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.identityGap,
    required this.sectionGap,
    required this.contentGap,
    required this.minPanelHeight,
    required this.actionPanelHeight,
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
    final prioritizeBoard = gridSize >= 6 || constraints.maxHeight < 700;

    return _GameLayoutMetrics(
      horizontalPadding: veryCompact
          ? 6.0
          : compact
          ? 8.0
          : 12.0,
      topPadding: veryCompact ? 0.0 : 2.0,
      bottomPadding: veryCompact ? 8.0 : 14.0,
      identityGap: veryCompact ? 5.0 : 6.0,
      sectionGap: prioritizeBoard
          ? 5.0
          : veryCompact
          ? 8.0
          : compact
          ? 10.0
          : 12.0,
      contentGap: veryCompact ? 6.0 : 7.0,
      minPanelHeight: prioritizeBoard
          ? veryCompact
                ? 90.0
                : 96.0
          : compact
          ? 88.0
          : 92.0,
      actionPanelHeight: veryCompact
          ? 154.0
          : compact
          ? 158.0
          : 168.0,
      compact: compact,
      prioritizeBoard: prioritizeBoard,
    );
  }

  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final double identityGap;
  final double sectionGap;
  final double contentGap;
  final double minPanelHeight;
  final double actionPanelHeight;
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
  const _HeaderBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _HeaderPauseButton extends StatelessWidget {
  const _HeaderPauseButton({
    required this.paused,
    required this.onPressed,
    required this.compact,
  });

  final bool paused;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: paused ? 'Continuar' : 'Pausar',
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: compact ? 44 : 46,
            height: compact ? 44 : 46,
            child: Icon(
              paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: Colors.white,
              size: compact ? 23 : 25,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderScorePill extends StatelessWidget {
  const _HeaderScorePill({
    required this.score,
    required this.fontSize,
    required this.compact,
  });

  final int score;
  final double fontSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 44 : 46),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 15,
        vertical: compact ? 8 : 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        '$score',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
