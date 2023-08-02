import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kicker_scoreboard/bloc/goals/goals_cubit.dart';

class GoalsPageContent extends StatelessWidget {
  const GoalsPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoalsCubit, GoalsState>(builder: (context, state) {
      if (state is GoalsIdle) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      } else if (state is GoalsAvailable) {
        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${state.home}'),
              const SizedBox(
                width: 20,
              ),
              const Text(':'),
              const SizedBox(
                width: 20,
              ),
              Text('${state.away}'),
            ],
          ),
        );
      } else {
        throw Exception('Unknown state: $state');
      }
    });
  }
}
