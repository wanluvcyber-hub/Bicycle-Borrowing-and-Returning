import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// สแกน QR บนตัวจักรยาน (ค่าใน QR คือเลขคัน) แล้วส่งค่ากลับผ่าน Navigator.pop
class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  var _done = false;

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    final value = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .where((v) => v.trim().isNotEmpty)
        .firstOrNull;
    if (value == null) return;
    _done = true;
    Navigator.of(context).pop(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สแกน QR จักรยาน')),
      body: MobileScanner(
        onDetect: _onDetect,
        errorBuilder: (context, error) =>
            const Center(child: Text('เปิดกล้องไม่ได้ กรุณาพิมพ์เลขคันแทน')),
      ),
    );
  }
}
