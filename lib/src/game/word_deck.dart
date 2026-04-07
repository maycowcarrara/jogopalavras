import 'dart:math';

class WordDeck {
  WordDeck(List<String> sourceWords, {Random? random})
    : _sourceWords = List.unmodifiable(sourceWords),
      _random = random ?? Random();

  final List<String> _sourceWords;
  final Random _random;
  final List<String> _remainingWords = [];
  String? _lastWord;

  String nextWord() {
    if (_sourceWords.isEmpty) {
      throw StateError('O banco de palavras não pode estar vazio.');
    }

    if (_remainingWords.isEmpty) {
      _remainingWords
        ..clear()
        ..addAll(_sourceWords)
        ..shuffle(_random);

      if (_remainingWords.length > 1 && _remainingWords.first == _lastWord) {
        final swapIndex = 1 + _random.nextInt(_remainingWords.length - 1);
        final firstWord = _remainingWords.first;
        _remainingWords[0] = _remainingWords[swapIndex];
        _remainingWords[swapIndex] = firstWord;
      }
    }

    final next = _remainingWords.removeAt(0);
    _lastWord = next;
    return next;
  }
}
