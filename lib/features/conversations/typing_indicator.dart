import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/theme.dart';

/// The "someone is composing a message" bubble: three dots jumping in a
/// staggered loop, styled like a received message bubble so it reads as
/// "a reply is on its way" sitting where the next message would land.
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.bubble),
          border: Border.all(color: AppColors.chromeMid, width: 1),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => _Dot(delay: i * 150)),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final int delay;
  const _Dot({required this.delay});

  static DecoratedBox get _dot => DecoratedBox(
        decoration: BoxDecoration(color: AppColors.fuchsia, shape: BoxShape.circle),
        child: const SizedBox(width: 8, height: 8),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: _dot.animate(onPlay: (controller) => controller.repeat()).custom(
            delay: delay.ms,
            duration: 600.ms,
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              // Up on the first half, back down on the second — a bounce
              // rather than a one-way slide, matching the reference dots.
              final t = value <= 0.5 ? value * 2 : (1 - value) * 2;
              return Transform.translate(offset: Offset(0, -6 * t), child: child);
            },
          ),
    );
  }
}
