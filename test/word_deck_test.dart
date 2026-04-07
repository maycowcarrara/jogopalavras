import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
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
}
