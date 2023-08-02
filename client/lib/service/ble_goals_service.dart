import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rxdart/rxdart.dart';

class GoalsResult {
  final bool connected;
  final int value;

  GoalsResult(this.connected, this.value);
}

class BleGoalsService {
  final Guid _goalServiceId;

  BluetoothDevice? _goalDevice;
  StreamSubscription? _subscription;

  BehaviorSubject<int> _goalsSubject = BehaviorSubject();

  Stream<int> get goalsStream => _goalsSubject.stream;

  static const _serviceIdString = 'c03f245f-d01c-4886-850b-408bc53fe63a';

  BleGoalsService({Guid? goalServiceId}) : _goalServiceId = goalServiceId ?? Guid(_serviceIdString) {
    startScan();
  }

  Future<void> startScan() async {
    final isAvailable = await FlutterBluePlus.isAvailable;
    if (!isAvailable) {
      print('cannot start scan, is not on or available!');
      return;
    }
    if (FlutterBluePlus.isScanningNow) {
      return;
    }

    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      withServices: [_goalServiceId],
    );
    _subscription = FlutterBluePlus.scanResults.listen((results) async {
      print('scan results: ${results.length}');
      for (final r in results) {
        final device = r.device;
        final localName = device.localName;
        print(r.advertisementData.serviceUuids);
        if (r.advertisementData.serviceUuids.contains(_serviceIdString.toUpperCase())) {
          print('GOAL SERVICE FOUND!');
          stopScan();
          await device.connect();
          final services = await device.discoverServices();
          if (services.isEmpty) {
            print('no services found!');
            return;
          }
          final characteristic =
              services.first.characteristics.first; //TODO: assumes only one service and one characteristic
          final currentValue = await characteristic.read();
          print(currentValue);
          characteristic.setNotifyValue(true);
          characteristic.lastValueStream.listen((event) {
            print('value changed to $event');
            _goalsSubject.add(event[0]);
          });
        }
        print('${localName.isNotEmpty ? localName : device.remoteId.toString()} found! rssi: ${r.rssi}');
        /*await device.connect();
        final services = await device.discoverServices();
        final goalService = services
            .cast<BluetoothService?>()
            .firstWhere((service) => service?.uuid == _goalServiceId, orElse: () => null);*/
        if (false) {
          print('found goal service!');
          await stopScan();
          /*final success = await goalService.characteristics.first.setNotifyValue(true);
          goalService.characteristics.first.onValueChangedStream.listen((event) {
            print('value changed to $event');
          });
          print('setNotifyValue, success = $success');
          await stopScan();*/
        } else {
          //await device.disconnect();
        }
      }
      //final service = results.firstWhere((r) => r.device.se)
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await stopScan();
  }
}
