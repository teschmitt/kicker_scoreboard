import 'package:flutter/material.dart';

class IdlePageContent extends StatelessWidget {
  const IdlePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
