import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/design_widgets.dart';
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
        final theme = Theme.of(context);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: SwitchListTile(
                secondary: Icon(
                  _reveal ? Icons.visibility : Icons.visibility_off,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('แสดงรหัสล็อก'),
                subtitle: const Text('ปิดไว้เป็นค่าเริ่มต้น กันคนมองข้างหลัง'),
                value: _reveal,
                onChanged: (v) => setState(() => _reveal = v),
              ),
            ),
            const SizedBox(height: 8),
            for (final item in p.bikes)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
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
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        IconBadge(
                          icon: item.lockCode == null
                              ? Icons.lock_open
                              : Icons.lock_outline,
                          color: item.lockCode == null
                              ? context.status.overdue
                              : theme.colorScheme.primary,
                          background: item.lockCode == null
                              ? context.status.overdueContainer
                              : theme.colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                          size: 52,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.bike.bikeNo,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              item.lockCode == null
                                  ? Text(
                                      'ยังไม่มีรหัสล็อก',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: context.status.overdue,
                                          ),
                                    )
                                  : Text(
                                      _reveal ? item.lockCode! : '••••',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            letterSpacing: 4,
                                            fontFeatures: tabularFigures,
                                          ),
                                    ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.edit_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
