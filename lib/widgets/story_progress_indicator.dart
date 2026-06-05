import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class StoryProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color accentColor;

  const StoryProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.accentColor = AppTheme.accentGold,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (index) {
            final isCompleted = index < currentStep;
            final isCurrent = index == currentStep;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isCurrent ? 32 : 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? accentColor
                      : isCurrent
                          ? accentColor.withOpacity(0.5)
                          : AppTheme.secondaryDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrent ? accentColor : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isCompleted || isCurrent
                      ? [
                          BoxShadow(
                            color: accentColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 10,
                        color: AppTheme.primaryDark,
                      )
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          '$currentStep / $totalSteps',
          style: TextStyle(
            color: accentColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
