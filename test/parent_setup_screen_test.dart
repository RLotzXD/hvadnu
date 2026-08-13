import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hvad_nu/screens/parent_setup_screen.dart';
import 'package:hvad_nu/config/app_theme.dart';

void main() {
  group('ParentSetupScreen', () {
    testWidgets('displays app title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ParentSetupScreen(),
          ),
        ),
      );

      expect(find.text('Hvad Nu?!'), findsOneWidget);
    });

    testWidgets('displays all theme options', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ParentSetupScreen(),
          ),
        ),
      );

      expect(find.text('Dragejagt'), findsOneWidget);
      expect(find.text('Rumrejsen'), findsOneWidget);
      expect(find.text('Pirateventyret'), findsOneWidget);
    });

    testWidgets('displays all environment options', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ParentSetupScreen(),
          ),
        ),
      );

      expect(find.text('Hjemme'), findsOneWidget);
      expect(find.text('Legeplads'), findsOneWidget);
      expect(find.text('Strand'), findsOneWidget);
      expect(find.text('Skov'), findsOneWidget);
      expect(find.text('Sejlbåd'), findsOneWidget);
    });

    testWidgets('displays narrator options', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ParentSetupScreen(),
          ),
        ),
      );

      expect(find.text('Den Vise Troldmand'), findsOneWidget);
      expect(find.text('Den Gamle Søkaptajn'), findsOneWidget);
      expect(find.text('Den Venlige Robot'), findsOneWidget);
    });

    testWidgets('displays step count options', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ParentSetupScreen(),
          ),
        ),
      );

      // '5' is deliberately not asserted as unique: it is both a step count
      // and a duration in minutes, so two widgets legitimately show it.
      expect(find.text('3'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('5'), findsNWidgets(2));
      expect(find.text('skridt'), findsNWidgets(3));
    });

    testWidgets('displays start button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ParentSetupScreen(),
          ),
        ),
      );

      expect(find.text('Start Eventyr'), findsOneWidget);
    });
  });
}
