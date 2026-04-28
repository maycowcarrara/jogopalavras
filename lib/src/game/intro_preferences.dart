import 'package:shared_preferences/shared_preferences.dart';

class IntroPreferences {
  const IntroPreferences._();

  static const String _introSeenKey = 'intro_seen_v1';

  static Future<bool> hasSeenIntro() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_introSeenKey) ?? false;
  }

  static Future<void> markIntroSeen() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_introSeenKey, true);
  }
}
