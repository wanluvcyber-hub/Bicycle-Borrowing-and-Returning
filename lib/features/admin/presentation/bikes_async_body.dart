import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/message_view.dart';
import '../state/admin_bikes_provider.dart';

/// โครงรวมของ 3 แท็บที่ใช้ [AdminBikesProvider]: หมุนตอนโหลด · error + ลองใหม่ · ดึงลงเพื่อรีเฟรช
class BikesAsyncBody extends StatelessWidget {
  const BikesAsyncBody({super.key, required this.builder});

  final Widget Function(BuildContext context, AdminBikesProvider p) builder;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AdminBikesProvider>();
    if (p.loading && p.bikes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (p.loadError != null && p.bikes.isEmpty) {
      return MessageView(
        icon: Icons.cloud_off,
        message: p.loadError!,
        actions: [
          FilledButton(onPressed: p.load, child: const Text('ลองอีกครั้ง')),
        ],
      );
    }
    return RefreshIndicator(onRefresh: p.load, child: builder(context, p));
  }
}

void showSnack(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
