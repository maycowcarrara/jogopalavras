import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jogopalavras/src/app.dart';
import 'package:jogopalavras/src/game/campaign_stage_rules.dart';
import 'package:jogopalavras/src/game/game_level.dart';
import 'package:jogopalavras/src/game/ranking_store.dart';
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
    expect(
      find.text(
        'O jogo pode exibir anúncios em pausas naturais para manter a experiência gratuita.',
      ),
      findsOneWidget,
    );
    expect(find.text('Iniciar jogo'), findsOneWidget);

    await tester.ensureVisible(find.text('Iniciar jogo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar jogo'));
    await tester.pumpAndSettle();

    expect(find.text('Mapa da edição'), findsOneWidget);
    expect(find.text('Pauta'), findsAtLeastNWidgets(1));
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

    expect(find.text('Melhores: Redação 1'), findsOneWidget);
    expect(find.text('Jogar Redação 1'), findsOneWidget);

    await tester.tap(find.text('Jogar Redação 1'));
    await tester.pumpAndSettle();

    expect(find.text('0/8 palavras'), findsOneWidget);
  });

  testWidgets('ranking mantém engrenagem alinhada no appbar', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(home: RankingScreen(initialLevel: GameLevel.medium)),
    );
    await tester.pumpAndSettle();

    final appBarRect = tester.getRect(find.byType(AppBar));
    final buttonRect = tester.getRect(
      find.byKey(const ValueKey<String>('app_options_button')),
    );

    expect(buttonRect.height, closeTo(42, 0.1));
    expect(
      buttonRect.center.dy,
      closeTo(appBarRect.top + kToolbarHeight / 2, 0.1),
    );
    expect(buttonRect.right, closeTo(appBarRect.right - 12, 0.1));
  });

  testWidgets('ranking destaca resultado recém-gravado antes da lista', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 4, 30);
    final highlightEntry = RankingEntry(
      initials: 'MAY',
      level: GameLevel.easy,
      stageNumber: 1,
      score: RankingStore.scoreForPerformance(
        level: GameLevel.easy,
        words: 10,
        elapsedSeconds: 90,
      ),
      words: 10,
      elapsedSeconds: 90,
      completedAt: now.add(const Duration(seconds: 1)),
    );

    await RankingStore.instance.saveEntry(
      RankingEntry(
        initials: 'AAA',
        level: GameLevel.easy,
        stageNumber: 1,
        score: RankingStore.scoreForPerformance(
          level: GameLevel.easy,
          words: 10,
          elapsedSeconds: 80,
        ),
        words: 10,
        elapsedSeconds: 80,
        completedAt: now,
      ),
    );
    await RankingStore.instance.saveEntry(highlightEntry);

    await tester.pumpWidget(
      MaterialApp(
        home: RankingScreen(
          initialLevel: GameLevel.easy,
          initialStageNumber: 1,
          highlightEntry: highlightEntry,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Seu resultado'), findsOneWidget);
    expect(find.text('Sua rodada ficou em #2 com 610 pontos.'), findsOneWidget);
    expect(find.text('MAY'), findsOneWidget);
  });

  testWidgets('ranking com resultado mostra cinco antes e cinco depois', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime(2026, 4, 30);
    final entries = [
      for (var index = 1; index <= 20; index++)
        RankingEntry(
          initials: 'U${index.toString().padLeft(2, '0')}',
          level: GameLevel.easy,
          stageNumber: 1,
          score: RankingStore.scoreForPerformance(
            level: GameLevel.easy,
            words: 10,
            elapsedSeconds: index * 10,
          ),
          words: 10,
          elapsedSeconds: index * 10,
          completedAt: now.add(Duration(seconds: index)),
        ),
    ];
    final highlightEntry = entries[9];

    await tester.pumpWidget(
      MaterialApp(
        home: RankingScreen(
          initialLevel: GameLevel.easy,
          initialStageNumber: 1,
          highlightEntry: highlightEntry,
          initialEntries: entries,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mostrando #5 a #15 de 20'), findsOneWidget);
    expect(find.text('U04'), findsNothing);
    expect(find.text('U05'), findsOneWidget);
    expect(find.text('U10'), findsOneWidget);
    expect(find.text('U15'), findsOneWidget);
    expect(find.text('U16'), findsNothing);
  });

  testWidgets('continuar após fechar Pauta abre Apuração', (tester) async {
    SharedPreferences.setMockInitialValues({
      'word_progress_used_v1:easy': List<String>.generate(
        100,
        (index) => 'PALAVRA_$index',
      ),
    });
    final highlightEntry = RankingEntry(
      initials: 'MAY',
      level: GameLevel.easy,
      stageNumber: 10,
      score: RankingStore.scoreForPerformance(
        level: GameLevel.easy,
        words: 10,
        elapsedSeconds: 90,
      ),
      words: 10,
      elapsedSeconds: 90,
      completedAt: DateTime(2026, 5, 2),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RankingScreen(
          initialLevel: GameLevel.easy,
          initialStageNumber: 10,
          highlightEntry: highlightEntry,
          initialEntries: [highlightEntry],
          continueLevel: GameLevel.easy,
          continueStageNumber: 11,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continuar em Apuração'), findsOneWidget);

    await tester.tap(find.text('Continuar em Apuração'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Apuração 11/19'), findsOneWidget);
    expect(find.text('0/10 palavras'), findsOneWidget);
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

    expect(find.textContaining('Jogar Pauta 1/'), findsOneWidget);

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

    expect(find.textContaining('Jogar Pauta 2/'), findsOneWidget);
  });

  testWidgets('mapa mostra posição do ranking em fase concluída', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'intro_seen_v1': true,
      'ranking_last_initials_v1': 'MAY',
      'word_progress_used_v1:easy': List<String>.generate(
        10,
        (index) => 'PALAVRA_$index',
      ),
    });
    await RankingStore.instance.saveCachedStagePosition(
      initials: 'MAY',
      level: GameLevel.easy,
      stageNumber: 1,
      position: 2,
    );

    await tester.pumpWidget(const MaterialApp(home: LevelScreen()));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Sua última posição conhecida: #2'), findsOneWidget);
  });

  testWidgets(
    'mapa libera próximo nível quando progresso antigo já completou',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'intro_seen_v1': true,
        'word_progress_used_v1:easy': List<String>.generate(
          campaignRequiredWordCountForLevel(GameLevel.easy),
          (index) => 'PALAVRA_$index',
        ),
      });

      await tester.pumpWidget(const MaterialApp(home: LevelScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Jogar Redação 1/'), findsOneWidget);
      expect(find.text('Redação'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets('pauta livre mostra posição conhecida do ranking', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'intro_seen_v1': true,
      'ranking_last_initials_v1': 'MAY',
    });
    await RankingStore.instance.saveCachedStagePosition(
      initials: 'MAY',
      level: GameLevel.pautaLivre,
      stageNumber: 0,
      position: 4,
    );

    await tester.pumpWidget(const MaterialApp(home: LevelScreen()));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Sua última posição conhecida: #4'), findsOneWidget);
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

  testWidgets('opções persiste modo de dica escolhido', (tester) async {
    SharedPreferences.setMockInitialValues({'intro_seen_v1': true});
    await tester.pumpWidget(const WordMazeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('app_options_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Olho de Editor'));
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
