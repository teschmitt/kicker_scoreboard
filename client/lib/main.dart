import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:kicker_scoreboard/bloc/main_page/main_page_cubit.dart';
import 'package:kicker_scoreboard/page/main_page.dart';
import 'package:kicker_scoreboard/service/ble_goals_service.dart';
import 'package:kicker_scoreboard/theme.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  if (Platform.isAndroid) {
    WidgetsFlutterBinding.ensureInitialized();
    [
      Permission.location,
      Permission.storage,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan
    ].request().then((status) {
      runApp(const KickerScoreboardApp());
    });
  } else {
    runApp(const KickerScoreboardApp());
  }
}

class BluetoothAdapterStateObserver extends NavigatorObserver {
  StreamSubscription<BluetoothAdapterState>? _btStateSubscription;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name == '/deviceScreen') {
      // Start listening to Bluetooth state changes when a new route is pushed
      _btStateSubscription ??= FlutterBluePlus.adapterState.listen((state) {
        if (state != BluetoothAdapterState.on) {
          // Pop the current route if Bluetooth is off
          navigator?.pop();
        }
      });
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    // Cancel the subscription when the route is popped
    _btStateSubscription?.cancel();
    _btStateSubscription = null;
  }
}

class KickerScoreboardApp extends StatelessWidget {
  const KickerScoreboardApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scoreboard',
      theme: ScoreboardTheme.light,
      darkTheme: ScoreboardTheme.dark,
      home: BlocProvider<MainPageCubit>(
        create: (context) => MainPageCubit(),
        child: const MainPage(),
      ),
    );
  }
}
