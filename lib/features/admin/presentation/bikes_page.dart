import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/bike.dart';
import '../../../core/widgets/message_view.dart';
import '../data/admin_repository.dart';
import '../state/admin_bikes_provider.dart';
import 'bikes_async_body.dart';

/// จัดการจักรยาน: เพิ่มคัน (พร้อมรหัสล็อก) และแก้จุดจอด
class BikesPage extends StatelessWidget {
  const BikesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BikesAsyncBody(
        builder: (context, p) {
          if (p.bikes.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                MessageView(
                  icon: Icons.pedal_bike,
                  message: 'ยังไม่มีจักรยาน กดปุ่ม + เพื่อเพิ่ม',
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: p.bikes.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = p.bikes[i];
              final b = item.bike;
              return ListTile(
                leading: _StatusDot(b.status),
                title: Text(b.bikeNo),
                subtitle: Text(
                  [
                    b.station ?? 'ไม่ระบุจุดจอด',
                    b.status.labelTh,
                    if (item.lockCode == null) 'ยังไม่มีรหัสล็อก',
                  ].join(' · '),
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _showEdit(context, item),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มจักรยาน'),
      ),
    );
  }

  Future<void> _showAdd(BuildContext context) async {
    final p = context.read<AdminBikesProvider>();
    final result = await showDialog<({String no, String station, String lock})>(
      context: context,
      builder: (_) => const _AddBikeDialog(),
    );
    if (result == null || !context.mounted) return;
    final err = await p.addBike(
      bikeNo: result.no,
      station: result.station,
      lockCode: result.lock,
    );
    if (context.mounted) {
      showSnack(context, err ?? 'เพิ่มจักรยาน ${result.no} แล้ว');
    }
  }

  Future<void> _showEdit(BuildContext context, AdminBike item) async {
    final p = context.read<AdminBikesProvider>();
    final station = await showDialog<String>(
      context: context,
      builder: (_) => TextDialog(
        title: 'แก้จุดจอด ${item.bike.bikeNo}',
        label: 'จุดจอด',
        initial: item.bike.station ?? '',
        allowEmpty: true,
      ),
    );
    if (station == null || !context.mounted) return;
    final err = await p.updateStation(item.bike.bikeNo, station);
    if (context.mounted) showSnack(context, err ?? 'บันทึกจุดจอดแล้ว');
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot(this.status);
  final BikeStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BikeStatus.available => Colors.green,
      BikeStatus.borrowed => Colors.blue,
      BikeStatus.broken => Colors.red,
    };
    return Icon(
      Icons.circle,
      color: color,
      size: 16,
      semanticLabel: status.labelTh,
    );
  }
}

class _AddBikeDialog extends StatefulWidget {
  const _AddBikeDialog();

  @override
  State<_AddBikeDialog> createState() => _AddBikeDialogState();
}

class _AddBikeDialogState extends State<_AddBikeDialog> {
  final _no = TextEditingController();
  final _station = TextEditingController();
  final _lock = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _no.dispose();
    _station.dispose();
    _lock.dispose();
    super.dispose();
  }

  void _submit() {
    final no = _no.text.trim();
    if (no.isEmpty || no.contains(RegExp(r'\s'))) {
      setState(() => _error = 'เลขคันต้องไม่ว่างและไม่มีช่องว่าง');
      return;
    }
    final lockError = AdminBikesProvider.validateLockCode(_lock.text.trim());
    if (lockError != null) {
      setState(() => _error = lockError);
      return;
    }
    Navigator.pop(context, (
      no: no,
      station: _station.text,
      lock: _lock.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('เพิ่มจักรยาน'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _no,
              decoration: const InputDecoration(
                labelText: 'เลขคัน (เช่น B11)',
                helperText: 'ค่าใน QR จะเป็นเลขคันนี้',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _station,
              decoration: const InputDecoration(labelText: 'จุดจอด'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lock,
              decoration: const InputDecoration(labelText: 'รหัสล็อก'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(onPressed: _submit, child: const Text('เพิ่ม')),
      ],
    );
  }
}

/// ไดอะล็อกกรอกข้อความช่องเดียว (ใช้ร่วมกับหน้ารหัสล็อก)
class TextDialog extends StatefulWidget {
  const TextDialog({
    super.key,
    required this.title,
    required this.label,
    required this.initial,
    this.allowEmpty = false,
  });

  final String title;
  final String label;
  final String initial;
  final bool allowEmpty;

  @override
  State<TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<TextDialog> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _c,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () {
            if (!widget.allowEmpty && _c.text.trim().isEmpty) return;
            Navigator.pop(context, _c.text);
          },
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}
