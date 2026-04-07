import 'package:flutter/material.dart';
import 'package:jogopalavras/src/screens/intro_screen.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';

class WordMazeApp extends StatelessWidget {
  const WordMazeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anagrama Oculto',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const IntroScreen(),
    );
  }
}
