import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppErrorReporter {
  AppErrorReporter._();

  static final AppErrorReporter instance = AppErrorReporter._();

  static const String _productionApiBaseUrl =
      'https://anagrama-oculto-ranking.maycowcarrara.workers.dev';
  static const String _apiBaseUrl = String.fromEnvironment(
    'RANKING_API_URL',
    defaultValue: kReleaseMode ? _productionApiBaseUrl : '',
  );
  static const String _appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: 'unknown',
  );
  static const String _storageKey = 'app_error_logs_v1';
  static const int _maxStoredLogs = 30;
  static const int _maxBatchSize = 8;
  static const Duration _requestTimeout = Duration(seconds: 5);

  final NavigatorObserver routeObserver = _ErrorRouteObserver();

  SharedPreferences? _preferences;
  bool _isRecording = false;
  bool _isFlushing = false;
  String _currentRoute = 'startup';

  Future<void> initialize() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      await flushPendingLogs();
    } on Object {
      _preferences = null;
    }
  }

  void recordFlutterError(FlutterErrorDetails details) {
    FlutterError.presentError(details);
    unawaited(
      record(
        details.exception,
        details.stack,
        source: 'flutter',
        context: <String, Object?>{
          'library': details.library,
          'context': details.context?.toDescription(),
        },
      ),
    );
  }

  bool recordPlatformError(Object error, StackTrace stackTrace) {
    unawaited(record(error, stackTrace, source: 'platform', fatal: true));
    return true;
  }

  Future<void> record(
    Object error,
    StackTrace? stackTrace, {
    required String source,
    bool fatal = false,
    Map<String, Object?> context = const <String, Object?>{},
  }) async {
    if (_isRecording) {
      return;
    }

    _isRecording = true;
    try {
      final log = _ErrorLog(
        timestamp: DateTime.now().toUtc(),
        source: source,
        fatal: fatal,
        route: _currentRoute,
        errorType: error.runtimeType.toString(),
        message: _trim(error.toString(), 700),
        stackTrace: _trim(stackTrace?.toString() ?? '', 3200),
        platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
        appVersion: _appVersion,
        buildMode: kReleaseMode
            ? 'release'
            : kProfileMode
            ? 'profile'
            : 'debug',
        context: _sanitizeContext(context),
      );

      await _store(log);
      await flushPendingLogs();
    } on Object {
      // Error reporting must never become a second crash path.
    } finally {
      _isRecording = false;
    }
  }

  Future<void> flushPendingLogs() async {
    final preferences = _preferences;
    final endpoint = _logsUri();
    if (preferences == null || endpoint == null || _isFlushing) {
      return;
    }

    final rawLogs = preferences.getStringList(_storageKey) ?? <String>[];
    if (rawLogs.isEmpty) {
      return;
    }

    _isFlushing = true;
    try {
      final batch = rawLogs.take(_maxBatchSize).toList();
      final events = batch
          .map((raw) {
            try {
              final decoded = jsonDecode(raw);
              return decoded is Map<String, dynamic> ? decoded : null;
            } on Object {
              return null;
            }
          })
          .nonNulls
          .toList();

      if (events.isEmpty) {
        await preferences.setStringList(
          _storageKey,
          rawLogs.skip(batch.length).toList(),
        );
        return;
      }

      final response = await http
          .post(
            endpoint,
            headers: const <String, String>{'content-type': 'application/json'},
            body: jsonEncode(<String, Object?>{'events': events}),
          )
          .timeout(_requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await preferences.setStringList(
          _storageKey,
          rawLogs.skip(batch.length).toList(),
        );
      }
    } on Object {
      // Logs stay queued locally and will be retried on a later launch/error.
    } finally {
      _isFlushing = false;
    }
  }

  void updateRoute(Route<dynamic>? route) {
    final settings = route?.settings;
    _currentRoute = settings?.name?.isNotEmpty == true
        ? settings!.name!
        : route?.runtimeType.toString() ?? 'unknown';
  }

  Future<void> _store(_ErrorLog log) async {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }

    final rawLogs = preferences.getStringList(_storageKey) ?? <String>[];
    final nextLogs = <String>[...rawLogs, jsonEncode(log.toJson())];
    final trimmed = nextLogs.length > _maxStoredLogs
        ? nextLogs.sublist(nextLogs.length - _maxStoredLogs)
        : nextLogs;

    await preferences.setStringList(_storageKey, trimmed);
  }

  Uri? _logsUri() {
    if (_apiBaseUrl.isEmpty) {
      return null;
    }

    final baseUri = Uri.tryParse(_apiBaseUrl);
    if (baseUri == null || !baseUri.hasScheme || baseUri.host.isEmpty) {
      return null;
    }

    final normalizedPath = baseUri.path.replaceFirst(RegExp(r'/$'), '');
    final path = normalizedPath.endsWith('/ranking')
        ? '${normalizedPath.substring(0, normalizedPath.length - 8)}/logs'
        : '$normalizedPath/logs';

    return baseUri.replace(
      path: path,
      queryParameters: const <String, String>{},
    );
  }

  static Map<String, Object?> _sanitizeContext(Map<String, Object?> context) {
    final sanitized = <String, Object?>{};
    for (final entry in context.entries.take(12)) {
      final key = _trim(entry.key, 64);
      final value = entry.value;
      if (value == null || value is num || value is bool) {
        sanitized[key] = value;
      } else {
        sanitized[key] = _trim(value.toString(), 240);
      }
    }
    return sanitized;
  }

  static String _trim(String value, int maxLength) {
    final normalized = value.replaceAll(
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'),
      ' ',
    );
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return '${normalized.substring(0, maxLength)}...';
  }
}

class _ErrorRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppErrorReporter.instance.updateRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppErrorReporter.instance.updateRoute(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    AppErrorReporter.instance.updateRoute(newRoute);
  }
}

class _ErrorLog {
  const _ErrorLog({
    required this.timestamp,
    required this.source,
    required this.fatal,
    required this.route,
    required this.errorType,
    required this.message,
    required this.stackTrace,
    required this.platform,
    required this.appVersion,
    required this.buildMode,
    required this.context,
  });

  final DateTime timestamp;
  final String source;
  final bool fatal;
  final String route;
  final String errorType;
  final String message;
  final String stackTrace;
  final String platform;
  final String appVersion;
  final String buildMode;
  final Map<String, Object?> context;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'fatal': fatal,
      'route': route,
      'errorType': errorType,
      'message': message,
      'stackTrace': stackTrace,
      'platform': platform,
      'appVersion': appVersion,
      'buildMode': buildMode,
      'context': context,
    };
  }
}
