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
    this.stageNumber = 0,
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
      stageNumber: _stageNumberFromJson(json['stageNumber'] ?? json['stage']),
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
  final int stageNumber;
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
      'stageNumber': stageNumber,
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

class RankingEntriesResult {
  const RankingEntriesResult({
    required this.entries,
    required this.startPosition,
    required this.totalEntries,
    this.highlightedPosition,
  });

  factory RankingEntriesResult.fromFullEntries(
    List<RankingEntry> entries, {
    RankingEntry? highlightedEntry,
    int? limit,
  }) {
    final rankedEntries = RankingStore.bestEntries(entries);
    final highlightedPosition = highlightedEntry == null
        ? null
        : rankedEntries.indexWhere(
                (entry) =>
                    RankingStore.samePerformance(entry, highlightedEntry),
              ) +
              1;

    if (highlightedEntry != null &&
        highlightedPosition != null &&
        highlightedPosition > 0) {
      return RankingEntriesResult.windowAround(
        rankedEntries,
        highlightedPosition: highlightedPosition,
      );
    }

    final cappedEntries = limit == null || limit <= 0
        ? rankedEntries
        : rankedEntries.take(limit).toList();
    return RankingEntriesResult(
      entries: cappedEntries,
      startPosition: cappedEntries.isEmpty ? 0 : 1,
      totalEntries: rankedEntries.length,
    );
  }

  factory RankingEntriesResult.windowAround(
    List<RankingEntry> rankedEntries, {
    required int highlightedPosition,
    int neighbors = 5,
  }) {
    if (highlightedPosition <= 0 || rankedEntries.isEmpty) {
      return RankingEntriesResult.fromFullEntries(rankedEntries);
    }

    final highlightIndex = highlightedPosition - 1;
    final start = (highlightIndex - neighbors).clamp(0, rankedEntries.length);
    final end = (highlightIndex + neighbors + 1).clamp(0, rankedEntries.length);
    return RankingEntriesResult(
      entries: rankedEntries.sublist(start, end),
      startPosition: start + 1,
      totalEntries: rankedEntries.length,
      highlightedPosition: highlightedPosition,
    );
  }

  final List<RankingEntry> entries;
  final int startPosition;
  final int totalEntries;
  final int? highlightedPosition;

  int get endPosition =>
      entries.isEmpty ? 0 : startPosition + entries.length - 1;
  bool get isPartial => entries.length < totalEntries;
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

int _stageNumberFromJson(Object? value) {
  final parsed = switch (value) {
    final int number => number,
    final String text => int.tryParse(text) ?? 0,
    _ => 0,
  };
  return parsed > 0 ? parsed : 0;
}

class RankingStore {
  const RankingStore._();

  static const RankingStore instance = RankingStore._();
  static const Duration _requestTimeout = Duration(seconds: 6);
  static const String _storageKey = 'ranking_entries_v1';
  static const String _lastInitialsKey = 'ranking_last_initials_v1';
  static const String _lastInitialsChangedAtKey =
      'ranking_last_initials_changed_at_v1';
  static const String _playerIdKey = 'ranking_player_id_v1';
  static const String _stagePositionsKey = 'ranking_stage_positions_v1';
  static const String _stagePositionsSyncedAtKey =
      'ranking_stage_positions_synced_at_v1';
  static const String _entriesCacheKey = 'ranking_entries_cache_v1';
  static const Duration initialsChangeCooldown = Duration(days: 30);
  static const Duration entriesCacheTtl = Duration(minutes: 10);
  static const Duration stagePositionsCacheTtl = Duration(minutes: 10);
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

  Future<List<RankingEntry>> loadEntries({
    GameLevel? level,
    int? stageNumber,
    int? limit,
    RankingEntry? aroundEntry,
    bool forceRefresh = false,
  }) async {
    final result = await loadEntriesResult(
      level: level,
      stageNumber: stageNumber,
      limit: limit,
      aroundEntry: aroundEntry,
      forceRefresh: forceRefresh,
    );
    return result.entries;
  }

  Future<RankingEntriesResult> loadEntriesResult({
    GameLevel? level,
    int? stageNumber,
    int? limit,
    RankingEntry? aroundEntry,
    bool forceRefresh = false,
  }) async {
    final localEntries = await _loadLocalEntries(
      level: level,
      stageNumber: stageNumber,
    );

    if (!forceRefresh) {
      final cachedResult = await _loadCachedEntriesResult(
        level: level,
        stageNumber: stageNumber,
        limit: limit,
        aroundEntry: aroundEntry,
      );
      if (cachedResult != null) {
        return _mergeResult(cachedResult, localEntries, aroundEntry);
      }
    }

    if (_apiBaseUrl.isNotEmpty) {
      final remoteResult = await _loadRemoteEntriesResult(
        level: level,
        stageNumber: stageNumber,
        limit: limit,
        aroundEntry: aroundEntry,
      );
      if (remoteResult != null) {
        final result = _mergeResult(remoteResult, localEntries, aroundEntry);
        await _saveCachedEntriesResult(
          result,
          level: level,
          stageNumber: stageNumber,
          limit: limit,
          aroundEntry: aroundEntry,
        );
        return result;
      }
    }

    return RankingEntriesResult.fromFullEntries(
      localEntries,
      highlightedEntry: aroundEntry,
      limit: limit,
    );
  }

  Future<List<RankingEntry>> saveEntry(RankingEntry entry) async {
    final result = await saveEntryResult(entry);
    return result.entries;
  }

  Future<RankingEntriesResult> saveEntryResult(RankingEntry entry) async {
    await saveLastInitials(entry.initials);
    final localEntries = await _saveLocalEntry(entry);

    if (_apiBaseUrl.isNotEmpty) {
      final remoteResult = await _saveRemoteEntryResult(entry);
      if (remoteResult != null) {
        final result = _mergeResult(remoteResult, localEntries, entry);
        await cacheStagePositionForEntry(entry, result.entries);
        await _saveCachedEntriesResult(
          result,
          level: entry.level,
          stageNumber: entry.stageNumber > 0 ? entry.stageNumber : null,
          aroundEntry: entry,
        );
        return result;
      }
    }

    await cacheStagePositionForEntry(entry, localEntries);
    return RankingEntriesResult.fromFullEntries(
      localEntries,
      highlightedEntry: entry,
    );
  }

  Future<Map<String, int>> loadCachedStagePositions() async {
    final initials = await loadLastInitials();
    if (initials.isEmpty) {
      return const <String, int>{};
    }

    final preferences = await SharedPreferences.getInstance();
    final rawPositions = preferences.getString(_stagePositionsKey);
    if (rawPositions == null) {
      return const <String, int>{};
    }

    try {
      final decoded = jsonDecode(rawPositions);
      if (decoded is! Map<String, dynamic>) {
        return const <String, int>{};
      }

      final positions = <String, int>{};
      for (final MapEntry(:key, :value) in decoded.entries) {
        final parts = key.split(':');
        if (parts.length != 3 || parts.first != initials) {
          continue;
        }

        final stageNumber = int.tryParse(parts[2]) ?? 0;
        final position = value is int ? value : int.tryParse('$value') ?? 0;
        if (stageNumber >= 0 && position > 0) {
          positions['${parts[1]}:$stageNumber'] = position;
        }
      }

      return positions;
    } on Object {
      return const <String, int>{};
    }
  }

  Future<Map<String, int>> syncCachedStagePositions({
    bool forceRefresh = false,
  }) async {
    final cachedPositions = await loadCachedStagePositions();
    final initials = await loadLastInitials();
    if (_apiBaseUrl.isEmpty || initials.isEmpty) {
      return cachedPositions;
    }

    final preferences = await SharedPreferences.getInstance();
    if (!forceRefresh) {
      final syncedAt = DateTime.tryParse(
        preferences.getString(_stagePositionsSyncedAtKey) ?? '',
      );
      if (syncedAt != null &&
          DateTime.now().difference(syncedAt) < stagePositionsCacheTtl) {
        return cachedPositions;
      }
    }

    try {
      final response = await http
          .get(_positionsUri(initials: initials))
          .timeout(_requestTimeout);
      if (response.statusCode != 200) {
        return cachedPositions;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return cachedPositions;
      }

      final rawPositions = decoded['positions'];
      if (rawPositions is! Map<String, dynamic>) {
        return cachedPositions;
      }

      final positions = <String, int>{};
      for (final MapEntry(:key, :value) in rawPositions.entries) {
        final parts = key.split(':');
        if (parts.length != 2) {
          continue;
        }

        final level = _levelFromName(parts[0]);
        final stageNumber = int.tryParse(parts[1]) ?? 0;
        final position = value is int ? value : int.tryParse('$value') ?? 0;
        if (stageNumber >= 0 && position > 0) {
          positions['${level.name}:$stageNumber'] = position;
        }
      }

      await _replaceCachedStagePositions(
        initials: initials,
        positions: positions,
      );
      await preferences.setString(
        _stagePositionsSyncedAtKey,
        DateTime.now().toIso8601String(),
      );
      return positions;
    } on Object {
      return cachedPositions;
    }
  }

  Future<void> cacheStagePositionForEntry(
    RankingEntry entry,
    List<RankingEntry> entries,
  ) async {
    final rankedEntries = bestEntries(
      entries
          .where(
            (candidate) =>
                candidate.level == entry.level &&
                candidate.stageNumber == entry.stageNumber,
          )
          .toList(),
    );
    var position =
        rankedEntries.indexWhere(
          (candidate) => samePerformance(candidate, entry),
        ) +
        1;
    if (position <= 0) {
      position =
          rankedEntries.indexWhere(
            (candidate) => candidate.initials == entry.initials,
          ) +
          1;
    }

    if (position > 0) {
      await saveCachedStagePosition(
        initials: entry.initials,
        level: entry.level,
        stageNumber: entry.stageNumber,
        position: position,
      );
    }
  }

  Future<void> cacheCurrentStagePosition({
    required GameLevel level,
    required int? stageNumber,
    required List<RankingEntry> entries,
  }) async {
    if (stageNumber == null || stageNumber < 0) {
      return;
    }

    final initials = await loadLastInitials();
    if (initials.isEmpty) {
      return;
    }

    final rankedEntries = bestEntries(
      entries
          .where(
            (entry) => entry.level == level && entry.stageNumber == stageNumber,
          )
          .toList(),
    );
    final position =
        rankedEntries.indexWhere((entry) => entry.initials == initials) + 1;
    if (position > 0) {
      await saveCachedStagePosition(
        initials: initials,
        level: level,
        stageNumber: stageNumber,
        position: position,
      );
    }
  }

  Future<void> saveCachedStagePosition({
    required String initials,
    required GameLevel level,
    required int stageNumber,
    required int position,
  }) async {
    final sanitizedInitials = _sanitizeInitials(initials);
    if (sanitizedInitials == null || stageNumber < 0 || position <= 0) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final rawPositions = preferences.getString(_stagePositionsKey);
    final positions = <String, Object?>{};
    if (rawPositions != null) {
      try {
        final decoded = jsonDecode(rawPositions);
        if (decoded is Map<String, dynamic>) {
          positions.addAll(decoded);
        }
      } on Object {
        positions.clear();
      }
    }

    positions['$sanitizedInitials:${level.name}:$stageNumber'] = position;
    await preferences.setString(_stagePositionsKey, jsonEncode(positions));
  }

  Future<void> _replaceCachedStagePositions({
    required String initials,
    required Map<String, int> positions,
  }) async {
    final sanitizedInitials = _sanitizeInitials(initials);
    if (sanitizedInitials == null) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final rawPositions = preferences.getString(_stagePositionsKey);
    final nextPositions = <String, Object?>{};
    if (rawPositions != null) {
      try {
        final decoded = jsonDecode(rawPositions);
        if (decoded is Map<String, dynamic>) {
          for (final MapEntry(:key, :value) in decoded.entries) {
            if (!key.startsWith('$sanitizedInitials:')) {
              nextPositions[key] = value;
            }
          }
        }
      } on Object {
        nextPositions.clear();
      }
    }

    for (final MapEntry(:key, :value) in positions.entries) {
      nextPositions['$sanitizedInitials:$key'] = value;
    }

    await preferences.setString(_stagePositionsKey, jsonEncode(nextPositions));
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

  Future<List<RankingEntry>> _loadLocalEntries({
    GameLevel? level,
    int? stageNumber,
  }) async {
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
        .where(
          (entry) => stageNumber == null || entry.stageNumber == stageNumber,
        )
        .toList();

    final dedupedEntries = _dedupeEntries(entries);
    _sortEntries(dedupedEntries);
    return dedupedEntries;
  }

  Future<List<RankingEntry>> _saveLocalEntry(RankingEntry entry) async {
    final preferences = await SharedPreferences.getInstance();
    final entries = _dedupeEntries([...await _loadLocalEntries(), entry]);
    final groupedEntries = <RankingEntry>[];
    final buckets = <String, List<RankingEntry>>{};
    for (final entry in entries) {
      final key = '${entry.level.name}:${entry.stageNumber}';
      buckets.putIfAbsent(key, () => <RankingEntry>[]).add(entry);
    }
    for (final bucket in buckets.values) {
      groupedEntries.addAll(_rankedEntries(bucket));
    }

    await preferences.setStringList(
      _storageKey,
      groupedEntries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );

    return _loadLocalEntries(
      level: entry.level,
      stageNumber: entry.stageNumber > 0 ? entry.stageNumber : null,
    );
  }

  Future<RankingEntriesResult?> _loadRemoteEntriesResult({
    GameLevel? level,
    int? stageNumber,
    int? limit,
    RankingEntry? aroundEntry,
  }) async {
    try {
      final uri = _rankingUri(
        level: level,
        stageNumber: stageNumber,
        limit: limit,
        aroundEntry: aroundEntry,
      );
      final response = await http.get(uri).timeout(_requestTimeout);
      if (response.statusCode != 200) {
        return null;
      }

      return _resultFromResponse(
        response.body,
        level: level,
        stageNumber: stageNumber,
        highlightedEntry: aroundEntry,
        limit: limit,
      );
    } on Object {
      return null;
    }
  }

  Future<RankingEntriesResult?> _saveRemoteEntryResult(
    RankingEntry entry,
  ) async {
    try {
      final response = await http
          .post(
            _rankingUri(
              stageNumber: entry.stageNumber,
              limit: 11,
              aroundEntry: entry,
            ),
            headers: const <String, String>{'content-type': 'application/json'},
            body: jsonEncode(entry.toJson()),
          )
          .timeout(_requestTimeout);
      if (response.statusCode != 200 && response.statusCode != 201) {
        return null;
      }

      return _resultFromResponse(
        response.body,
        level: entry.level,
        stageNumber: entry.stageNumber > 0 ? entry.stageNumber : null,
        highlightedEntry: entry,
      );
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
    final id = List<int>.generate(
      24,
      (_) => random.nextInt(36),
    ).map((value) => value.toRadixString(36)).join();
    await preferences.setString(_playerIdKey, id);
    return id;
  }

  Uri _rankingUri({
    GameLevel? level,
    int? stageNumber,
    int? limit,
    RankingEntry? aroundEntry,
  }) {
    final baseUri = Uri.parse(_apiBaseUrl);
    final path = baseUri.path.endsWith('/ranking')
        ? baseUri.path
        : '${baseUri.path.replaceFirst(RegExp(r'/$'), '')}/ranking';

    return baseUri.replace(
      path: path,
      queryParameters: <String, String>{
        if (level != null) 'level': level.name,
        if (stageNumber != null && stageNumber > 0)
          'stage': stageNumber.toString(),
        if (limit != null && limit > 0) 'limit': limit.toString(),
        if (aroundEntry != null) ...{
          'aroundInitials': aroundEntry.initials,
          'aroundWords': aroundEntry.words.toString(),
          'aroundElapsed': aroundEntry.elapsedSeconds.toString(),
          'aroundErrors': aroundEntry.errors.toString(),
          'aroundHints': aroundEntry.hintsUsed.toString(),
          'aroundSkips': aroundEntry.skipsUsed.toString(),
        },
      },
    );
  }

  Uri _playersUri() {
    final baseUri = Uri.parse(_apiBaseUrl);
    final path = '${baseUri.path.replaceFirst(RegExp(r'/$'), '')}/players';
    return baseUri.replace(path: path);
  }

  Uri _positionsUri({required String initials}) {
    final baseUri = Uri.parse(_apiBaseUrl);
    final path = '${baseUri.path.replaceFirst(RegExp(r'/$'), '')}/positions';
    return baseUri.replace(
      path: path,
      queryParameters: <String, String>{'initials': initials},
    );
  }

  RankingEntriesResult? _resultFromResponse(
    String body, {
    GameLevel? level,
    int? stageNumber,
    RankingEntry? highlightedEntry,
    int? limit,
  }) {
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
          .where(
            (entry) => stageNumber == null || entry.stageNumber == stageNumber,
          )
          .toList();
      _sortEntries(entries);
      if (decoded is Map<String, dynamic>) {
        final startPosition =
            _positiveIntFromJson(decoded['startPosition']) ??
            (entries.isEmpty ? 0 : 1);
        final totalEntries =
            _positiveIntFromJson(decoded['totalEntries']) ?? entries.length;
        final highlightedPosition = _positiveIntFromJson(
          decoded['highlightedPosition'],
        );

        return RankingEntriesResult(
          entries: entries,
          startPosition: startPosition,
          totalEntries: totalEntries,
          highlightedPosition: highlightedPosition,
        );
      }

      return RankingEntriesResult.fromFullEntries(
        entries,
        highlightedEntry: highlightedEntry,
        limit: limit,
      );
    } on Object {
      return null;
    }
  }

  int? _positiveIntFromJson(Object? value) {
    final parsed = switch (value) {
      final int number => number,
      final String text => int.tryParse(text) ?? 0,
      _ => 0,
    };
    return parsed > 0 ? parsed : null;
  }

  Future<RankingEntriesResult?> _loadCachedEntriesResult({
    GameLevel? level,
    int? stageNumber,
    int? limit,
    RankingEntry? aroundEntry,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final cache = _entriesCacheFromJson(
      preferences.getString(_entriesCacheKey),
    );
    final rawEntry =
        cache[_entriesCacheLookupKey(
          level: level,
          stageNumber: stageNumber,
          limit: limit,
          aroundEntry: aroundEntry,
        )];
    if (rawEntry is! Map<String, dynamic>) {
      return null;
    }

    final cachedAt = DateTime.tryParse(rawEntry['cachedAt'] as String? ?? '');
    if (cachedAt == null ||
        DateTime.now().difference(cachedAt) > entriesCacheTtl) {
      return null;
    }

    final rawEntries = rawEntry['entries'];
    if (rawEntries is! List) {
      return null;
    }

    final entries = rawEntries
        .whereType<Map<String, dynamic>>()
        .map(RankingEntry.fromJson)
        .where((entry) => level == null || entry.level == level)
        .where(
          (entry) => stageNumber == null || entry.stageNumber == stageNumber,
        )
        .toList();
    _sortEntries(entries);

    return RankingEntriesResult(
      entries: entries,
      startPosition:
          _positiveIntFromJson(rawEntry['startPosition']) ??
          (entries.isEmpty ? 0 : 1),
      totalEntries:
          _positiveIntFromJson(rawEntry['totalEntries']) ?? entries.length,
      highlightedPosition: _positiveIntFromJson(
        rawEntry['highlightedPosition'],
      ),
    );
  }

  Future<void> _saveCachedEntriesResult(
    RankingEntriesResult result, {
    GameLevel? level,
    int? stageNumber,
    int? limit,
    RankingEntry? aroundEntry,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final cache = _entriesCacheFromJson(
      preferences.getString(_entriesCacheKey),
    );
    cache[_entriesCacheLookupKey(
      level: level,
      stageNumber: stageNumber,
      limit: limit,
      aroundEntry: aroundEntry,
    )] = <String, Object?>{
      'cachedAt': DateTime.now().toIso8601String(),
      'entries': result.entries.map((entry) => entry.toJson()).toList(),
      'startPosition': result.startPosition,
      'totalEntries': result.totalEntries,
      if (result.highlightedPosition != null)
        'highlightedPosition': result.highlightedPosition,
    };
    await preferences.setString(_entriesCacheKey, jsonEncode(cache));
  }

  Map<String, Object?> _entriesCacheFromJson(String? rawValue) {
    if (rawValue == null) {
      return <String, Object?>{};
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is Map<String, dynamic>) {
        return <String, Object?>{...decoded};
      }
    } on Object {
      return <String, Object?>{};
    }
    return <String, Object?>{};
  }

  String _entriesCacheLookupKey({
    GameLevel? level,
    int? stageNumber,
    int? limit,
    RankingEntry? aroundEntry,
  }) {
    return [
      level?.name ?? 'all',
      stageNumber ?? 0,
      limit ?? 0,
      if (aroundEntry == null)
        'top'
      else
        [
          aroundEntry.initials,
          aroundEntry.words,
          aroundEntry.elapsedSeconds,
          aroundEntry.errors,
          aroundEntry.hintsUsed,
          aroundEntry.skipsUsed,
        ].join('-'),
    ].join(':');
  }

  static List<RankingEntry> bestEntries(List<RankingEntry> entries) {
    return _rankedEntries([...entries]);
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

  static List<RankingEntry> _rankedEntries(List<RankingEntry> entries) {
    _sortEntries(entries);
    return entries;
  }

  static List<RankingEntry> _mergedEntries(
    List<RankingEntry> primaryEntries,
    List<RankingEntry> fallbackEntries,
  ) {
    final merged = _dedupeEntries([...primaryEntries, ...fallbackEntries]);
    _sortEntries(merged);
    return merged;
  }

  static RankingEntriesResult _mergeResult(
    RankingEntriesResult primaryResult,
    List<RankingEntry> fallbackEntries,
    RankingEntry? highlightedEntry,
  ) {
    final mergedEntries = _mergedEntries(
      primaryResult.entries,
      fallbackEntries,
    );
    final totalEntries = max(primaryResult.totalEntries, mergedEntries.length);
    if (highlightedEntry == null) {
      return RankingEntriesResult(
        entries: mergedEntries,
        startPosition: primaryResult.startPosition,
        totalEntries: totalEntries,
        highlightedPosition: primaryResult.highlightedPosition,
      );
    }

    final highlightedInWindow =
        primaryResult.highlightedPosition != null &&
        primaryResult.entries.any(
          (entry) => samePerformance(entry, highlightedEntry),
        );
    if (highlightedInWindow) {
      return RankingEntriesResult(
        entries: mergedEntries,
        startPosition: primaryResult.startPosition,
        totalEntries: totalEntries,
        highlightedPosition: primaryResult.highlightedPosition,
      );
    }

    return RankingEntriesResult.fromFullEntries(
      mergedEntries,
      highlightedEntry: highlightedEntry,
    );
  }

  static List<RankingEntry> _dedupeEntries(List<RankingEntry> entries) {
    final seen = <String>{};
    final deduped = <RankingEntry>[];

    for (final entry in entries) {
      final key = _entryKey(entry);
      if (seen.add(key)) {
        deduped.add(entry);
      }
    }

    return deduped;
  }

  static String _entryKey(RankingEntry entry) {
    return [
      entry.initials,
      entry.level.name,
      entry.stageNumber,
      scoreForPerformance(
        level: entry.level,
        words: entry.words,
        elapsedSeconds: entry.elapsedSeconds,
        errors: entry.errors,
        hintsUsed: entry.hintsUsed,
        skipsUsed: entry.skipsUsed,
      ),
      entry.words,
      entry.elapsedSeconds,
      entry.errors,
      entry.hintsUsed,
      entry.skipsUsed,
    ].join(':');
  }

  static bool samePerformance(RankingEntry a, RankingEntry b) {
    return a.initials == b.initials &&
        a.level == b.level &&
        a.stageNumber == b.stageNumber &&
        a.words == b.words &&
        a.elapsedSeconds == b.elapsedSeconds &&
        a.errors == b.errors &&
        a.hintsUsed == b.hintsUsed &&
        a.skipsUsed == b.skipsUsed;
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
    return RegExp(r'^[A-Z0-9]{3,6}$').hasMatch(normalized) ? normalized : null;
  }
}
