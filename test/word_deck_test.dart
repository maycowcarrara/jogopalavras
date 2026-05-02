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
    final deck = WordDeck(['USADA', 'NOVA'], random: _SequenceRandom([1]));

    expect(deck.nextWhere((word) => word != 'USADA'), 'NOVA');
  });

  test('todas as palavras têm dicas sem entregar a resposta', () {
    const genericHints = {
      'Cabe em chamada curta de jornal',
      'Surge bastante na fala sem cerimônia',
      'Pode aparecer em bilhete rápido',
      'Funciona como peça pequena da conversa',
      'Entra fácil numa manchete enxuta',
      'Fica perto do vocabulário de todo dia',
      'Ajuda a montar uma frase simples',
      'Palavra breve, mas com presença forte',
      'Costuma passar despercebida por hábito',
      'Tem jeito de nota curta no canto da página',
      'Aparece bem em conversa ou notícia',
      'Tem tamanho de chamada de caderno',
      'Serve para dar mais corpo a uma frase',
      'Frequente em textos sem soar difícil',
      'Pode ocupar o centro de uma pequena nota',
      'Integra vocabulário bem circulado',
      'Ajuda a ligar ideia, fato ou descrição',
      'Soa familiar mesmo fora da escola',
      'Entra sem esforço numa matéria curta',
      'Tem ritmo de palavra comum em manchete',
      'Pede atenção maior antes do fechamento',
      'Tem presença de caderno mais completo',
      'Costuma carregar ideia com mais fôlego',
      'Cabe em reportagem, análise ou editorial',
      'Parece palavra de página mais densa',
      'Exige leitura calma para não escapar',
      'Tem corpo de termo usado em matéria longa',
      'Ajuda a nomear assunto mais elaborado',
      'Surge quando a pauta ganha profundidade',
      'Combina com edição revisada com cuidado',
    };

    for (final entries in wordBank.values) {
      expect(entries, isNotEmpty);

      for (final entry in entries) {
        expect(entry.text, isNotEmpty);
        expect(entry.hint, isNotEmpty);
        expect(entry.extraHint, isNotEmpty);
        expect(
          genericHints,
          isNot(contains(entry.hint)),
          reason: 'A dica de ${entry.text} é genérica demais.',
        );
        expect(
          _normalize(entry.hint).contains(_normalize(entry.text)),
          isFalse,
          reason: 'A dica de ${entry.text} entrega a palavra.',
        );
      }
    }
  });

  test('dicas cabem em até três linhas no painel compacto', () {
    for (final entries in wordBank.values) {
      for (final entry in entries) {
        expect(
          _wrapsWithinThreeLines(
            'Nota da redação: ${entry.hint}',
            maxCharactersPerLine: 30,
          ),
          isTrue,
          reason: 'A dica de ${entry.text} pode passar de 3 linhas.',
        );
        expect(
          _wrapsWithinThreeLines(
            'Dica extra: ${entry.extraHint}',
            maxCharactersPerLine: 28,
          ),
          isTrue,
          reason: 'A dica extra de ${entry.text} pode passar de 3 linhas.',
        );
      }
    }
  });

  test('nível fácil não usa preposições ou pronomes como palavra', () {
    const weakEasyWords = {
      'ANTE',
      'APÓS',
      'COMO',
      'CUJA',
      'CUJO',
      'DELA',
      'DELE',
      'ELES',
      'ELAS',
      'ESSE',
      'ESSA',
      'ESTA',
      'ESTE',
      'ISTO',
      'LHES',
      'MAIS',
      'MEUS',
      'NELA',
      'NELE',
      'NUMA',
      'PARA',
      'PELA',
      'PELO',
      'POIS',
      'QUAL',
      'QUEM',
      'SEUS',
      'SUAS',
      'TAIS',
      'TEUS',
      'TUAS',
      'VOCÊ',
    };

    final easyWords = wordBank[GameLevel.easy]!.map((entry) => entry.text);

    for (final word in easyWords) {
      expect(
        weakEasyWords,
        isNot(contains(word)),
        reason: '$word não tem conceito bom para uma dica fácil.',
      );
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

  test('banco curado mantém variedade suficiente por nível', () {
    expect(wordBank[GameLevel.easy]!.length, greaterThanOrEqualTo(150));
    expect(wordBank[GameLevel.medium]!.length, greaterThanOrEqualTo(180));
    expect(wordBank[GameLevel.hard]!.length, greaterThanOrEqualTo(190));
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

bool _wrapsWithinThreeLines(String text, {required int maxCharactersPerLine}) {
  final words = text.split(RegExp(r'\s+'));
  var lines = 1;
  var currentLineLength = 0;

  for (final word in words) {
    if (word.isEmpty) {
      continue;
    }

    if (currentLineLength == 0) {
      currentLineLength = word.length;
      continue;
    }

    final nextLength = currentLineLength + 1 + word.length;
    if (nextLength <= maxCharactersPerLine) {
      currentLineLength = nextLength;
      continue;
    }

    lines++;
    currentLineLength = word.length;
  }

  return lines <= 3;
}
