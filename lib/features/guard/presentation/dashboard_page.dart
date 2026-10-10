import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/design_widgets.dart';
import '../data/guard_models.dart';
import '../state/guard_provider.dart';
import 'guard_widgets.dart';

/// แดชบอร์ด: ตัวเลขสรุป + รายการเกินเวลา + สถานะทุกคัน (กรองได้)
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GuardProvider>();
    final now = p.now;
    final s = p.summary;
    final overdue = p.overdueBikes;
    final theme = Theme.of(context);
    final status = context.status;

    return RefreshIndicator(
      onRefresh: p.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (p.dashboardError != null) ...[
            ErrorBanner(p.dashboardError!),
            const SizedBox(height: 12),
          ],
          LayoutBuilder(
            builder: (context, c) {
              const gap = 8.0;
              final third = (c.maxWidth - gap * 2) / 3;
              final half = (c.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _SummaryTile(
                    width: third,
                    label: 'ทั้งหมด',
                    value: s.total,
                    icon: Icons.pedal_bike,
                    color: status.broken,
                    background: theme.colorScheme.surfaceContainerLowest,
                  ),
                  _SummaryTile(
                    width: third,
                    label: 'ว่าง',
                    value: s.available,
                    icon: Icons.check_circle,
                    color: status.available,
                    background: status.availableContainer,
                  ),
                  _SummaryTile(
                    width: third,
                    label: 'กำลังถูกใช้',
                    value: s.inUse,
                    icon: Icons.pedal_bike,
                    color: status.borrowed,
                    background: status.borrowedContainer,
                  ),
                  _SummaryTile(
                    width: half,
                    label: 'ชำรุด',
                    value: s.broken,
                    icon: Icons.build,
                    color: status.broken,
                    background: status.brokenContainer,
                  ),
                  // เกินเวลาต้องเด่น: เมื่อ > 0 เป็นแดงเต็มกรอบ
                  _SummaryTile(
                    width: half,
                    label: 'เกินเวลา',
                    value: s.overdue,
                    icon: Icons.alarm_off,
                    color: s.overdue > 0 ? Colors.white : status.overdue,
                    background: s.overdue > 0
                        ? status.overdue
                        : status.overdueContainer,
                  ),
                ],
              );
            },
          ),
          if (overdue.isNotEmpty) ...[
            SectionTitle(
              'เกินกำหนดคืน',
              trailing: StatusPill(
                label: '${overdue.length} คัน',
                color: status.overdue,
                background: status.overdueContainer,
                icon: Icons.alarm_off,
              ),
            ),
            for (final bike in overdue) _BikeTile(bike: bike, now: now),
          ] else if (!p.loading || p.loadedOnce) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.task_alt, color: status.available, size: 20),
                const SizedBox(width: 8),
                Text('ไม่มีรายการเกินเวลา', style: theme.textTheme.bodyMedium),
              ],
            ),
          ],
          const SectionTitle('รายการจักรยาน'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final f in BikeFilter.values)
                ChoiceChip(
                  label: Text(f.label),
                  selected: p.filter == f,
                  onSelected: (_) => p.setFilter(f),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (p.loading && !p.loadedOnce)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (p.filteredBikes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('ไม่มีจักรยานในหมวดนี้')),
            )
          else
            for (final bike in p.filteredBikes) _BikeTile(bike: bike, now: now),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  final double width;
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label $value คัน',
      excludeSemantics: true,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  // ป้ายยาว (เช่น "กำลังถูกใช้") ย่อให้พอดีช่อง ไม่ตัดท้าย
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: theme.textTheme.labelLarge?.copyWith(color: color),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontFeatures: tabularFigures,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BikeTile extends StatelessWidget {
  const _BikeTile({required this.bike, required this.now});

  final GuardBike bike;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = bike.isOverdue(now);
    final loan = bike.activeLoan;
    final color = bikeStatusColor(bike.status, overdue: overdue);
    final bg = bikeStatusBackground(bike.status, overdue: overdue);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: overdue
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(
                  icon: bikeStatusIcon(bike.status, overdue: overdue),
                  color: color,
                  background: bg,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bike.bikeNo,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((bike.station ?? '').isNotEmpty)
                        Text(bike.station!, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                StatusPill(
                  label: overdue ? 'เกินเวลา' : bike.status.label,
                  color: color,
                  background: bg,
                  icon: bikeStatusIcon(bike.status, overdue: overdue),
                ),
              ],
            ),
            if (loan != null) ...[
              const Divider(height: 24),
              LoanDetails(loan: loan, now: now),
            ],
            if (bike.status == BikeStatus.broken &&
                (bike.note ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'หมายเหตุ: ${bike.note}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
