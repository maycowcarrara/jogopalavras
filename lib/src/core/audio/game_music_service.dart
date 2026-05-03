import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:jogopalavras/src/game/game_level.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameMusicService {
  GameMusicService._();

  static final GameMusicService instance = GameMusicService._();

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _wordVictoryPlayer = AudioPlayer();
  final AudioPlayer _endOfGamePlayer = AudioPlayer();
  StreamSubscription<void>? _playerCompleteSubscription;

  bool _initialized = false;
  bool _enabled = true;
  bool _effectsEnabled = true;
  bool _musicPlaying = false;
  bool _pausedByGame = false;
  double _volume = 1;
  String? _currentAsset;
  GameLevel? _currentLevel;
  int _playlistIndex = -1;

  static const String _musicEnabledKey = 'music_enabled_v1';
  static const String _effectsEnabledKey = 'effects_enabled_v1';
  static const String _musicVolumeKey = 'music_volume_v1';
  static const List<String> _playlistAssets = [
    'audio/alisiabeats-titanium-170190.mp3',
    'audio/andriig-relaxing-relax-music-473810.mp3',
    'audio/atlasaudio-piano-relaxing-510242.mp3',
    'audio/bodleasons-lofi-chill-smooth-chill-lofi-for-vlogs-and-background-music-159456.mp3',
    'audio/comastudio-order-99518.mp3',
    'audio/kontraa-water-afro-pop-music-445661.mp3',
    'audio/leberch-relaxation-morning-354986.mp3',
    'audio/monume-chill-chill-music-519245.mp3',
    'audio/music_for_video-please-calm-my-mind-125566.mp3',
    'audio/music_for_videos-relaxing-145038.mp3',
    'audio/oceanframemusic-relax-music-515140.mp3',
    'audio/penguinmusic-better-day-186374.mp3',
    'audio/penguinmusic-penguinmusic-modern-chillout-future-calm-12641.mp3',
    'audio/romanbelov-spirit-blossom-15285.mp3',
    'audio/the_mountain-relaxing-142297.mp3',
  ];
  static const String _wordVictoryKeyAsset = 'audio/typewriter_key.wav';
  static const String _endOfGameAsset = 'audio/endofgame.mp3';
  static const String _stageCompletionBellAsset = 'audio/typewriter_bell.wav';
  static const double _effectsOutputVolume = 1;
  static const double _maxMusicVolume = _effectsOutputVolume * 0.5;

  bool get enabled => _enabled;
  bool get effectsEnabled => _effectsEnabled;
  double get volume => _volume;

  Future<void> playAppMusic() async {
    await initialize();

    if (!_enabled || _pausedByGame || kIsWeb || _musicPlaying) {
      return;
    }

    try {
      await _applyMusicVolume();
      await _playAsset(_currentAsset ?? _nextPlaylistAsset());
    } catch (_) {
      // Ignore audio platform issues during tests or unsupported runtimes.
    }
  }

  Future<void> initialize() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _enabled = preferences.getBool(_musicEnabledKey) ?? true;
      _effectsEnabled = preferences.getBool(_effectsEnabledKey) ?? true;
      _volume = (preferences.getDouble(_musicVolumeKey) ?? 1)
          .clamp(0.0, 1.0)
          .toDouble();
    } catch (_) {
      // Ignore preferences issues during tests or unsupported runtimes.
    }

    if (_initialized || kIsWeb) {
      _initialized = true;
      return;
    }

    try {
      final mixContext = AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
      ).build();
      await _player.setReleaseMode(ReleaseMode.release);
      await _player.setAudioContext(mixContext);
      await _wordVictoryPlayer.setReleaseMode(ReleaseMode.stop);
      await _wordVictoryPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _wordVictoryPlayer.setAudioContext(mixContext);
      await _wordVictoryPlayer.setVolume(_effectsOutputVolume);
      await _endOfGamePlayer.setReleaseMode(ReleaseMode.stop);
      await _endOfGamePlayer.setAudioContext(mixContext);
      await _endOfGamePlayer.setVolume(_effectsOutputVolume);
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
    _pausedByGame = false;

    if (!_enabled || kIsWeb) {
      return;
    }

    try {
      await _applyMusicVolume();
      await _playAsset(asset);
    } catch (_) {
      // Ignore audio platform issues during tests or unsupported runtimes.
    }
  }

  Future<void> setEnabled(bool value, {GameLevel? fallbackLevel}) async {
    await initialize();
    _enabled = value;

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_musicEnabledKey, value);
    } catch (_) {
      // Ignore preferences issues during tests or unsupported runtimes.
    }

    if (kIsWeb) {
      return;
    }

    if (!_enabled) {
      try {
        await _player.stop();
        _musicPlaying = false;
        _pausedByGame = false;
      } catch (_) {
        // Ignore audio platform issues during tests or unsupported runtimes.
      }
      return;
    }

    if (_pausedByGame) {
      return;
    }

    if (fallbackLevel != null) {
      await playForLevel(fallbackLevel);
      return;
    }

    if (_currentAsset != null) {
      try {
        if (_currentLevel != null) {
          await _applyMusicVolume();
        }
        await _playAsset(_currentAsset!);
      } catch (_) {
        // Ignore audio platform issues during tests or unsupported runtimes.
      }
      return;
    }

    await playAppMusic();
  }

  Future<void> setVolume(double value) async {
    await initialize();
    _volume = value.clamp(0.0, 1.0).toDouble();

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setDouble(_musicVolumeKey, _volume);
    } catch (_) {
      // Ignore preferences issues during tests or unsupported runtimes.
    }

    if (kIsWeb) {
      return;
    }

    await _applyMusicVolume();
  }

  Future<void> setEffectsEnabled(bool value) async {
    _effectsEnabled = value;

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_effectsEnabledKey, value);
    } catch (_) {
      // Ignore preferences issues during tests or unsupported runtimes.
    }

    if (value || kIsWeb) {
      return;
    }

    await initialize();

    try {
      await _wordVictoryPlayer.stop();
      await _endOfGamePlayer.stop();
    } catch (_) {
      // Ignore audio platform issues during tests or unsupported runtimes.
    }
  }

  Future<void> pause({bool holdForGame = false}) async {
    _pausedByGame = _pausedByGame || holdForGame;

    if (kIsWeb || !_enabled) {
      return;
    }

    try {
      await _player.pause();
      _musicPlaying = false;
    } catch (_) {
      // Ignore audio platform issues during tests or unsupported runtimes.
    }
  }

  Future<void> resume(GameLevel level) async {
    _pausedByGame = false;

    if (!_enabled) {
      return;
    }

    if (_currentLevel == level && _currentAsset != null) {
      if (kIsWeb) {
        return;
      }

      try {
        await _player.resume();
        _musicPlaying = true;
      } catch (_) {
        await playForLevel(level);
      }
      return;
    }

    await playForLevel(level);
  }

  Future<void> stop() async {
    _pausedByGame = false;

    if (kIsWeb) {
      return;
    }

    try {
      await _player.stop();
      await _wordVictoryPlayer.stop();
      await _endOfGamePlayer.stop();
      _musicPlaying = false;
    } catch (_) {
      // Ignore audio platform issues during tests or unsupported runtimes.
    }
  }

  Future<void> playWordVictory() async {
    await _playEffect(_wordVictoryPlayer, _wordVictoryKeyAsset);
  }

  void clearGamePause() {
    _pausedByGame = false;
  }

  Future<void> playEndOfGame() async {
    await _playEffect(_endOfGamePlayer, _endOfGameAsset);
  }

  Future<void> playStageCompletionCelebration() async {
    await _playEffect(
      _endOfGamePlayer,
      _endOfGameAsset,
      waitForCompletion: true,
    );
    await _playEffect(_endOfGamePlayer, _stageCompletionBellAsset);
  }

  Future<void> playStageCompletionBell() async {
    await _playEffect(_endOfGamePlayer, _stageCompletionBellAsset);
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
    if (!_enabled || kIsWeb) {
      return;
    }

    try {
      await _applyMusicVolume();
      await _playAsset(_nextPlaylistAsset());
    } catch (_) {
      // Ignore audio platform issues during tests or unsupported runtimes.
    }
  }

  Future<void> _playAsset(String asset) async {
    _currentAsset = asset;
    _playlistIndex = _playlistAssets.indexOf(asset);
    await _player.play(AssetSource(asset));
    _musicPlaying = true;
  }

  Future<void> _applyMusicVolume() async {
    await _player.setVolume((_maxMusicVolume * _volume).clamp(0.0, 1.0));
  }

  Future<void> _playEffect(
    AudioPlayer player,
    String asset, {
    bool waitForCompletion = false,
  }) async {
    if (!_effectsEnabled || kIsWeb) {
      return;
    }

    await initialize();

    if (!_effectsEnabled || kIsWeb) {
      return;
    }

    StreamSubscription<void>? completionSubscription;
    Completer<void>? completion;

    try {
      if (waitForCompletion) {
        completion = Completer<void>();
        completionSubscription = player.onPlayerComplete.listen((_) {
          if (completion == null || completion.isCompleted) {
            return;
          }
          completion.complete();
        });
      }

      await player.stop();
      await player.play(AssetSource(asset));
      await completion?.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () {},
      );
    } catch (_) {
      // Ignore audio platform issues during tests or unsupported runtimes.
    } finally {
      await completionSubscription?.cancel();
    }
  }

  String _nextPlaylistAsset() {
    _playlistIndex = (_playlistIndex + 1) % _playlistAssets.length;
    return _playlistAssets[_playlistIndex];
  }
}
