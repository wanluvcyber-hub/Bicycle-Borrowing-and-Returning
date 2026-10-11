import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/borrow_models.dart';
import '../state/borrow_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/design_widgets.dart';
import 'borrow_widgets.dart';

/// ยืนยันการยืม: ข้อมูลนิสิตดึงจากบัญชีที่ล็อกอิน แสดงให้ดูเฉยๆ ห้ามพิมพ์เอง
/// (ต้องห่อด้วย ChangeNotifierProvider.value เพราะ push เป็น route ใหม่)
class ConfirmBorrowPage extends StatelessWidget {
  const ConfirmBorrowPage({super.key, required this.qrCode});

  final String qrCode;

  Future<void> _confirm(BuildContext context) async {
    final navigator = Navigator.of(context);
    final outcome = await context.read<BorrowProvider>().confirmBorrow(qrCode);
    if (outcome == BorrowOutcome.success) {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BorrowProvider>();
    final student = p.profile;
    final now = p.now;
    final due = DateTime(now.year, now.month, now.day, 21);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = context.status;

    return Scaffold(
      appBar: AppBar(title: const Text('ยืนยันการยืม')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ข้อมูลผู้ยืมดึงจากบัญชีที่ล็อกอิน แสดงให้ดูเฉยๆ ห้ามพิมพ์เอง
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconBadge(
                        icon: Icons.pedal_bike,
                        color: scheme.onPrimary,
                        background: scheme.primary,
                        size: 56,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'จักรยานที่จะยืม',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              qrCode,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Icon(Icons.badge_outlined, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text('ข้อมูลผู้ยืม', style: theme.textTheme.titleMedium),
                      const Spacer(),
                      StatusPill(
                        label: 'ตรวจสอบจากบัญชี',
                        color: scheme.primary,
                        icon: Icons.verified_user_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _Row('ชื่อ', student?.fullName ?? '-'),
                  _Row('รหัสนิสิต', student?.studentId ?? '-'),
                  _Row('วันที่ยืม', formatDate(now)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.alarm, color: status.overdue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('กำหนดคืน', style: theme.textTheme.bodyMedium),
                      Text(
                        'วันนี้ ${formatClock(due)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: status.overdueContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info, color: status.overdue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ข้อควรทราบก่อนยืนยัน',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: status.overdue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'กรุณาคืนจักรยานที่ป้อมรปภ.ก่อนเวลา ${formatClock(due)} '
                        'เพื่อให้เจ้าหน้าที่ตรวจสภาพและรับคืน',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (p.borrowError != null) ...[
            ErrorBanner(p.borrowError!),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: p.borrowing ? null : () => _confirm(context),
            child: p.borrowing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_open, size: 20),
                      SizedBox(width: 8),
                      Text('ยืนยันการยืม'),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: p.borrowing
                ? null
                : () {
                    p.clearBorrowError();
                    Navigator.of(context).pop();
                  },
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(child: Text(value, style: theme.textTheme.titleSmall)),
        ],
      ),
    );
  }
}
