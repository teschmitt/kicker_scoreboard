import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class NotConnectedPageContent extends StatelessWidget {
  final BluetoothAdapterState adapterState;

  const NotConnectedPageContent({super.key, required this.adapterState});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text('Not connected, reason: $adapterState'),
    );
  }
}
