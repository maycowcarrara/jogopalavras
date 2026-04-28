import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jogopalavras/src/app.dart';
import 'package:jogopalavras/src/game/game_level.dart';
import 'package:jogopalavras/src/screens/ranking_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('abre a intro e navega para a seleção de nível', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const WordMazeApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Anagrama\nOculto'), findsOneWidget);
    expect(find.text('Iniciar jogo'), findsOneWidget);

    await tester.ensureVisible(find.text('Iniciar jogo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar jogo'));
    await tester.pumpAndSettle();

    expect(find.text('Escolha a editoria'), findsOneWidget);
    expect(find.text('Começar no fácil'), findsOneWidget);

    await tester.tap(find.text('Começar no fácil'));
    await tester.pumpAndSettle();

    expect(find.text('Coluna leve'), findsOneWidget);
    expect(find.text('0/150'), findsOneWidget);
  });

  testWidgets('ranking abre jogo direto no nível selecionado', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(home: RankingScreen(initialLevel: GameLevel.medium)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Melhores em médio'), findsOneWidget);
    expect(find.text('Jogar no médio'), findsOneWidget);

    await tester.tap(find.text('Jogar no médio'));
    await tester.pumpAndSettle();

    expect(find.text('Caderno principal'), findsOneWidget);
    expect(find.text('0/150'), findsOneWidget);
  });
}
