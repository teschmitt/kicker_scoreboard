import 'package:flutter/material.dart';
import 'package:kicker_scoreboard/controller/goal_text_controller.dart';
import 'dart:math' as math;

class AnimatedGoalText extends StatefulWidget {
  final GoalTextController controller;

  const AnimatedGoalText({super.key, required this.controller});

  @override
  State<AnimatedGoalText> createState() => _AnimatedGoalTextState();
}

class _AnimatedGoalTextState extends State<AnimatedGoalText> with SingleTickerProviderStateMixin {
  late int _goals;
  late AnimationController _animationController;
  late Animation _animation;

  @override
  void initState() {
    super.initState();
    _goals = widget.controller.value;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween(begin: -.5, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.bounceOut),
    );
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    if (!mounted) return;
    setState(() {
      _animationController.reset();
      _goals = widget.controller.value;
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    //return Text('$_goals');
    if (!_animationController.isAnimating) {
      return Text('$_goals');
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1,//.5 + _animation.value,
          child: Transform.rotate(
            angle: math.pi * _animation.value,
            alignment: Alignment.center,
            origin: const Offset(-200, -200),
            child: child,
          ),
        );
      },
      child: Text('$_goals'),
    );
  }
}
