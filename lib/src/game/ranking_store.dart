import 'dart:convert';

import 'package:jogopalavras/src/game/game_level.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RankingEntry {
  const RankingEntry({
    required this.initials,
    required this.level,
    required this.score,
    required this.words,
    required this.elapsedSeconds,
    required this.completedAt,
  });

  factory RankingEntry.fromJson(Map<String, Object?> json) {
    return RankingEntry(
      initials: (json['initials'] as String? ?? '---').toUpperCase(),
      level: _levelFromName(json['level'] as String?),
      score: json['score'] as int? ?? 0,
      words: json['words'] as int? ?? 0,
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String initials;
  final GameLevel level;
  final int score;
  final int words;
  final int elapsedSeconds;
  final DateTime completedAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'initials': initials,
      'level': level.name,
      'score': score,
      'words': words,
      'elapsedSeconds': elapsedSeconds,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}

GameLevel _levelFromName(String? name) {
  for (final level in GameLevel.values) {
    if (level.name == name) {
      return level;
    }
  }

  return GameLevel.easy;
}

class RankingStore {
  const RankingStore._();

  static const RankingStore instance = RankingStore._();
  static const int maxEntries = 10;
  static const Duration _requestTimeout = Duration(seconds: 6);
  static const String _storageKey = 'ranking_entries_v1';
  static const String _apiBaseUrl = String.fromEnvironment('RANKING_API_URL');

  Future<List<RankingEntry>> loadEntries({GameLevel? level}) async {
    if (_apiBaseUrl.isNotEmpty) {
      final remoteEntries = await _loadRemoteEntries(level: level);
      if (remoteEntries != null) {
        return remoteEntries;
      }
    }

    return _loadLocalEntries(level: level);
  }

  Future<List<RankingEntry>> saveEntry(RankingEntry entry) async {
    if (_apiBaseUrl.isNotEmpty) {
      final remoteEntries = await _saveRemoteEntry(entry);
      if (remoteEntries != null) {
        return remoteEntries;
      }
    }

    return _saveLocalEntry(entry);
  }

  Future<List<RankingEntry>> _loadLocalEntries({GameLevel? level}) async {
    final preferences = await SharedPreferences.getInstance();
    final rawEntries = preferences.getStringList(_storageKey) ?? <String>[];
    final entries = rawEntries
        .map((rawEntry) {
          try {
            final decoded = jsonDecode(rawEntry);
            if (decoded is Map<String, dynamic>) {
              return RankingEntry.fromJson(decoded);
            }
          } on Object {
            return null;
          }
          return null;
        })
        .nonNulls
        .where((entry) => level == null || entry.level == level)
        .toList();

    _sortEntries(entries);
    return entries;
  }

  Future<List<RankingEntry>> _saveLocalEntry(RankingEntry entry) async {
    final preferences = await SharedPreferences.getInstance();
    final entries = await _loadLocalEntries();
    entries.add(entry);
    final groupedEntries = <RankingEntry>[
      for (final level in GameLevel.values)
        ..._bestEntriesForLevel(
          entries.where((entry) => entry.level == level).toList(),
        ),
    ];

    await preferences.setStringList(
      _storageKey,
      groupedEntries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );

    return _loadLocalEntries(level: entry.level);
  }

  Future<List<RankingEntry>?> _loadRemoteEntries({GameLevel? level}) async {
    try {
      final uri = _rankingUri(level: level);
      final response = await http.get(uri).timeout(_requestTimeout);
      if (response.statusCode != 200) {
        return null;
      }

      return _entriesFromResponse(response.body, level: level);
    } on Object {
      return null;
    }
  }

  Future<List<RankingEntry>?> _saveRemoteEntry(RankingEntry entry) async {
    try {
      final response = await http
          .post(
            _rankingUri(),
            headers: const <String, String>{
              'content-type': 'application/json',
            },
            body: jsonEncode(entry.toJson()),
          )
          .timeout(_requestTimeout);
      if (response.statusCode != 200 && response.statusCode != 201) {
        return null;
      }

      return _entriesFromResponse(response.body, level: entry.level);
    } on Object {
      return null;
    }
  }

  Uri _rankingUri({GameLevel? level}) {
    final baseUri = Uri.parse(_apiBaseUrl);
    final path = baseUri.path.endsWith('/ranking')
        ? baseUri.path
        : '${baseUri.path.replaceFirst(RegExp(r'/$'), '')}/ranking';

    return baseUri.replace(
      path: path,
      queryParameters: <String, String>{
        if (level != null) 'level': level.name,
      },
    );
  }

  List<RankingEntry>? _entriesFromResponse(String body, {GameLevel? level}) {
    try {
      final decoded = jsonDecode(body);
      final rawEntries = switch (decoded) {
        {'entries': final entries} => entries,
        final entries => entries,
      };

      if (rawEntries is! List) {
        return null;
      }

      final entries = rawEntries
          .whereType<Map<String, dynamic>>()
          .map(RankingEntry.fromJson)
          .where((entry) => level == null || entry.level == level)
          .toList();
      _sortEntries(entries);
      return entries.take(maxEntries).toList();
    } on Object {
      return null;
    }
  }

  static List<RankingEntry> bestEntries(List<RankingEntry> entries) {
    return _bestEntriesForLevel([...entries]);
  }

  static List<RankingEntry> _bestEntriesForLevel(List<RankingEntry> entries) {
    _sortEntries(entries);
    return entries.take(maxEntries).toList();
  }

  static void _sortEntries(List<RankingEntry> entries) {
    entries.sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);
      if (scoreComparison != 0) {
        return scoreComparison;
      }

      final wordComparison = a.words.compareTo(b.words);
      if (wordComparison != 0) {
        return wordComparison;
      }

      final timeComparison = a.elapsedSeconds.compareTo(b.elapsedSeconds);
      if (timeComparison != 0) {
        return timeComparison;
      }

      return a.completedAt.compareTo(b.completedAt);
    });
  }
}
