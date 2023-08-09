import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kicker_scoreboard/bloc/goals/goals_cubit.dart';

import '../controller/goal_text_controller.dart';
import 'animated_goal_text.dart';

class GoalsPageContent extends StatelessWidget {
  final _homeController = GoalTextController();
  final _awayController = GoalTextController();

  GoalsPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GoalsCubit, GoalsState>(
        buildWhen: (previous, current) => previous.runtimeType != current.runtimeType,
        listenWhen: (_, current) => current is GoalsAvailable,
        listener: (context, state) {
          if (state is GoalsAvailable) {
            _homeController.value = state.home;
            _awayController.value = state.away;
          }
        },
        builder: (context, state) {
          if (state is GoalsIdle) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is GoalsAvailable) {
            return Center(
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.displayLarge!,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedGoalText(controller: _homeController),
                    const SizedBox(width: 20),
                    const Text(':'),
                    const SizedBox(width: 20),
                    AnimatedGoalText(controller: _awayController),
                  ],
                ),
              ),
            );
          } else {
            throw Exception('Unknown state: $state');
          }
        });
  }
}
