import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class GoalsResult {
  final bool connected;
  final int value;

  GoalsResult(this.connected, this.value);
}

class BleGoalsService {
  final Guid _goalServiceId;

  final flutterBlue = FlutterBluePlus.instance;

  BluetoothDevice? _goalDevice;
  StreamSubscription? _subscription;

  BleGoalsService({Guid? goalServiceId})
      : _goalServiceId = goalServiceId ?? Guid('c03f245f-d01c-4886-850b-408bc53fe63a') {
    startScan();
  }

  Future<void> startScan() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final isOnAndAvailable = await flutterBlue.isOn && await flutterBlue.isAvailable;
    if (!isOnAndAvailable) {
      print('cannot start scan, is not on or available!');
      return;
    }

    await flutterBlue.startScan(
      timeout: const Duration(seconds: 4),
      //withServices: [_goalServiceId],
    );
    _subscription = flutterBlue.scanResults.listen((results) async {
      for (final r in results) {
        final device = r.device;
        print('${r.device.name} found! rssi: ${r.rssi}');
        await device.connect();
        final services = await device.discoverServices();
        final goalService = services
            .cast<BluetoothService?>()
            .firstWhere((service) => service?.uuid == _goalServiceId, orElse: () => null);
        if (goalService != null) {
          print('found goal service!');
          final success = await goalService.characteristics.first.setNotifyValue(true);
          goalService.characteristics.first.onValueChangedStream.listen((event) {
            print('value changed to $event');
          });
          print('setNotifyValue, success = $success');
          await stopScan();
        } else {
          await device.disconnect();
        }
      }
      //final service = results.firstWhere((r) => r.device.se)
    });
  }

  Future<void> stopScan() async {
    await flutterBlue.stopScan();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await stopScan();
  }
}
