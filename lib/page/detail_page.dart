import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DetailPage extends StatefulWidget {
  final BluetoothDevice device;

  const DetailPage({super.key, required this.device});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late BluetoothDevice _device;
  bool? connected = false;

  @override
  void initState() {
    super.initState();
    _device = widget.device;
    connectAndDiscover();
  }

  Future<void> connectAndDiscover() async {
    try {
      setState(() {
        connected = null;
      });
      await _device.connect(timeout: const Duration(seconds: 10));
      setState(() {
        connected = true;
      });
    } catch (e) {
      setState(() {
        connected = false;
      });
      rethrow;
    }

    await _device.discoverServices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_device.name),
      ),
      body: Center(
        child: Column(
          children: [
            Text('Name: ${_device.name}'),
            Text('Id: ${_device.id}'),
            Text(connected == null ? 'Connecting...' : 'Connected: $connected'),
            const Divider(
              height: 20,
            ),
            const Text('Services'),
            StreamBuilder(
              stream: _device.services,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data?.length ?? 0,
                  itemBuilder: (context, index) {
                    final service = snapshot.data![index];
                    return ListTile(
                      title: Text(service.uuid.toString()),
                      onTap: () async {
                        showBottomSheet(
                          context: context,
                          builder: (context) {
                            return ListView.builder(
                              itemBuilder: (context, index) {
                                final characteristic = service.characteristics[index];
                                characteristic.onValueChangedStream.listen((event) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Value changed: $event'),
                                    ),
                                  );
                                });
                                return StreamBuilder<List<int>>(
                                    stream: characteristic.value,
                                    builder: (context, snapshot) {
                                      return ListTile(
                                        title: Text('${characteristic.uuid.toString()} - ${snapshot.data}'),
                                        subtitle: Text(characteristic.descriptors.toString()),
                                      );
                                    });
                              },
                              itemCount: service.characteristics.length,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
