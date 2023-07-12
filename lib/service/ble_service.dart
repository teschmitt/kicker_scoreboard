import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  final flutterBlue = FlutterBluePlus.instance;

  BluetoothDevice? _goalDevice;
  StreamSubscription? _subscription;

  BleService() {
    startScan();
  }

  Future<void> startScan() async {
    await flutterBlue.startScan(timeout: const Duration(seconds: 4));
  }

  Future<void> stopScan() async {
    await flutterBlue.stopScan();
  }

  Stream<List<BluetoothDevice>> get devices =>
      flutterBlue.scanResults.map((event) => event.map((e) => e.device).toList());

  Future<void> dispose() async {
    await _subscription?.cancel();
    await stopScan();
  }
}
