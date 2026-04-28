import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/terrain_provider.dart';
import 'splash_screen.dart';


// ─── Notifier global ───────────────────────────────────────────────────────
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
final unreadNotifNotifier = ValueNotifier<int>(3); // notifications non lues

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MinifootApp());
}

class MinifootApp extends StatelessWidget {
  const MinifootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TerrainProvider()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, mode, child) => MaterialApp(
          title: 'MiniFoot',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F0E8),
            cardColor: Colors.white,
            useMaterial3: true,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF006F39),
              surface: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F0F0F),
            cardColor: const Color(0xFF1C1C1C),
            useMaterial3: true,
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00C264),
              surface: Color(0xFF1C1C1C),
              onSurface: Color(0xFFF0EBE0),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1C1C1C),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
            ),
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }

}
