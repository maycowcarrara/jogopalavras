import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jogopalavras/src/app.dart';
import 'package:jogopalavras/src/game/game_level.dart';
import 'package:jogopalavras/src/navigation/app_route_observer.dart';
import 'package:jogopalavras/src/screens/level_screen.dart';
import 'package:jogopalavras/src/screens/ranking_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });

  tearDown(() {
    binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });

  testWidgets('abre a intro e navega para a seleção de nível', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const WordMazeApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Entreletras'), findsOneWidget);
    expect(find.text('Iniciar jogo'), findsOneWidget);

    await tester.ensureVisible(find.text('Iniciar jogo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar jogo'));
    await tester.pumpAndSettle();

    expect(find.text('Mapa da edição'), findsOneWidget);
    expect(find.text('Pauta'), findsOneWidget);
    expect(find.text('Pauta Livre'), findsOneWidget);

    final easyStage = find.byKey(const ValueKey<String>('stage_easy'));
    await tester.ensureVisible(easyStage);
    await tester.pumpAndSettle();
    await tester.tap(easyStage);
    await tester.pumpAndSettle();

    expect(find.text('0/10 palavras'), findsOneWidget);
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

    expect(find.text('0/8 palavras'), findsOneWidget);
  });

  testWidgets('card de próxima pauta abre a fase atual', (tester) async {
    SharedPreferences.setMockInitialValues({'intro_seen_v1': true});
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final routeRecorder = _RouteRecorder();

    await tester.pumpWidget(
      MaterialApp(
        home: const LevelScreen(),
        navigatorObservers: [routeRecorder],
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 1200));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('next_objective_banner')),
    );

    expect(routeRecorder.pushedRouteNames.last, '/game/easy');
  });

  testWidgets('mapa atualiza fases ao voltar de outra rota', (tester) async {
    SharedPreferences.setMockInitialValues({'intro_seen_v1': true});
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [appRouteObserver],
        home: const LevelScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Próxima pauta 1/'), findsOneWidget);

    unawaited(
      navigatorKey.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Rota temporária')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      'word_progress_used_v1:easy',
      List<String>.generate(10, (index) => 'PALAVRA_$index'),
    );

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(find.textContaining('Próxima pauta 2/'), findsOneWidget);
  });

  testWidgets('voltar na tela inicial pede confirmação antes de sair', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'intro_seen_v1': true});
    final platformMethods = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformMethods.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(const WordMazeApp());
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('Mapa da edição'), findsOneWidget);
    expect(find.text('Pressione voltar novamente para sair'), findsOneWidget);
    expect(
      platformMethods.where((method) => method == 'SystemNavigator.pop'),
      isEmpty,
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(platformMethods, contains('SystemNavigator.pop'));
  });

  testWidgets('confirmação de saída expira depois de 5 segundos', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'intro_seen_v1': true});
    final platformMethods = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformMethods.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(const WordMazeApp());
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pump();

    await tester.pump(const Duration(seconds: 6));
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('Mapa da edição'), findsOneWidget);
    expect(find.text('Pressione voltar novamente para sair'), findsOneWidget);
    expect(
      platformMethods.where((method) => method == 'SystemNavigator.pop'),
      isEmpty,
    );
  });

  testWidgets('opções abre painel discreto', (tester) async {
    SharedPreferences.setMockInitialValues({'intro_seen_v1': true});
    await tester.pumpWidget(const WordMazeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('app_options_button')));
    await tester.pumpAndSettle();

    expect(find.text('Música'), findsOneWidget);
    expect(find.text('Efeitos'), findsOneWidget);
    expect(find.text('Olho de Editor'), findsOneWidget);
    expect(find.text('Dica Aberta'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('opções muta efeitos e salva preferência', (tester) async {
    SharedPreferences.setMockInitialValues({'intro_seen_v1': true});
    await tester.pumpWidget(const WordMazeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('app_options_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Efeitos'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('effects_enabled_v1'), isFalse);
  });

  testWidgets('opções salva modo de dica aberta', (tester) async {
    SharedPreferences.setMockInitialValues({'intro_seen_v1': true});
    await tester.pumpWidget(const WordMazeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('app_options_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dica Aberta'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('hint_display_mode_v1'), 'dicaAberta');
  });
}

class _RouteRecorder extends NavigatorObserver {
  final pushedRouteNames = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRouteNames.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}
