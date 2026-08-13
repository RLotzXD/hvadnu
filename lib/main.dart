import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_theme.dart';
import 'screens/screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only load .env file on mobile (not on web)
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('Warning: Could not load .env file: $e');
    }
  }

  // Only apply platform-specific settings on mobile
  if (!kIsWeb) {
    try {
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
    } catch (e) {
      debugPrint('Could not set platform preferences: $e');
    }
  }

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
          onComplete: () => _goTo(AppScreen.loading),
        );

      case AppScreen.loading:
        return LoadingScreen(
          onReady: () => _goTo(_afterLoading),
          onError: () {
            // Stay on the loading screen, which renders its own error state.
          },
        );

      case AppScreen.permissions:
        return PermissionsScreen(
          onAllGranted: () => _goTo(AppScreen.setup),
          onSkipped: () => _goTo(AppScreen.setup),
        );

      case AppScreen.setup:
        return const ParentSetupScreen();
    }
  }

  /// Browsers prompt for camera and microphone on first use and
  /// `permission_handler` is a no-op there, so the screen would be a dead end.
  AppScreen get _afterLoading =>
      kIsWeb ? AppScreen.setup : AppScreen.permissions;

  void _goTo(AppScreen screen) {
    if (!mounted) return;
    setState(() => _currentScreen = screen);
  }
}

enum AppScreen {
  splash,
  loading,
  permissions,
  setup,
}
