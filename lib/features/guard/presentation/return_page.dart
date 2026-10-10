import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/design_widgets.dart';
import '../../reminder/presentation/overdue_banner.dart';
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
    _bikeFocus.dispose();
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
    final ok = await context.read<GuardProvider>().confirmReturn(
      condition: _condition,
      note: _noteCtrl.text,
    );
    if (ok) {
      _bikeCtrl.clear();
      _resetForm();
    }
  }

  final _bikeFocus = FocusNode();

  void _next() {
    _bikeCtrl.clear();
    _bikeFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GuardProvider>();
    final loan = p.pendingLoan;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = context.status;
    final damagedWithoutNote =
        _condition == ReturnCondition.damaged && _noteCtrl.text.trim().isEmpty;
    final canSubmit = loan != null && !p.returning && !damagedWithoutNote;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _StepTitle(1, 'ระบุเลขจักรยาน'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _bikeCtrl,
                focusNode: _bikeFocus,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'เลขจักรยาน เช่น B01',
                  prefixIcon: Icon(Icons.pedal_bike),
                ),
                onSubmitted: (_) => _lookup(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'สแกน QR',
              style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
              onPressed: _scan,
              icon: const Icon(Icons.qr_code_scanner),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              tooltip: 'ค้นหา',
              style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
              onPressed: p.lookingUp ? null : _lookup,
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (p.lookingUp) const Center(child: CircularProgressIndicator()),
        if (p.returnError != null) ErrorBanner(p.returnError!),
        if (p.lastResult != null)
          _ResultCard(result: p.lastResult!, onNext: _next),
        if (loan != null) ...[
          const _StepTitle(2, 'ข้อมูลผู้ยืม (ตรวจสอบก่อนรับคืน)'),
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
                        size: 48,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        loan.bikeNo,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (loan.isOverdue(p.now)) ...[
                    OverdueBanner(dueAt: loan.dueAt, now: p.now),
                    const SizedBox(height: 12),
                  ],
                  LoanDetails(loan: loan, now: p.now),
                ],
              ),
            ),
          ),
          const _StepTitle(3, 'ตรวจสภาพจักรยาน'),
          SegmentedButton<ReturnCondition>(
            showSelectedIcon: false,
            segments: [
              for (final c in ReturnCondition.values)
                ButtonSegment(
                  value: c,
                  icon: Icon(
                    c == ReturnCondition.normal
                        ? Icons.task_alt
                        : Icons.warning_amber_rounded,
                  ),
                  label: Text(c.label),
                ),
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
              decoration: InputDecoration(
                labelText: 'หมายเหตุความเสียหาย (จำเป็น)',
                prefixIcon: const Icon(Icons.edit_note),
                errorText: damagedWithoutNote
                    ? 'ถ้าชำรุด ต้องใส่หมายเหตุ'
                    : null,
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              backgroundColor: scheme.primary,
            ),
            onPressed: canSubmit ? _confirm : null,
            child: p.returning
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in_outlined),
                      SizedBox(width: 8),
                      Text('ยืนยันรับคืนจักรยาน'),
                    ],
                  ),
          ),
          if (_condition == ReturnCondition.normal && loan.isOverdue(p.now))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: status.overdue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'เลยกำหนดแล้ว ระบบจะบันทึกเป็นคืนสาย',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle(this.n, this.text);

  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              '$n',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.titleMedium)),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.onNext});

  final ReturnResult result;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = context.status;
    final damaged = result.condition == ReturnCondition.damaged;
    final okColor = result.isLate ? status.overdue : status.available;
    return Card(
      color: status.availableContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: status.available,
                  child: const Icon(Icons.check, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'รับคืน ${result.bikeNo} เรียบร้อยแล้ว',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'นิสิต ${result.studentId} · ${formatTime(result.returnedAt)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusPill(
                  label: result.isLate ? 'คืนสาย' : 'คืนตรงเวลา',
                  color: okColor,
                  background: Colors.white,
                  icon: result.isLate
                      ? Icons.history_toggle_off
                      : Icons.task_alt,
                ),
                if (damaged)
                  StatusPill(
                    label: 'บันทึกเป็นจักรยานชำรุด',
                    color: status.broken,
                    background: Colors.white,
                    icon: Icons.build,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('รับคืนคันถัดไป'),
            ),
          ],
        ),
      ),
    );
  }
}
