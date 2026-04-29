import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
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
    this.errors = 0,
    this.hintsUsed = 0,
    this.skipsUsed = 0,
  });

  factory RankingEntry.fromJson(Map<String, Object?> json) {
    final words = json['words'] as int? ?? 0;
    final elapsedSeconds = json['elapsedSeconds'] as int? ?? 0;
    final errors = json['errors'] as int? ?? 0;
    final hintsUsed = json['hintsUsed'] as int? ?? 0;
    final skipsUsed = json['skipsUsed'] as int? ?? 0;
    final level = _levelFromName(json['level'] as String?);

    return RankingEntry(
      initials: (json['initials'] as String? ?? '---').toUpperCase(),
      level: level,
      score: RankingStore.scoreForPerformance(
        level: level,
        words: words,
        elapsedSeconds: elapsedSeconds,
        errors: errors,
        hintsUsed: hintsUsed,
        skipsUsed: skipsUsed,
      ),
      words: words,
      elapsedSeconds: elapsedSeconds,
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      errors: errors,
      hintsUsed: hintsUsed,
      skipsUsed: skipsUsed,
    );
  }

  final String initials;
  final GameLevel level;
  final int score;
  final int words;
  final int elapsedSeconds;
  final DateTime completedAt;
  final int errors;
  final int hintsUsed;
  final int skipsUsed;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'initials': initials,
      'level': level.name,
      'score': score,
      'words': words,
      'elapsedSeconds': elapsedSeconds,
      'completedAt': completedAt.toIso8601String(),
      'errors': errors,
      'hintsUsed': hintsUsed,
      'skipsUsed': skipsUsed,
    };
  }
}

enum InitialsUpdateStatus { saved, invalid, unavailable, cooldown }

class InitialsUpdateResult {
  const InitialsUpdateResult({
    required this.status,
    this.initials,
    this.remainingCooldown,
  });

  final InitialsUpdateStatus status;
  final String? initials;
  final Duration? remainingCooldown;

  bool get saved => status == InitialsUpdateStatus.saved;
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
  static const String _lastInitialsKey = 'ranking_last_initials_v1';
  static const String _lastInitialsChangedAtKey =
      'ranking_last_initials_changed_at_v1';
  static const String _playerIdKey = 'ranking_player_id_v1';
  static const Duration initialsChangeCooldown = Duration(days: 30);
  static const String _productionApiBaseUrl =
      'https://anagrama-oculto-ranking.maycowcarrara.workers.dev';
  static const String _apiBaseUrl = String.fromEnvironment(
    'RANKING_API_URL',
    defaultValue: kReleaseMode ? _productionApiBaseUrl : '',
  );
  static const int easyStartingScore = 1000;
  static const int mediumStartingScore = 1250;
  static const int hardStartingScore = 1500;
  static const int pautaLivreStartingScore = 1450;
  static const int pointsPerWord = 30;
  static const int pointsPerSecond = 1;
  static const int pointsPerError = 50;
  static const int pointsPerHint = 0;
  static const int pointsPerSkip = 160;

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
    await saveLastInitials(entry.initials);

    if (_apiBaseUrl.isNotEmpty) {
      final remoteEntries = await _saveRemoteEntry(entry);
      if (remoteEntries != null) {
        return remoteEntries;
      }
    }

    return _saveLocalEntry(entry);
  }

  Future<String> loadLastInitials() async {
    final preferences = await SharedPreferences.getInstance();
    final storedInitials = _sanitizeInitials(
      preferences.getString(_lastInitialsKey),
    );
    if (storedInitials != null) {
      return storedInitials;
    }

    final entries = await _loadLocalEntries();
    if (entries.isEmpty) {
      return '';
    }

    entries.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return _sanitizeInitials(entries.first.initials) ?? '';
  }

  Future<void> saveLastInitials(String initials) async {
    final sanitizedInitials = _sanitizeInitials(initials);
    if (sanitizedInitials == null) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastInitialsKey, sanitizedInitials);
  }

  Future<DateTime?> loadLastInitialsChangedAt() async {
    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(_lastInitialsChangedAtKey);
    return rawValue == null ? null : DateTime.tryParse(rawValue);
  }

  Future<Duration?> remainingInitialsCooldown({DateTime? now}) async {
    final changedAt = await loadLastInitialsChangedAt();
    if (changedAt == null) {
      return null;
    }

    final elapsed = (now ?? DateTime.now()).difference(changedAt);
    final remaining = initialsChangeCooldown - elapsed;
    return remaining.isNegative ? null : remaining;
  }

  Future<InitialsUpdateResult> updatePlayerInitials(
    String initials, {
    DateTime? now,
  }) async {
    final sanitizedInitials = _sanitizeInitials(initials);
    if (sanitizedInitials == null) {
      return const InitialsUpdateResult(status: InitialsUpdateStatus.invalid);
    }

    final currentInitials = await loadLastInitials();
    if (currentInitials == sanitizedInitials) {
      await saveLastInitials(sanitizedInitials);
      return InitialsUpdateResult(
        status: InitialsUpdateStatus.saved,
        initials: sanitizedInitials,
      );
    }

    final cooldown = await remainingInitialsCooldown(now: now);
    if (currentInitials.isNotEmpty && cooldown != null) {
      return InitialsUpdateResult(
        status: InitialsUpdateStatus.cooldown,
        remainingCooldown: cooldown,
      );
    }

    final reserved = await _reserveInitials(
      sanitizedInitials,
      previousInitials: currentInitials,
    );
    if (reserved == false) {
      return const InitialsUpdateResult(
        status: InitialsUpdateStatus.unavailable,
      );
    }

    if (reserved == null &&
        await _localInitialsAlreadyUsed(sanitizedInitials, currentInitials)) {
      return const InitialsUpdateResult(
        status: InitialsUpdateStatus.unavailable,
      );
    }

    final preferences = await SharedPreferences.getInstance();
    final changedAt = now ?? DateTime.now();
    await preferences.setString(_lastInitialsKey, sanitizedInitials);
    await preferences.setString(
      _lastInitialsChangedAtKey,
      changedAt.toIso8601String(),
    );

    return InitialsUpdateResult(
      status: InitialsUpdateStatus.saved,
      initials: sanitizedInitials,
    );
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
            headers: const <String, String>{'content-type': 'application/json'},
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

  Future<bool?> _reserveInitials(
    String initials, {
    required String previousInitials,
  }) async {
    if (_apiBaseUrl.isEmpty) {
      return null;
    }

    try {
      final playerId = await _loadPlayerId();
      final response = await http
          .post(
            _playersUri(),
            headers: const <String, String>{'content-type': 'application/json'},
            body: jsonEncode(<String, Object?>{
              'initials': initials,
              'previousInitials': previousInitials,
              'ownerId': playerId,
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 409) {
        return false;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      return null;
    } on Object {
      return null;
    }
  }

  Future<bool> _localInitialsAlreadyUsed(
    String initials,
    String currentInitials,
  ) async {
    if (currentInitials == initials) {
      return false;
    }

    final entries = await _loadLocalEntries();
    return entries.any((entry) => entry.initials == initials);
  }

  Future<String> _loadPlayerId() async {
    final preferences = await SharedPreferences.getInstance();
    final storedId = preferences.getString(_playerIdKey);
    if (storedId != null && storedId.length >= 16) {
      return storedId;
    }

    final random = Random.secure();
    final id = List<int>.generate(24, (_) => random.nextInt(36))
        .map((value) => value.toRadixString(36))
        .join();
    await preferences.setString(_playerIdKey, id);
    return id;
  }

  Uri _rankingUri({GameLevel? level}) {
    final baseUri = Uri.parse(_apiBaseUrl);
    final path = baseUri.path.endsWith('/ranking')
        ? baseUri.path
        : '${baseUri.path.replaceFirst(RegExp(r'/$'), '')}/ranking';

    return baseUri.replace(
      path: path,
      queryParameters: <String, String>{if (level != null) 'level': level.name},
    );
  }

  Uri _playersUri() {
    final baseUri = Uri.parse(_apiBaseUrl);
    final path = '${baseUri.path.replaceFirst(RegExp(r'/$'), '')}/players';
    return baseUri.replace(path: path);
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

  static int scoreForPerformance({
    required GameLevel level,
    required int words,
    required int elapsedSeconds,
    int errors = 0,
    int hintsUsed = 0,
    int skipsUsed = 0,
  }) {
    return max(
      0,
      startingScoreForLevel(level) -
          (words * pointsPerWord) -
          (elapsedSeconds * pointsPerSecond) -
          (errors * pointsPerError) -
          (hintsUsed * pointsPerHint) -
          (skipsUsed * pointsPerSkip),
    );
  }

  static List<RankingEntry> _bestEntriesForLevel(List<RankingEntry> entries) {
    _sortEntries(entries);
    return entries.take(maxEntries).toList();
  }

  static void _sortEntries(List<RankingEntry> entries) {
    entries.sort((a, b) {
      final scoreComparison =
          scoreForPerformance(
            level: b.level,
            words: b.words,
            elapsedSeconds: b.elapsedSeconds,
            errors: b.errors,
            hintsUsed: b.hintsUsed,
            skipsUsed: b.skipsUsed,
          ).compareTo(
            scoreForPerformance(
              level: a.level,
              words: a.words,
              elapsedSeconds: a.elapsedSeconds,
              errors: a.errors,
              hintsUsed: a.hintsUsed,
              skipsUsed: a.skipsUsed,
            ),
          );
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

  static int startingScoreForLevel(GameLevel level) {
    return switch (level) {
      GameLevel.easy => easyStartingScore,
      GameLevel.medium => mediumStartingScore,
      GameLevel.hard => hardStartingScore,
      GameLevel.pautaLivre => pautaLivreStartingScore,
    };
  }

  static String? _sanitizeInitials(String? initials) {
    final normalized = initials?.trim().toUpperCase() ?? '';
    return RegExp(r'^[A-Z]{3,5}$').hasMatch(normalized) ? normalized : null;
  }
}
