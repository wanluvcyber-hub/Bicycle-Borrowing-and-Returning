import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/design_widgets.dart';
import '../state/guard_provider.dart';
import 'guard_widgets.dart';

/// ค้นประวัติการยืมด้วยรหัสนิสิต
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GuardProvider>();
    final history = p.history;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = context.status;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'รหัสนิสิต',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                onSubmitted: p.searchHistory,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'ค้นหา',
              style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
              onPressed: p.searching ? null : () => p.searchHistory(_ctrl.text),
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (p.searching) const Center(child: CircularProgressIndicator()),
        if (p.historyError != null) ErrorBanner(p.historyError!),
        if (!p.searching && p.historyError == null && p.searchedId != null)
          if (history == null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('ไม่พบรหัสนิสิต ${p.searchedId}')),
            )
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconBadge(
                      icon: Icons.person,
                      color: scheme.primary,
                      background: scheme.primary.withValues(alpha: 0.12),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            history.fullName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'รหัส ${history.studentId}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 6),
                          StatusPill(
                            label: 'คืนสายรวม ${history.lateCount} ครั้ง',
                            color: history.lateCount > 0
                                ? status.overdue
                                : status.available,
                            icon: history.lateCount > 0
                                ? Icons.history_toggle_off
                                : Icons.task_alt,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SectionTitle('ประวัติการยืม'),
            if (history.loans.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('ยังไม่มีประวัติการยืม')),
              ),
            for (final loan in history.loans)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'จักรยาน ${loan.bikeNo}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ยืม ${formatTime(loan.borrowedAt)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              'คืน ${loan.isActive ? 'ยังไม่คืน' : formatTime(loan.returnedAt)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      loan.isActive
                          ? (loan.isOverdue(p.now)
                                ? StatusChip(
                                    label: 'เกินเวลา',
                                    color: status.overdue,
                                    icon: Icons.alarm_off,
                                  )
                                : StatusChip(
                                    label: 'กำลังยืม',
                                    color: status.borrowed,
                                    icon: Icons.schedule,
                                  ))
                          : StatusChip(
                              label: loan.isLate ? 'คืนสาย' : 'ตรงเวลา',
                              color: loan.isLate
                                  ? status.overdue
                                  : status.available,
                              icon: loan.isLate
                                  ? Icons.history_toggle_off
                                  : Icons.task_alt,
                            ),
                    ],
                  ),
                ),
              ),
          ],
      ],
    );
  }
}
