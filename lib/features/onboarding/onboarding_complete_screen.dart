import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/app_scope.dart';
import '../../theme/theme.dart';
import '../../widgets/animated_gradient_background.dart';
import '../alphabet/alphabet_preview_screen.dart';
import '../home/home_screen.dart';
import '../../widgets/app_text.dart';

class OnboardingCompleteScreen extends StatelessWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Icon(AppIcons.check, size: 56, color: AppColors.fuchsia)
                    .animate()
                    .fadeIn(duration: AppMotion.base, curve: AppMotion.enter)
                    .scaleXY(begin: 0.7, end: 1, duration: AppMotion.base, curve: AppMotion.emphasized),
                const SizedBox(height: AppSpacing.xl),
                AppText('il tuo', textAlign: TextAlign.center, style: AppTypography.display())
                    .animate(delay: AppMotion.staggerStep)
                    .fadeIn(duration: AppMotion.base, curve: AppMotion.enter),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AppText('alfabeto', textAlign: TextAlign.center, style: AppTypography.accent(fontSize: 48)),
                )
                    .animate(delay: AppMotion.staggerStep * 2)
                    .fadeIn(duration: AppMotion.base, curve: AppMotion.enter),
                AppText('è pronto.', textAlign: TextAlign.center, style: AppTypography.display())
                    .animate(delay: AppMotion.staggerStep * 3)
                    .fadeIn(duration: AppMotion.base, curve: AppMotion.enter),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final state = AppScope.readOf(context);
                      await state.completeOnboarding();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AlphabetPreviewScreen(focusTryField: true)),
                      );
                    },
                    child: const AppText('PROVALO'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
