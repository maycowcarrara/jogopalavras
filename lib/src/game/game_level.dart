import 'package:flutter/material.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';

enum GameLevel { easy, medium, hard }

extension GameLevelDetails on GameLevel {
  String get title => switch (this) {
    GameLevel.easy => 'Fácil',
    GameLevel.medium => 'Médio',
    GameLevel.hard => 'Difícil',
  };

  String get subtitle => switch (this) {
    GameLevel.easy => 'Palavras curtas e bem familiares',
    GameLevel.medium => 'Mistura equilibrada para ganhar ritmo',
    GameLevel.hard => 'Desafio com palavras maiores e tabuleiro amplo',
  };

  String get tag => switch (this) {
    GameLevel.easy => '4x4',
    GameLevel.medium => '6x6',
    GameLevel.hard => '8x8',
  };

  String get wordSizeShortLabel => switch (this) {
    GameLevel.easy => '4 letras',
    GameLevel.medium => '5-7 letras',
    GameLevel.hard => '7-9 letras',
  };

  String get wordSizeLabel => switch (this) {
    GameLevel.easy => 'Palavras de 4 letras',
    GameLevel.medium => 'Palavras de 5 a 7 letras',
    GameLevel.hard => 'Palavras de 7 a 9 letras',
  };

  int get gridSize => switch (this) {
    GameLevel.easy => 4,
    GameLevel.medium => 6,
    GameLevel.hard => 8,
  };

  Color get accent => switch (this) {
    GameLevel.easy => AppTheme.mint,
    GameLevel.medium => AppTheme.amber,
    GameLevel.hard => AppTheme.coral,
  };

  IconData get icon => switch (this) {
    GameLevel.easy => Icons.auto_awesome,
    GameLevel.medium => Icons.bolt,
    GameLevel.hard => Icons.local_fire_department,
  };

  String get sceneTitle => switch (this) {
    GameLevel.easy => 'Jardim em revelacao',
    GameLevel.medium => 'Oficina em movimento',
    GameLevel.hard => 'Templo em chamas',
  };

  String get sceneSubtitle => switch (this) {
    GameLevel.easy => 'Cada acerto abre uma nova parte da paisagem.',
    GameLevel.medium => 'Monte palavras para energizar a cena.',
    GameLevel.hard => 'A rodada finaliza quando o painel ganha vida.',
  };

  List<Color> get sceneGradient => switch (this) {
    GameLevel.easy => const [
      Color(0xFFEEF6D8),
      Color(0xFFD4EDC5),
      Color(0xFFF8E7AF),
    ],
    GameLevel.medium => const [
      Color(0xFFFFE2BB),
      Color(0xFFF7BE73),
      Color(0xFFEB8A5B),
    ],
    GameLevel.hard => const [
      Color(0xFFFFD7C2),
      Color(0xFFE69568),
      Color(0xFFB54C5C),
    ],
  };

  IconData get sceneIcon => switch (this) {
    GameLevel.easy => Icons.park_rounded,
    GameLevel.medium => Icons.precision_manufacturing_rounded,
    GameLevel.hard => Icons.whatshot_rounded,
  };

  IconData get sceneAccentIcon => switch (this) {
    GameLevel.easy => Icons.wb_sunny_rounded,
    GameLevel.medium => Icons.flash_on_rounded,
    GameLevel.hard => Icons.nightlight_round,
  };

  String get soundtrackLabel => switch (this) {
    GameLevel.easy => 'Brisa calma',
    GameLevel.medium => 'Pulso arcade',
    GameLevel.hard => 'Chama intensa',
  };

  String get soundtrackAsset => switch (this) {
    GameLevel.easy => 'audio/easy_loop.wav',
    GameLevel.medium => 'audio/medium_loop.wav',
    GameLevel.hard => 'audio/hard_loop.wav',
  };

  double get soundtrackVolume => switch (this) {
    GameLevel.easy => 0.34,
    GameLevel.medium => 0.38,
    GameLevel.hard => 0.42,
  };
}
