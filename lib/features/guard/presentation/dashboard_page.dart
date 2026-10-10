import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    return RefreshIndicator(
      onRefresh: p.refresh,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (p.dashboardError != null) ...[
            ErrorBanner(p.dashboardError!),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryCard('ทั้งหมด', s.total, Colors.blueGrey),
              _SummaryCard('ว่าง', s.available, Colors.green),
              _SummaryCard('กำลังถูกใช้', s.inUse, Colors.blue),
              _SummaryCard('ชำรุด', s.broken, Colors.grey),
              _SummaryCard('เกินเวลา', s.overdue, Colors.red),
            ],
          ),
          if (overdue.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('เกินเวลา',
                style: TextStyle(
                    color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
            for (final bike in overdue) _BikeTile(bike: bike, now: now),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          Text(label),
        ],
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
    final overdue = bike.isOverdue(now);
    final loan = bike.activeLoan;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(bike.bikeNo,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                StatusChip(
                  label: overdue ? 'เกินเวลา' : bike.status.label,
                  color: bikeStatusColor(bike.status, overdue: overdue),
                ),
              ],
            ),
            if (loan != null) ...[
              const SizedBox(height: 6),
              LoanDetails(loan: loan, now: now),
            ],
            if (bike.status == BikeStatus.broken && (bike.note ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('หมายเหตุ: ${bike.note}'),
              ),
          ],
        ),
      ),
    );
  }
}
