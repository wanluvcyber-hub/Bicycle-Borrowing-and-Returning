import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/widgets/design_widgets.dart';

/// สแกน QR บนตัวจักรยาน (ค่าใน QR คือเลขคัน) มีช่องพิมพ์เลขคันเป็นทางสำรอง
/// ส่งค่ากลับผ่าน Navigator.pop
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _ctrl = TextEditingController();
  final _scanner = MobileScannerController();
  var _done = false;
  var _torch = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scanner.dispose();
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

  Future<void> _toggleTorch() async {
    try {
      await _scanner.toggleTorch();
      if (mounted) setState(() => _torch = !_torch);
    } catch (_) {
      // เครื่องไม่มีไฟฉาย/กล้องยังไม่พร้อม: ไม่ต้องทำอะไร
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('สแกน QR จักรยาน'),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: Colors.white,
        ),
        actions: [
          IconButton(
            tooltip: _torch ? 'ปิดไฟฉาย' : 'เปิดไฟฉาย',
            onPressed: _toggleTorch,
            icon: Icon(_torch ? Icons.flashlight_off : Icons.flashlight_on),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _scanner,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => Container(
                    color: const Color(0xFF04202B),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.no_photography,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'เปิดกล้องไม่ได้ กรุณาพิมพ์เลขคันด้านล่างแทน',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ฉากมืดรอบกรอบสแกน ให้โฟกัสที่ QR
                const ScanOverlay(),
                Align(
                  alignment: const Alignment(0, -0.78),
                  child: IgnorePointer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'เล็ง QR บนตัวจักรยาน',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'วาง QR ให้อยู่กลางกรอบเพื่อสแกนอัตโนมัติ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.keyboard, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'หรือพิมพ์เลขคันจักรยาน (ใช้เมื่อกล้องสแกนไม่ติด)',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'เลขคัน เช่น B01',
                            prefixIcon: Icon(Icons.pedal_bike),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
