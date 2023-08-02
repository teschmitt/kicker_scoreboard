part of 'goals_cubit.dart';

@immutable
abstract class GoalsState {}

class GoalsIdle extends GoalsState {}

class GoalsAvailable extends GoalsState {
  final int home;
  final int away;

  GoalsAvailable({required this.home, required this.away});
}