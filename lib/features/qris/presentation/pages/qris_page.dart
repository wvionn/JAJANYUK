import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QrisPage extends ConsumerWidget {
  const QrisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRIS Payment'),
      ),
      body: const Center(
        child: Text('QRIS Page - To be implemented'),
      ),
    );
  }
}
