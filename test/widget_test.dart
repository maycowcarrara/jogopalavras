import 'package:flutter_test/flutter_test.dart';
import 'package:jogopalavras/src/app.dart';

void main() {
  testWidgets('abre a intro e navega para a seleção de nível', (tester) async {
    await tester.pumpWidget(const WordMazeApp());

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
    expect(find.textContaining('0/100'), findsOneWidget);
  });
}
