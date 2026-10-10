import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/guard_models.dart';
import '../state/guard_provider.dart';
import 'guard_widgets.dart';
import 'qr_scan_page.dart';

/// รับคืน: สแกน/พิมพ์เลขคัน → ดูผู้ยืม → เลือกปกติ/ชำรุด (+หมายเหตุ) → ยืนยัน
class ReturnPage extends StatefulWidget {
  const ReturnPage({super.key});

  @override
  State<ReturnPage> createState() => _ReturnPageState();
}

class _ReturnPageState extends State<ReturnPage> {
  final _bikeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  var _condition = ReturnCondition.normal;

  @override
  void dispose() {
    _bikeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final value = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => const QrScanPage()));
    if (value == null || !mounted) return;
    _bikeCtrl.text = value;
    await _lookup();
  }

  Future<void> _lookup() async {
    _resetForm();
    await context.read<GuardProvider>().lookupBike(_bikeCtrl.text);
  }

  void _resetForm() {
    _noteCtrl.clear();
    setState(() => _condition = ReturnCondition.normal);
  }

  Future<void> _confirm() async {
    final ok = await context
        .read<GuardProvider>()
        .confirmReturn(condition: _condition, note: _noteCtrl.text);
    if (ok) {
      _bikeCtrl.clear();
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GuardProvider>();
    final loan = p.pendingLoan;
    final damagedWithoutNote =
        _condition == ReturnCondition.damaged && _noteCtrl.text.trim().isEmpty;
    final canSubmit = loan != null && !p.returning && !damagedWithoutNote;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _bikeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'เลขจักรยาน เช่น B01',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _lookup(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'สแกน QR',
              onPressed: _scan,
              icon: const Icon(Icons.qr_code_scanner),
            ),
            IconButton.filled(
              tooltip: 'ค้นหา',
              onPressed: p.lookingUp ? null : _lookup,
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (p.lookingUp) const Center(child: CircularProgressIndicator()),
        if (p.returnError != null) ErrorBanner(p.returnError!),
        if (p.lastResult != null) _ResultCard(result: p.lastResult!),
        if (loan != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('จักรยาน ${loan.bikeNo}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  LoanDetails(loan: loan, now: p.now),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ReturnCondition>(
            segments: [
              for (final c in ReturnCondition.values)
                ButtonSegment(value: c, label: Text(c.label)),
            ],
            selected: {_condition},
            onSelectionChanged: p.returning
                ? null
                : (s) => setState(() => _condition = s.first),
          ),
          if (_condition == ReturnCondition.damaged) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'หมายเหตุความเสียหาย (จำเป็น)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: guardColor,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: canSubmit ? _confirm : null,
            child: p.returning
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('รับคืน'),
          ),
        ],
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final ReturnResult result;

  @override
  Widget build(BuildContext context) {
    final damaged = result.condition == ReturnCondition.damaged;
    return Card(
      color: Colors.green.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('รับคืน ${result.bikeNo} เรียบร้อย',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('นิสิต ${result.studentId} · ${formatTime(result.returnedAt)}'),
            Text(result.isLate ? 'คืนสาย' : 'คืนตรงเวลา',
                style: TextStyle(
                    color: result.isLate ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w600)),
            if (damaged) const Text('บันทึกเป็นจักรยานชำรุด'),
          ],
        ),
      ),
    );
  }
}
