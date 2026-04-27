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

  test('todas as palavras têm dicas sem entregar a resposta', () {
    for (final level in GameLevel.values) {
      final entries = wordBank[level]!;

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
