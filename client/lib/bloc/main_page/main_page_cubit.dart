import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:meta/meta.dart';

part 'main_page_state.dart';

class MainPageCubit extends Cubit<MainPageState> {
  late StreamSubscription<BluetoothAdapterState> _connectivitySubscription;

  MainPageCubit() : super(MainPageIdle()) {
    _connectivitySubscription = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        emit(MainPageConnected());
      } else if (state == BluetoothAdapterState.turningOn || state == BluetoothAdapterState.turningOff) {
        emit(MainPageIdle());
      } else {
        emit(MainPageNotConnected(state));
      }
    });
  }

  @override
  Future<void> close() async {
    await _connectivitySubscription.cancel();
    super.close();
  }
}
