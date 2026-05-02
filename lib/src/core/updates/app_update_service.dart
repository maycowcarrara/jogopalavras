import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:jogopalavras/src/core/errors/app_error_reporter.dart';

class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();

  static const bool _updatesEnabled = bool.fromEnvironment(
    'IN_APP_UPDATES_ENABLED',
    defaultValue: kReleaseMode,
  );

  bool _isChecking = false;
  bool _promptedThisSession = false;

  Future<void> checkForImmediateUpdate({bool allowNewPrompt = true}) async {
    if (!_canUsePlayUpdates || _isChecking) {
      return;
    }

    _isChecking = true;
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      final shouldResumeImmediateUpdate =
          updateInfo.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress;
      final shouldStartImmediateUpdate =
          allowNewPrompt &&
          !_promptedThisSession &&
          updateInfo.updateAvailability == UpdateAvailability.updateAvailable &&
          updateInfo.immediateUpdateAllowed;

      if (!shouldResumeImmediateUpdate && !shouldStartImmediateUpdate) {
        return;
      }

      _promptedThisSession = true;
      final result = await InAppUpdate.performImmediateUpdate();
      if (result == AppUpdateResult.inAppUpdateFailed) {
        await AppErrorReporter.instance.record(
          StateError('Play in-app immediate update failed'),
          StackTrace.current,
          source: 'app_update',
          context: <String, Object?>{
            'availableVersionCode': updateInfo.availableVersionCode,
            'updateAvailability': updateInfo.updateAvailability.name,
            'installStatus': updateInfo.installStatus.name,
          },
        );
      }
    } on PlatformException catch (error, stackTrace) {
      if (_isExpectedPlayStoreAvailabilityError(error)) {
        return;
      }

      await AppErrorReporter.instance.record(
        error,
        stackTrace,
        source: 'app_update',
        context: <String, Object?>{'code': error.code},
      );
    } on MissingPluginException {
      // Happens in local/test environments where the Android plugin is absent.
    } on Object catch (error, stackTrace) {
      await AppErrorReporter.instance.record(
        error,
        stackTrace,
        source: 'app_update',
      );
    } finally {
      _isChecking = false;
    }
  }

  bool get _canUsePlayUpdates {
    return _updatesEnabled &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android;
  }

  bool _isExpectedPlayStoreAvailabilityError(PlatformException error) {
    return error.code == 'ERROR_API_NOT_AVAILABLE' ||
        error.code == 'ERROR_INSTALL_NOT_ALLOWED' ||
        error.code == 'ERROR_INSTALL_UNAVAILABLE';
  }
}
