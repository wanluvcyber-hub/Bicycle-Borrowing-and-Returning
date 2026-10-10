import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/message_view.dart';
import '../state/admin_bikes_provider.dart';
import 'bikes_async_body.dart';

/// งานซ่อม: คันที่ชำรุด พร้อมหมายเหตุ → ปุ่ม "ซ่อมเสร็จ"
class RepairsPage extends StatelessWidget {
  const RepairsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BikesAsyncBody(
      builder: (context, p) {
        final broken = p.broken;
        if (broken.isEmpty) {
          return ListView(
            children: const [
              SizedBox(height: 120),
              MessageView(
                icon: Icons.check_circle_outline,
                message: 'ไม่มีจักรยานชำรุดค้างซ่อม',
              ),
            ],
          );
        }
        return ListView.separated(
          itemCount: broken.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final b = broken[i].bike;
            return ListTile(
              title: Text(b.bikeNo),
              subtitle: Text(b.note ?? 'ไม่มีหมายเหตุ'),
              trailing: FilledButton(
                onPressed: () async {
                  final provider = context.read<AdminBikesProvider>();
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('ซ่อม ${b.bikeNo} เสร็จแล้ว?'),
                      content: const Text(
                        'จักรยานจะกลับเป็น "ว่าง" และล้างหมายเหตุ',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('ยกเลิก'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('ซ่อมเสร็จ'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true || !context.mounted) return;
                  final err = await provider.markRepaired(b.bikeNo);
                  if (context.mounted) {
                    showSnack(context, err ?? '${b.bikeNo} กลับมาว่างแล้ว');
                  }
                },
                child: const Text('ซ่อมเสร็จ'),
              ),
            );
          },
        );
      },
    );
  }
}
