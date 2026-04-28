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
    GameLevel.medium => AppTheme.electricBlue,
    GameLevel.hard => AppTheme.coral,
  };

  IconData get icon => switch (this) {
    GameLevel.easy => Icons.article_outlined,
    GameLevel.medium => Icons.newspaper_rounded,
    GameLevel.hard => Icons.local_library_rounded,
  };

  String get sceneTitle => switch (this) {
    GameLevel.easy => 'Coluna leve',
    GameLevel.medium => 'Caderno principal',
    GameLevel.hard => 'Edição de domingo',
  };

  String get sceneSubtitle => switch (this) {
    GameLevel.easy => 'Cada acerto revela uma nova chamada.',
    GameLevel.medium => 'Monte palavras para fechar a manchete.',
    GameLevel.hard => 'Complete a página antes do fechamento.',
  };

  List<Color> get sceneGradient => switch (this) {
    GameLevel.easy => const [
      Color(0xFFFFFCF5),
      Color(0xFFEDE5D6),
      Color(0xFFD8CFBE),
    ],
    GameLevel.medium => const [
      Color(0xFFFFFCF5),
      Color(0xFFD7E0E3),
      Color(0xFF8DA5B1),
    ],
    GameLevel.hard => const [
      Color(0xFFFFFCF5),
      Color(0xFFE4CAC4),
      Color(0xFF9E2F2F),
    ],
  };

  IconData get sceneIcon => switch (this) {
    GameLevel.easy => Icons.short_text_rounded,
    GameLevel.medium => Icons.view_column_rounded,
    GameLevel.hard => Icons.menu_book_rounded,
  };

  IconData get sceneAccentIcon => switch (this) {
    GameLevel.easy => Icons.format_quote_rounded,
    GameLevel.medium => Icons.title_rounded,
    GameLevel.hard => Icons.history_edu_rounded,
  };

  String get soundtrackLabel => switch (this) {
    GameLevel.easy => 'Leitura calma',
    GameLevel.medium => 'Ritmo de foco',
    GameLevel.hard => 'Noite editorial',
  };

  String get soundtrackAsset => switch (this) {
    GameLevel.easy => 'audio/easy_loop.mp3',
    GameLevel.medium => 'audio/medium_loop.mp3',
    GameLevel.hard => 'audio/hard_loop.mp3',
  };

  double get soundtrackVolume => switch (this) {
    GameLevel.easy => 0.24,
    GameLevel.medium => 0.27,
    GameLevel.hard => 0.3,
  };
}
