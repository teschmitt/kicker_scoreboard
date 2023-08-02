part of 'main_page_cubit.dart';

@immutable
abstract class MainPageState {}

class MainPageIdle extends MainPageState {}

class MainPageConnected extends MainPageState {}

class MainPageNotConnected extends MainPageState {
  final BluetoothAdapterState adapterState;

  MainPageNotConnected(this.adapterState);
}



