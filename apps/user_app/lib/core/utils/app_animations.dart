import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

class AppAnimations {
  static Widget fadeThrough(Widget child) {
    return PageTransitionSwitcher(
      transitionBuilder: (child, animation, secondaryAnimation) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
      child: child,
    );
  }

  static Widget fadeIn(Widget child, {Duration duration = const Duration(milliseconds: 500)}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }

  static Widget slideIn(Widget child, {Offset begin = const Offset(0, 0.1), Duration duration = const Duration(milliseconds: 400)}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(begin.dx * (1 - value), begin.dy * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  static Widget staggeredList(int index, Widget child) {
    return slideIn(
      child,
      begin: const Offset(0.2, 0),
      duration: Duration(milliseconds: 300 + (index * 100).clamp(0, 400)),
    );
  }
}
