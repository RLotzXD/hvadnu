import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hvad_nu/widgets/story_progress_indicator.dart';
import 'package:hvad_nu/config/app_theme.dart';

void main() {
  group('StoryProgressIndicator', () {
    testWidgets('displays correct step count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: StoryProgressIndicator(
              currentStep: 2,
              totalSteps: 5,
            ),
          ),
        ),
      );

      expect(find.text('2 / 5'), findsOneWidget);
    });

    testWidgets('displays correct number of step indicators', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: StoryProgressIndicator(
              currentStep: 3,
              totalSteps: 5,
            ),
          ),
        ),
      );

      // Should find 5 AnimatedContainer widgets for the steps
      final containers = find.byType(AnimatedContainer);
      expect(containers, findsNWidgets(5));
    });

    testWidgets('works with zero progress', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: StoryProgressIndicator(
              currentStep: 0,
              totalSteps: 5,
            ),
          ),
        ),
      );

      expect(find.text('0 / 5'), findsOneWidget);
    });

    testWidgets('works with completed progress', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: StoryProgressIndicator(
              currentStep: 5,
              totalSteps: 5,
            ),
          ),
        ),
      );

      expect(find.text('5 / 5'), findsOneWidget);
    });
  });
}
