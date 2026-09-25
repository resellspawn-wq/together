import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/theme.dart';
import '../../widgets/animated_gradient_background.dart';
import '../../widgets/marquee_text.dart';
import '../editor/editor_screen.dart';
import 'onboarding_complete_screen.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Icon(AppIcons.pencilSimple, size: 56, color: AppColors.fuchsia)
                    .animate()
                    .fadeIn(duration: AppMotion.base, curve: AppMotion.enter)
                    .scaleXY(begin: 0.8, end: 1, duration: AppMotion.base, curve: AppMotion.emphasized),
                const SizedBox(height: AppSpacing.xl),
                Text('CREA IL TUO', textAlign: TextAlign.center, style: AppTypography.hero())
                    .animate(delay: AppMotion.staggerStep)
                    .fadeIn(duration: AppMotion.base, curve: AppMotion.enter)
                    .slideY(begin: 0.2, end: 0, duration: AppMotion.base, curve: AppMotion.emphasized),
                Text('alfabeto', textAlign: TextAlign.center, style: AppTypography.accent(fontSize: 52))
                    .animate(delay: AppMotion.staggerStep * 2)
                    .fadeIn(duration: AppMotion.base, curve: AppMotion.enter)
                    .slideY(begin: 0.2, end: 0, duration: AppMotion.base, curve: AppMotion.emphasized),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Trasforma il tuo modo di scrivere in qualcosa che è solo tuo.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(color: AppColors.inkSoft),
                )
                    .animate(delay: AppMotion.staggerStep * 3)
                    .fadeIn(duration: AppMotion.base, curve: AppMotion.enter)
                    .slideY(begin: 0.2, end: 0, duration: AppMotion.base, curve: AppMotion.emphasized),
                const SizedBox(height: AppSpacing.xl),
                MarqueeText('scritto a mano  ·  solo per te  ·  together  ·')
                    .animate(delay: AppMotion.staggerStep * 4)
                    .fadeIn(duration: AppMotion.base, curve: AppMotion.enter),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditorScreen(
                          sequential: true,
                          onSequenceComplete: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const OnboardingCompleteScreen()),
                            );
                          },
                        ),
                      ),
                    ),
                    child: const Text('INIZIA'),
                  ),
                ).animate(delay: AppMotion.staggerStep * 5).fadeIn(duration: AppMotion.base, curve: AppMotion.enter),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
