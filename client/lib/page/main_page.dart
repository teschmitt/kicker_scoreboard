import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kicker_scoreboard/bloc/goals/goals_cubit.dart';
import 'package:kicker_scoreboard/service/ble_goals_service.dart';
import 'package:kicker_scoreboard/widget/goals_page_content.dart';

import '../bloc/main_page/main_page_cubit.dart';
import '../widget/idle_page_content.dart';
import '../widget/not_connected_page_content.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<MainPageCubit, MainPageState>(builder: (context, state) {
        if (state is MainPageIdle) {
          return const IdlePageContent();
        } else if (state is MainPageNotConnected) {
          return NotConnectedPageContent(adapterState: state.adapterState);
        } else if (state is MainPageConnected) {
          return BlocProvider<GoalsCubit>(
            create: (_) => GoalsCubit(BleGoalsService()),
            child: GoalsPageContent(),
          );
        } else {
          return const IdlePageContent();
        }
      }),
    );
  }
}
