import 'package:jogopalavras/src/game/game_level.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WordProgressStore {
  const WordProgressStore._();

  static const WordProgressStore instance = WordProgressStore._();
  static const String _keyPrefix = 'word_progress_used_v1';

  Future<Set<String>> loadUsedWords(GameLevel level) async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_keyFor(level)) ?? <String>[]).toSet();
  }

  Future<Set<String>> markWordsUsed(
    GameLevel level,
    Iterable<String> words,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final usedWords = await loadUsedWords(level);
    usedWords.addAll(words.map((word) => word.toUpperCase()));

    await preferences.setStringList(_keyFor(level), usedWords.toList()..sort());
    return usedWords;
  }

  Future<void> resetLevel(GameLevel level) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_keyFor(level));
  }

  String _keyFor(GameLevel level) => '$_keyPrefix:${level.name}';
}
