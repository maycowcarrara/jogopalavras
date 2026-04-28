import 'dart:math';

class WordDeck<T> {
  WordDeck(List<T> sourceWords, {Random? random})
    : _sourceEntries = List.unmodifiable(sourceWords),
      _random = random ?? Random();

  final List<T> _sourceEntries;
  final Random _random;
  final List<T> _remainingEntries = [];
  T? _lastEntry;

  int get length => _sourceEntries.length;

  T nextWord() {
    if (_sourceEntries.isEmpty) {
      throw StateError('O banco de palavras não pode estar vazio.');
    }

    if (_remainingEntries.isEmpty) {
      _remainingEntries
        ..clear()
        ..addAll(_sourceEntries)
        ..shuffle(_random);

      if (_remainingEntries.length > 1 &&
          _remainingEntries.first == _lastEntry) {
        final swapIndex = 1 + _random.nextInt(_remainingEntries.length - 1);
        final firstEntry = _remainingEntries.first;
        _remainingEntries[0] = _remainingEntries[swapIndex];
        _remainingEntries[swapIndex] = firstEntry;
      }
    }

    final next = _remainingEntries.removeAt(0);
    _lastEntry = next;
    return next;
  }

  T nextWhere(bool Function(T entry) test) {
    for (var attempt = 0; attempt < _sourceEntries.length; attempt++) {
      final next = nextWord();
      if (test(next)) {
        return next;
      }
    }

    return nextWord();
  }
}
