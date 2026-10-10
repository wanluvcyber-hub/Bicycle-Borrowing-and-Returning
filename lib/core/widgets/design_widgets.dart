import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ชื่อแอปบน AppBar: โลโก้ + "ยืม-คืนจักรยานหอใน" + บรรทัดรองบอกว่าอยู่ฝั่งไหน
///
/// ```dart
/// AppBar(title: const BrandTitle(subtitle: 'นิสิตหอใน'))
/// ```
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key, required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/logo.png',
            width: 36,
            height: 36,
            semanticLabel: 'โลโก้ยืม-คืนจักรยานหอใน',
            errorBuilder: (_, _, _) => Icon(
              Icons.pedal_bike,
              size: 32,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ยืม-คืนจักรยานหอใน',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ป้ายสถานะทรงแคปซูล สูง 32dp: ไอคอน + ข้อความ + สี (ไม่พึ่งสีอย่างเดียว)
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.background,
    this.icon,
  });

  final String label;
  final Color color;

  /// ไม่ใส่ = ใช้สีเดียวกับ [color] แบบจาง
  final Color? background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// ไอคอนในกรอบสี่เหลี่ยมมน (ใช้หน้ารายการจักรยาน/หัวการ์ด)
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
    this.size = 56,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// หัวข้อส่วนของหน้า
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleMedium),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// รหัสล็อก 4 หลัก ตัวใหญ่ ตัดกันสูง อ่านชัดกลางแดด · แยกเป็นช่องทีละหลักกันอ่านผิด
/// (ไม่มีปุ่มคัดลอก ตามกติกาของทีม: ห้ามเก็บรหัสในเครื่อง)
class LockCodeDisplay extends StatelessWidget {
  const LockCodeDisplay({super.key, required this.code, this.masked = false});

  final String code;

  /// true = แสดงเป็น ••••
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final digits = masked ? List.filled(code.length, '•') : code.split('');
    return Semantics(
      label: masked ? 'รหัสล็อกถูกซ่อน' : 'รหัสล็อก ${digits.join(' ')}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF04202B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final d in digits)
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  constraints: const BoxConstraints(
                    maxWidth: 64,
                    minHeight: 76,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      d,
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 44,
                        letterSpacing: 0,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// แถบข้อความผิดพลาดสีแดงอ่อน (ใช้ร่วมทุกฝั่ง)
class ErrorNotice extends StatelessWidget {
  const ErrorNotice(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final status = context.status;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: status.overdueContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.overdue.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: status.overdue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: status.overdue),
            ),
          ),
        ],
      ),
    );
  }
}

/// ฉากมืดทับพรีวิวกล้อง + กรอบสแกน 250x250 มุมโค้ง (ใช้ทั้งหน้าสแกนนิสิตและป้อมยาม)
class ScanOverlay extends StatelessWidget {
  const ScanOverlay({super.key, this.accent});

  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScanOverlayPainter(
          accent ?? Theme.of(context).colorScheme.primaryFixedDim,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  _ScanOverlayPainter(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    const box = 250.0;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.5),
      width: box,
      height: box,
    );
    final cut = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    final scrim = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(cut)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(scrim, Paint()..color = const Color(0xCC04202B));

    final stroke = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const len = 36.0;
    for (final dx in [rect.left, rect.right]) {
      for (final dy in [rect.top, rect.bottom]) {
        final sx = dx == rect.left ? 1.0 : -1.0;
        final sy = dy == rect.top ? 1.0 : -1.0;
        canvas.drawLine(Offset(dx, dy), Offset(dx + sx * len, dy), stroke);
        canvas.drawLine(Offset(dx, dy), Offset(dx, dy + sy * len), stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter old) => old.accent != accent;
}
