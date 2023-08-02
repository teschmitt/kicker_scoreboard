import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../service/ble_goals_service.dart';

part 'goals_state.dart';

class GoalsCubit extends Cubit<GoalsState> {
  final BleGoalsService goalsService;

  GoalsCubit(this.goalsService) : super(GoalsIdle()) {
    goalsService.goalsStream.listen(
      (homeGoals) {
        emit(
          GoalsAvailable(home: homeGoals, away: 0),
        );
      },
    );
  }
}
