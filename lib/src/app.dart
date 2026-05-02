import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jogopalavras/src/core/audio/game_music_service.dart';
import 'package:jogopalavras/src/core/errors/app_error_reporter.dart';
import 'package:jogopalavras/src/core/updates/app_update_service.dart';
import 'package:jogopalavras/src/game/intro_preferences.dart';
import 'package:jogopalavras/src/navigation/app_route_observer.dart';
import 'package:jogopalavras/src/screens/intro_screen.dart';
import 'package:jogopalavras/src/screens/level_screen.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';
import 'package:jogopalavras/src/widgets/app_backdrop.dart';

class WordMazeApp extends StatefulWidget {
  const WordMazeApp({super.key});

  @override
  State<WordMazeApp> createState() => _WordMazeAppState();
}

class _WordMazeAppState extends State<WordMazeApp> with WidgetsBindingObserver {
  late final Future<bool> _hasSeenIntro = IntroPreferences.hasSeenIntro();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startAppMusic();
    unawaited(AppUpdateService.instance.checkForImmediateUpdate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startAppMusic();
      unawaited(
        AppUpdateService.instance.checkForImmediateUpdate(
          allowNewPrompt: false,
        ),
      );
      return;
    }

    GameMusicService.instance.pause();
  }

  Future<void> _startAppMusic() async {
    await GameMusicService.instance.playAppMusic();
    if (!mounted) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Entreletras: Palavras Ocultas',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        AppErrorReporter.instance.routeObserver,
        appRouteObserver,
      ],
      home: FutureBuilder<bool>(
        future: _hasSeenIntro,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const IntroScreen();
          }

          if (!snapshot.hasData) {
            return const _StartupScreen();
          }

          return snapshot.data! ? const LevelScreen() : const IntroScreen();
        },
      ),
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppBackdrop(
        primary: AppTheme.pressBlue,
        secondary: AppTheme.pressRed,
        child: Center(
          child: SizedBox.square(
            dimension: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      ),
    );
  }
}
