import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:jogopalavras/src/game/game_level.dart';

class GameMusicService {
  GameMusicService._();

  static final GameMusicService instance = GameMusicService._();

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _wordVictoryPlayer = AudioPlayer();
  final AudioPlayer _endOfGamePlayer = AudioPlayer();
  StreamSubscription<void>? _playerCompleteSubscription;

  bool _initialized = false;
  bool _enabled = true;
  String? _currentAsset;
  GameLevel? _currentLevel;
  int _playlistIndex = -1;

  static const List<String> _playlistAssets = [
    'audio/alisiabeats-titanium-170190.mp3',
    'audio/bodleasons-lofi-chill-smooth-chill-lofi-for-vlogs-and-background-music-159456.mp3',
    'audio/comastudio-order-99518.mp3',
    'audio/kontraa-water-afro-pop-music-445661.mp3',
    'audio/music_for_videos-relaxing-145038.mp3',
    'audio/penguinmusic-better-day-186374.mp3',
    'audio/penguinmusic-penguinmusic-modern-chillout-future-calm-12641.mp3',
    'audio/romanbelov-spirit-blossom-15285.mp3',
  ];
  static const String _wordVictoryAsset = 'audio/word_victory.mp3';
  static const String _endOfGameAsset = 'audio/endofgame.mp3';

  bool get enabled => _enabled;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      _initialized = true;
      return;
    }

    try {
      await _player.setReleaseMode(ReleaseMode.release);
      await _wordVictoryPlayer.setReleaseMode(ReleaseMode.stop);
      await _wordVictoryPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _wordVictoryPlayer.setVolume(0.75);
      await _endOfGamePlayer.setReleaseMode(ReleaseMode.stop);
      await _endOfGamePlayer.setVolume(0.9);
      _playerCompleteSubscription = _player.onPlayerComplete.listen((_) {
        unawaited(_playNextTrack());
      });
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
      await _playAsset(asset);
    } catch (_) {
      // Ignore audio platform issues during tests or unsupported runtimes.
    }
  }

  Future<void> setEnabled(bool value, {GameLevel? fallbackLevel}) async {
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
        await _playAsset(_currentAsset!);
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

    if (_currentLevel == level && _currentAsset != null) {
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
      await _wordVictoryPlayer.stop();
      await _endOfGamePlayer.stop();
    } catch (_) {
      // Ignore audio platform issues during tests or unsupported runtimes.
    }
  }

  Future<void> playWordVictory() async {
    await _playEffect(_wordVictoryPlayer, _wordVictoryAsset);
  }

  Future<void> playEndOfGame() async {
    await _playEffect(_endOfGamePlayer, _endOfGameAsset);
  }

  Future<void> dispose() async {
    if (kIsWeb) {
      return;
    }

    try {
      await _playerCompleteSubscription?.cancel();
      await _wordVictoryPlayer.dispose();
      await _endOfGamePlayer.dispose();
      await _player.dispose();
    } catch (_) {
      // Ignore audio platform issues during tests or unsupported runtimes.
    }
  }

  Future<void> _playNextTrack() async {
    if (!_enabled || kIsWeb || _currentLevel == null) {
      return;
    }

    try {
      await _player.setVolume(_currentLevel!.soundtrackVolume);
      await _playAsset(_nextPlaylistAsset());
    } catch (_) {
      // Ignore audio platform issues during tests or unsupported runtimes.
    }
  }

  Future<void> _playAsset(String asset) async {
    _currentAsset = asset;
    _playlistIndex = _playlistAssets.indexOf(asset);
    await _player.play(AssetSource(asset));
  }

  Future<void> _playEffect(AudioPlayer player, String asset) async {
    await initialize();

    if (!_enabled || kIsWeb) {
      return;
    }

    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (_) {
      // Ignore audio platform issues during tests or unsupported runtimes.
    }
  }

  String _nextPlaylistAsset() {
    _playlistIndex = (_playlistIndex + 1) % _playlistAssets.length;
    return _playlistAssets[_playlistIndex];
  }
}
