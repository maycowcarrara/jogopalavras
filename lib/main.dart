import 'package:flutter/widgets.dart';
import 'package:jogopalavras/src/app.dart';
import 'package:jogopalavras/src/core/ads/ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.instance.initialize();
  runApp(const WordMazeApp());
}
