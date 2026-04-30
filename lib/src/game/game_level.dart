import 'package:flutter/material.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';

enum GameLevel { easy, medium, hard, pautaLivre }

extension GameLevelDetails on GameLevel {
  String get title => switch (this) {
    GameLevel.easy => 'Fácil',
    GameLevel.medium => 'Médio',
    GameLevel.hard => 'Difícil',
    GameLevel.pautaLivre => 'Pauta Livre',
  };

  String get subtitle => switch (this) {
    GameLevel.easy => 'Palavras curtas e bem familiares',
    GameLevel.medium => 'Mistura equilibrada para ganhar ritmo',
    GameLevel.hard => 'Desafio com palavras maiores e tabuleiro amplo',
    GameLevel.pautaLivre => 'Uma rodada aleatória com todos os níveis',
  };

  String get tag => switch (this) {
    GameLevel.easy => '4x4',
    GameLevel.medium => '5x5',
    GameLevel.hard => '6x6',
    GameLevel.pautaLivre => '6x6',
  };

  String get wordSizeShortLabel => switch (this) {
    GameLevel.easy => '4 letras',
    GameLevel.medium => '5-7 letras',
    GameLevel.hard => '7-10 letras',
    GameLevel.pautaLivre => '4-10 letras',
  };

  String get wordSizeLabel => switch (this) {
    GameLevel.easy => 'Palavras de 4 letras',
    GameLevel.medium => 'Palavras de 5 a 7 letras',
    GameLevel.hard => 'Palavras de 7 a 10 letras',
    GameLevel.pautaLivre => 'Palavras de 4 a 10 letras',
  };

  int get gridSize => switch (this) {
    GameLevel.easy => 4,
    GameLevel.medium => 5,
    GameLevel.hard => 6,
    GameLevel.pautaLivre => 6,
  };

  int get targetWordCount => switch (this) {
    GameLevel.easy => 10,
    GameLevel.medium => 8,
    GameLevel.hard => 6,
    GameLevel.pautaLivre => 9,
  };

  Color get accent => switch (this) {
    GameLevel.easy => AppTheme.mint,
    GameLevel.medium => AppTheme.electricBlue,
    GameLevel.hard => AppTheme.coral,
    GameLevel.pautaLivre => AppTheme.pressGold,
  };

  IconData get icon => switch (this) {
    GameLevel.easy => Icons.article_outlined,
    GameLevel.medium => Icons.newspaper_rounded,
    GameLevel.hard => Icons.local_library_rounded,
    GameLevel.pautaLivre => Icons.dynamic_feed_rounded,
  };

  String get sceneTitle => switch (this) {
    GameLevel.easy => 'Coluna leve',
    GameLevel.medium => 'Caderno principal',
    GameLevel.hard => 'Edição de domingo',
    GameLevel.pautaLivre => 'Pauta Livre',
  };

  String get sceneSubtitle => switch (this) {
    GameLevel.easy => 'Cada acerto revela uma nova chamada.',
    GameLevel.medium => 'Monte palavras para fechar a manchete.',
    GameLevel.hard => 'Complete a página antes do fechamento.',
    GameLevel.pautaLivre => 'A rodada mistura pautas leves e manchetes fortes.',
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
    GameLevel.pautaLivre => const [
      Color(0xFFFFFCF5),
      Color(0xFFE5DDC8),
      Color(0xFFC9A227),
    ],
  };

  IconData get sceneIcon => switch (this) {
    GameLevel.easy => Icons.short_text_rounded,
    GameLevel.medium => Icons.view_column_rounded,
    GameLevel.hard => Icons.menu_book_rounded,
    GameLevel.pautaLivre => Icons.auto_stories_rounded,
  };

  IconData get sceneAccentIcon => switch (this) {
    GameLevel.easy => Icons.format_quote_rounded,
    GameLevel.medium => Icons.title_rounded,
    GameLevel.hard => Icons.history_edu_rounded,
    GameLevel.pautaLivre => Icons.bolt_rounded,
  };

  String get soundtrackLabel => switch (this) {
    GameLevel.easy => 'Leitura calma',
    GameLevel.medium => 'Ritmo de foco',
    GameLevel.hard => 'Noite editorial',
    GameLevel.pautaLivre => 'Plantão editorial',
  };

  String get soundtrackAsset => switch (this) {
    GameLevel.easy =>
      'audio/bodleasons-lofi-chill-smooth-chill-lofi-for-vlogs-and-background-music-159456.mp3',
    GameLevel.medium => 'audio/penguinmusic-better-day-186374.mp3',
    GameLevel.hard => 'audio/comastudio-order-99518.mp3',
    GameLevel.pautaLivre => 'audio/kontraa-water-afro-pop-music-445661.mp3',
  };

  double get soundtrackVolume => switch (this) {
    GameLevel.easy => 0.32,
    GameLevel.medium => 0.35,
    GameLevel.hard => 0.38,
    GameLevel.pautaLivre => 0.35,
  };

  bool get mixesAllLevels => this == GameLevel.pautaLivre;

  List<GameLevel> get sourceLevels => switch (this) {
    GameLevel.easy => const [GameLevel.easy],
    GameLevel.medium => const [GameLevel.medium],
    GameLevel.hard => const [GameLevel.hard],
    GameLevel.pautaLivre => const [
      GameLevel.easy,
      GameLevel.medium,
      GameLevel.hard,
    ],
  };
}
