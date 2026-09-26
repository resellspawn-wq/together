import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// The signature backdrop for "key screens" (splash/onboarding, home):
/// the same blush→mist gradient as everywhere else, but drifting almost
/// imperceptibly (one full cycle every [AppMotion.backgroundDrift],
/// ~15-20s) between two slightly different alignments. Falls back to a
/// static gradient when the platform/user requests reduced motion.
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;

  const AnimatedGradientBackground({super.key, required this.child});

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.backgroundDrift);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!reduceMotion) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.lerp(const Alignment(-0.3, -1), const Alignment(0.3, -1), t)!,
              end: Alignment.lerp(const Alignment(0.3, 1), const Alignment(-0.3, 1), t)!,
              colors: [AppColors.blush, AppColors.mist],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
