import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:kicker_scoreboard/service/ble_goals_service.dart';

import 'detail_page.dart';

class ScorePage extends StatefulWidget {
  final BleGoalsService bleService;

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
      body: Center(
        child: Icon(Icons.face),
      ),
    );
  }

  Future<void> _onReload(BuildContext context) async {
    await widget.bleService.startScan();
    await widget.bleService.startScan();
  }
}
