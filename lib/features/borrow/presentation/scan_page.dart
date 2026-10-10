import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// สแกน QR บนตัวจักรยาน (ค่าใน QR คือเลขคัน) มีช่องพิมพ์เลขคันเป็นทางสำรอง
/// ส่งค่ากลับผ่าน Navigator.pop
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _ctrl = TextEditingController();
  var _done = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _finish(String value) {
    final v = value.trim();
    if (_done || v.isEmpty) return;
    _done = true;
    Navigator.of(context).pop(v);
  }

  void _onDetect(BarcodeCapture capture) {
    final value = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .where((v) => v.trim().isNotEmpty)
        .firstOrNull;
    if (value != null) _finish(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สแกน QR จักรยาน')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: _onDetect,
              errorBuilder: (context, error) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('เปิดกล้องไม่ได้ กรุณาพิมพ์เลขคันด้านล่างแทน'),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'หรือพิมพ์เลขคัน เช่น B01',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: _finish,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _finish(_ctrl.text.toUpperCase()),
                    child: const Text('ตกลง'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
