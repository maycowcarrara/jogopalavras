import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jogopalavras/src/game/game_level.dart';
import 'package:jogopalavras/src/game/word_bank.dart';
import 'package:jogopalavras/src/game/word_deck.dart';

void main() {
  test('não repete palavras até esgotar o baralho', () {
    final deck = WordDeck(['CASA', 'BOLO', 'MESA', 'RODA'], random: Random(7));

    final firstCycle = [
      deck.nextWord(),
      deck.nextWord(),
      deck.nextWord(),
      deck.nextWord(),
    ];

    expect(firstCycle.toSet().length, 4);
  });

  test(
    'evita repetir a última palavra na virada do baralho quando possível',
    () {
      final deck = WordDeck(['CASA', 'BOLO', 'MESA'], random: Random(1));

      final draws = [
        deck.nextWord(),
        deck.nextWord(),
        deck.nextWord(),
        deck.nextWord(),
      ];

      expect(draws[2] == draws[3], isFalse);
    },
  );

  test('pula palavras já usadas quando há alternativa disponível', () {
    final deck = WordDeck(
      ['USADA', 'NOVA'],
      random: _SequenceRandom([1]),
    );

    expect(deck.nextWhere((word) => word != 'USADA'), 'NOVA');
  });

  test('todas as palavras têm dicas sem entregar a resposta', () {
    for (final entries in wordBank.values) {
      expect(entries, isNotEmpty);

      for (final entry in entries) {
        expect(entry.text, isNotEmpty);
        expect(entry.hint, isNotEmpty);
        expect(
          _normalize(entry.hint).contains(_normalize(entry.text)),
          isFalse,
          reason: 'A dica de ${entry.text} entrega a palavra.',
        );
      }
    }
  });

  test('palavras respeitam o tamanho esperado por nível', () {
    for (final MapEntry(key: level, value: entries) in wordBank.entries) {
      final (minLength, maxLength) = switch (level) {
        GameLevel.easy => (4, 4),
        GameLevel.medium => (5, 7),
        GameLevel.hard => (7, 10),
        GameLevel.pautaLivre => (4, 10),
      };
      final words = entries.map((entry) => entry.text).toList();

      expect(words.toSet().length, words.length);
      for (final word in words) {
        expect(
          word.length,
          inInclusiveRange(minLength, maxLength),
          reason: '$word não combina com ${level.name}.',
        );
      }
    }
  });
}

class _SequenceRandom implements Random {
  _SequenceRandom(this._values);

  final List<int> _values;
  int _index = 0;

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() => nextInt(1000000) / 1000000;

  @override
  int nextInt(int max) {
    final value = _index < _values.length ? _values[_index++] : 0;
    return value % max;
  }
}

String _normalize(String value) {
  return value
      .toUpperCase()
      .replaceAll(RegExp('[ÁÀÂÃ]'), 'A')
      .replaceAll(RegExp('[ÉÊ]'), 'E')
      .replaceAll(RegExp('[Í]'), 'I')
      .replaceAll(RegExp('[ÓÔÕ]'), 'O')
      .replaceAll(RegExp('[Ú]'), 'U')
      .replaceAll(RegExp('[Ç]'), 'C');
}
