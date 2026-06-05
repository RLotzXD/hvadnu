import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/app_theme.dart';
import 'screens/screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.primaryDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: HvadNuApp(),
    ),
  );
}

class HvadNuApp extends StatelessWidget {
  const HvadNuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hvad Nu?!',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppNavigator(),
    );
  }
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  AppScreen _currentScreen = AppScreen.splash;

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case AppScreen.splash:
        return SplashScreen(
          onComplete: () {
            setState(() => _currentScreen = AppScreen.loading);
          },
        );

      case AppScreen.loading:
        return LoadingScreen(
          onReady: () {
            setState(() => _currentScreen = AppScreen.setup);
          },
          onError: () {
            // Stay on loading screen with error display
          },
        );

      case AppScreen.setup:
        return const ParentSetupScreen();
    }
  }
}

enum AppScreen {
  splash,
  loading,
  setup,
}
