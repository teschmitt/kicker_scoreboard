import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:kicker_scoreboard/service/ble_service.dart';

import 'detail_page.dart';

class ScorePage extends StatefulWidget {
  final BleService bleService;

  const ScorePage({super.key, required this.bleService});

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Score Page'),
        actions: [
          IconButton(
            onPressed: () => _onReload(context),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: StreamBuilder<List<BluetoothDevice>>(
        stream: widget.bleService.devices,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final device = snapshot.data![index];
                return ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.id.toString()),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DetailPage(
                          device: device,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  Future<void> _onReload(BuildContext context) async {
    await widget.bleService.startScan();
    await widget.bleService.startScan();
  }
}
