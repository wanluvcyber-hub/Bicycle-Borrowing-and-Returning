import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/message_view.dart';
import '../state/admin_bikes_provider.dart';
import 'bikes_async_body.dart';
import 'bikes_page.dart' show TextDialog;

/// ดู/เปลี่ยนรหัสล็อกรายคัน (ซ่อนรหัสไว้ก่อน กดตาเพื่อดู)
class LocksPage extends StatefulWidget {
  const LocksPage({super.key});

  @override
  State<LocksPage> createState() => _LocksPageState();
}

class _LocksPageState extends State<LocksPage> {
  bool _reveal = false;

  @override
  Widget build(BuildContext context) {
    return BikesAsyncBody(
      builder: (context, p) {
        if (p.bikes.isEmpty) {
          return ListView(
            children: const [
              SizedBox(height: 120),
              MessageView(icon: Icons.lock, message: 'ยังไม่มีจักรยาน'),
            ],
          );
        }
        return ListView(
          children: [
            SwitchListTile(
              title: const Text('แสดงรหัสล็อก'),
              value: _reveal,
              onChanged: (v) => setState(() => _reveal = v),
            ),
            const Divider(height: 1),
            for (final item in p.bikes)
              ListTile(
                title: Text(item.bike.bikeNo),
                subtitle: Text(
                  item.lockCode == null
                      ? 'ยังไม่มีรหัสล็อก'
                      : (_reveal ? item.lockCode! : '••••'),
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () async {
                  final provider = context.read<AdminBikesProvider>();
                  final code = await showDialog<String>(
                    context: context,
                    builder: (_) => TextDialog(
                      title: 'รหัสล็อก ${item.bike.bikeNo}',
                      label: 'รหัสล็อกใหม่',
                      initial: '',
                    ),
                  );
                  if (code == null || !context.mounted) return;
                  final err = await provider.setLockCode(
                    item.bike.bikeNo,
                    code,
                  );
                  if (context.mounted) {
                    showSnack(context, err ?? 'เปลี่ยนรหัสล็อกแล้ว');
                  }
                },
              ),
          ],
        );
      },
    );
  }
}
