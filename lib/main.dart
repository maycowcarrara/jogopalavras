import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:jogopalavras/src/app.dart';
import 'package:jogopalavras/src/core/ads/ad_service.dart';
import 'package:jogopalavras/src/core/errors/app_error_fallback.dart';
import 'package:jogopalavras/src/core/errors/app_error_reporter.dart';

const bool _simulateErrorReport = bool.fromEnvironment('SIMULATE_ERROR_REPORT');

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      final errorReporter = AppErrorReporter.instance;
      await errorReporter.initialize();
      FlutterError.onError = errorReporter.recordFlutterError;
      PlatformDispatcher.instance.onError = errorReporter.recordPlatformError;
      ErrorWidget.builder = (details) {
        unawaited(
          errorReporter.record(
            details.exception,
            details.stack,
            source: 'error_widget',
            context: <String, Object?>{
              'library': details.library,
              'context': details.context?.toDescription(),
            },
          ),
        );
        return const AppErrorFallback();
      };

      try {
        await AdService.instance.initialize();
      } on Object catch (error, stackTrace) {
        await errorReporter.record(
          error,
          stackTrace,
          source: 'startup_ad_service',
        );
      }

      if (_simulateErrorReport) {
        await errorReporter.record(
          StateError('Synthetic startup diagnostic'),
          StackTrace.current,
          source: 'manual_simulation',
          context: const <String, Object?>{
            'trigger': 'SIMULATE_ERROR_REPORT',
            'safe': true,
          },
        );
      }

      runApp(const WordMazeApp());
    },
    (error, stackTrace) {
      unawaited(
        AppErrorReporter.instance.record(
          error,
          stackTrace,
          source: 'zone',
          fatal: true,
        ),
      );
    },
  );
}
