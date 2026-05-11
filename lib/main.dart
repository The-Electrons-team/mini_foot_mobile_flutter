import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'startup_config.dart';
import 'providers/auth_provider.dart';
import 'providers/terrain_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/team_provider.dart';
import 'providers/reservation_provider.dart';
import 'providers/chat_provider.dart';
import 'services/socket_service.dart';
import 'splash_screen.dart';
import 'app_navigator.dart';

// ─── Notifier global ───────────────────────────────────────────────────────
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const envFileName = String.fromEnvironment('ENV_FILE', defaultValue: '.env');
  try {
    await dotenv.load(fileName: envFileName);
  } catch (e) {
    debugPrint('Impossible de charger $envFileName : $e');
  }

  try {
    if (kIsWeb) {
      final firebaseOptions = buildWebFirebaseOptions(
        apiKey: dotenv.maybeGet('FIREBASE_API_KEY'),
        authDomain: dotenv.maybeGet('FIREBASE_AUTH_DOMAIN'),
        projectId: dotenv.maybeGet('FIREBASE_PROJECT_ID'),
        storageBucket: dotenv.maybeGet('FIREBASE_STORAGE_BUCKET'),
        messagingSenderId: dotenv.maybeGet('FIREBASE_MESSAGING_SENDER_ID'),
        appId: dotenv.maybeGet('FIREBASE_APP_ID'),
        measurementId: dotenv.maybeGet('FIREBASE_MEASUREMENT_ID'),
      );

      if (firebaseOptions == null) {
        debugPrint('Firebase web non initialisé: variables d\'environnement manquantes.');
      } else {
        await Firebase.initializeApp(options: firebaseOptions);
      }
    } else {
      await Firebase.initializeApp();
    }
    debugPrint("Firebase initialisé avec succès !");
  } catch (e) {
    debugPrint("Erreur initialisation Firebase : $e");
  }

  await initializeDateFormatting('fr_FR', null);
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
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => SocketService()),
        ChangeNotifierProxyProvider2<AuthProvider, SocketService, ChatProvider>(
          create: (context) => ChatProvider(
            Provider.of<AuthProvider>(context, listen: false),
            Provider.of<SocketService>(context, listen: false),
          ),
          update: (context, auth, socket, chat) => chat ?? ChatProvider(auth, socket),
        ),
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
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', 'FR'),
            Locale('en', 'US'),
          ],
          locale: const Locale('fr', 'FR'),
          navigatorKey: navigatorKey,
          home: const SplashScreen(),
        ),
      ),
    );
  }

}
