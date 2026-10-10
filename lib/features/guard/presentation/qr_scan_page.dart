import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/widgets/design_widgets.dart';

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
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('สแกน QR จักรยาน'),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: Colors.white,
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: _onDetect,
            errorBuilder: (context, error) => Container(
              color: const Color(0xFF04202B),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: Text(
                'เปิดกล้องไม่ได้ กรุณาพิมพ์เลขคันแทน',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ),
          ),
          const ScanOverlay(accent: Color(0xFFFFB68F)),
          Align(
            alignment: const Alignment(0, -0.78),
            child: IgnorePointer(
              child: Text(
                'เล็ง QR บนตัวจักรยาน',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
