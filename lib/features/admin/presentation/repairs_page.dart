import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/design_widgets.dart';
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
        final theme = Theme.of(context);
        final status = context.status;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: broken.length,
          itemBuilder: (context, i) {
            final b = broken[i].bike;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              clipBehavior: Clip.antiAlias,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 6, color: status.broken),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'จักรยาน ${b.bikeNo}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                StatusPill(
                                  label: 'ชำรุด',
                                  color: status.broken,
                                  background: status.brokenContainer,
                                  icon: Icons.build,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              (b.note ?? '').isEmpty
                                  ? 'ไม่มีหมายเหตุ'
                                  : 'อาการ: ${b.note}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              icon: const Icon(Icons.build_circle_outlined),
                              onPressed: () async {
                                final provider = context
                                    .read<AdminBikesProvider>();
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text('ซ่อม ${b.bikeNo} เสร็จแล้ว?'),
                                    content: const Text(
                                      'จักรยานจะกลับเป็น "ว่าง" และล้างหมายเหตุ',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('ยกเลิก'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('ซ่อมเสร็จ'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok != true || !context.mounted) return;
                                final err = await provider.markRepaired(
                                  b.bikeNo,
                                );
                                if (context.mounted) {
                                  showSnack(
                                    context,
                                    err ?? '${b.bikeNo} กลับมาว่างแล้ว',
                                  );
                                }
                              },
                              label: const Text('ซ่อมเสร็จ'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
