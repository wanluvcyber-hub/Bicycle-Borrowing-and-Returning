import 'package:flutter/material.dart';

import '../../../core/widgets/design_widgets.dart';
import '../../reminder/presentation/loan_countdown_card.dart';
import '../../reminder/presentation/overdue_banner.dart';
import '../data/borrow_models.dart';

/// รหัสล็อก + เวลานับถอยหลังถึง 21.00 น. (หน้าสำคัญที่สุดของฝั่งนิสิต)
/// เวลาที่เหลือคำนวณจาก due_at ทุกครั้ง · เลยกำหนดแล้วขึ้น "เกินเวลา"
/// การ์ดนับถอยหลังใช้ของคนที่ 4 (`LoanCountdownCard`) เพื่อให้เหมือนกันกับแจ้งเตือน
class ActiveLoanCard extends StatelessWidget {
  const ActiveLoanCard({super.key, required this.loan, required this.clock});

  final MyLoan loan;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final overdue = loan.isOverdue(clock());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (overdue) ...[
          OverdueBanner(dueAt: loan.dueAt, now: clock()),
          const SizedBox(height: 12),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconBadge(
                  icon: Icons.pedal_bike,
                  color: scheme.onPrimary,
                  background: scheme.primary,
                  size: 64,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'จักรยานที่คุณยืม',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        loan.bikeNo,
                        key: const Key('bikeNo'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_outline, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'รหัสปลดล็อก 4 หลัก',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'หมุนตามเลขนี้เพื่อปลดล็อกล้อจักรยาน',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                KeyedSubtree(
                  key: const Key('lockCode'),
                  child: LockCodeDisplay(code: loan.lockCode ?? '----'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: const Key('remaining'),
          child: LoanCountdownCard(
            bikeNo: loan.bikeNo,
            borrowedAt: loan.borrowedAt,
            dueAt: loan.dueAt,
            clock: clock,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text('วิธีคืนจักรยาน', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              const _Step(
                1,
                'ปั่นจักรยานมาคืนที่ป้อมยามหอใน ก่อนเวลา 21:00 น.',
              ),
              const _Step(2, 'ล็อกล้อไว้ แล้วรอป้อมยามตรวจสภาพจักรยาน'),
              const _Step(
                3,
                'ป้อมยามกดรับคืนในระบบ รหัสล็อกจะหายไปจากหน้านี้เอง',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.n, this.text);

  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                '$n',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
