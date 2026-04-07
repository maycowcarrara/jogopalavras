import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:jogopalavras/src/game/game_level.dart';

class GameMusicService {
  GameMusicService._();

  static final GameMusicService instance = GameMusicService._();

  final AudioPlayer _player = AudioPlayer();

  bool _initialized = false;
  bool _enabled = true;
  String? _currentAsset;
  GameLevel? _currentLevel;

  bool get enabled => _enabled;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      _initialized = true;
      return;
    }

    try {
      await _player.setReleaseMode(ReleaseMode.loop);
    } catch (_) {
      // Ignore audio platform issues during tests or unsupported runtimes.
    }
    _initialized = true;
  }

  Future<void> playForLevel(GameLevel level) async {
    await initialize();

    final asset = level.soundtrackAsset;
    _currentAsset = asset;
    _currentLevel = level;

    if (!_enabled || kIsWeb) {
      return;
    }

    try {
      await _player.setVolume(level.soundtrackVolume);
      await _player.play(AssetSource(asset));
    } catch (_) {
      // Ignore audio platform issues during tests or unsupported runtimes.
    }
  }

  Future<void> setEnabled(
    bool value, {
    GameLevel? fallbackLevel,
  }) async {
    _enabled = value;

    if (kIsWeb) {
      return;
    }

    if (!_enabled) {
      try {
        await _player.stop();
      } catch (_) {
        // Ignore audio platform issues during tests or unsupported runtimes.
      }
      return;
    }

    if (fallbackLevel != null) {
      await playForLevel(fallbackLevel);
      return;
    }

    if (_currentAsset != null) {
      try {
        if (_currentLevel != null) {
          await _player.setVolume(_currentLevel!.soundtrackVolume);
        }
        await _player.play(AssetSource(_currentAsset!));
      } catch (_) {
        // Ignore audio platform issues during tests or unsupported runtimes.
      }
    }
  }

  Future<void> pause() async {
    if (kIsWeb || !_enabled) {
      return;
    }

    try {
      await _player.pause();
    } catch (_) {
      // Ignore audio platform issues during tests or unsupported runtimes.
    }
  }

  Future<void> resume(GameLevel level) async {
    if (!_enabled) {
      return;
    }

    if (_currentAsset == level.soundtrackAsset) {
      if (kIsWeb) {
        return;
      }

      try {
        await _player.resume();
      } catch (_) {
        await playForLevel(level);
      }
      return;
    }

    await playForLevel(level);
  }

  Future<void> stop() async {
    if (kIsWeb) {
      return;
    }

    try {
      await _player.stop();
    } catch (_) {
      // Ignore audio platform issues during tests or unsupported runtimes.
    }
  }

  Future<void> dispose() async {
    if (kIsWeb) {
      return;
    }

    try {
      await _player.dispose();
    } catch (_) {
      // Ignore audio platform issues during tests or unsupported runtimes.
    }
  }
}
