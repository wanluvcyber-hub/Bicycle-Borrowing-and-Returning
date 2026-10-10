import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                  border: OutlineInputBorder(),
                ),
                onSubmitted: p.searchHistory,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'ค้นหา',
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
            Text('${history.fullName} (${history.studentId})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('คืนสายรวม ${history.lateCount} ครั้ง'),
            const SizedBox(height: 8),
            if (history.loans.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('ยังไม่มีประวัติการยืม')),
              ),
            for (final loan in history.loans)
              Card(
                child: ListTile(
                  title: Text('จักรยาน ${loan.bikeNo}'),
                  subtitle: Text(
                    'ยืม ${formatTime(loan.borrowedAt)}\n'
                    'คืน ${loan.isActive ? 'ยังไม่คืน' : formatTime(loan.returnedAt)}',
                  ),
                  isThreeLine: true,
                  trailing: loan.isActive
                      ? (loan.isOverdue(p.now)
                          ? const StatusChip(label: 'เกินเวลา', color: Colors.red)
                          : const StatusChip(label: 'กำลังยืม', color: Colors.blue))
                      : StatusChip(
                          label: loan.isLate ? 'คืนสาย' : 'ตรงเวลา',
                          color: loan.isLate ? Colors.red : Colors.green,
                        ),
                ),
              ),
          ],
      ],
    );
  }
}
