import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// เบอร์ 10 หลักแสดงเป็น 081-234-5678 · รูปแบบอื่นแสดงตามที่เก็บ
String formatPhone(String phone) => RegExp(r'^\d{10}$').hasMatch(phone)
    ? '${phone.substring(0, 3)}-${phone.substring(3, 6)}-${phone.substring(6)}'
    : phone;

/// กล่องแก้เบอร์มือถือของนิสิต · [onSave] คืนข้อความ error ภาษาไทย หรือ null ถ้าสำเร็จ
/// ปิดตัวเองเมื่อบันทึกสำเร็จ (pop ด้วย true)
class EditPhoneDialog extends StatefulWidget {
  const EditPhoneDialog({super.key, this.initialPhone, required this.onSave});

  final String? initialPhone;
  final Future<String?> Function(String phone) onSave;

  @override
  State<EditPhoneDialog> createState() => _EditPhoneDialogState();
}

class _EditPhoneDialogState extends State<EditPhoneDialog> {
  late final _c = TextEditingController(text: widget.initialPhone ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(_c.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _saving = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('แก้ไขเบอร์โทร'),
      content: TextField(
        controller: _c,
        autofocus: true,
        enabled: !_saving,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9 -]')),
          LengthLimitingTextInputFormatter(12),
        ],
        decoration: InputDecoration(
          labelText: 'เบอร์มือถือ',
          hintText: '0812345678',
          errorText: _error,
          errorMaxLines: 2,
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'กำลังบันทึก...' : 'บันทึก'),
        ),
      ],
    );
  }
}
