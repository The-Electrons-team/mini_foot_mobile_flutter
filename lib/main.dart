import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(const MinifootApp());
}

class MinifootApp extends StatelessWidget {
  const MinifootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiniFoot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
